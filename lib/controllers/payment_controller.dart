import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

import '../apis/payment_api.dart';
import '../config/app_config.dart';
import '../config/iap_products.dart';
import '../helpers/my_dialogs.dart';
import '../helpers/pref.dart';
import '../models/plan.dart';
import '../models/subscription.dart';
import '../screens/main_shell_screen.dart';
import '../screens/payment_success_screen.dart';
import '../services/iap_service.dart';
import 'auth_controller.dart';

/// Subscriptions via App Store / Google Play (in_app_purchase).
class PaymentController extends GetxController {
  final IapService _iap = IapService.instance;
  List<ProductDetails> _storeProducts = [];
  bool _fromSignup = false;
  bool _guestMode = false;
  bool _iapReady = false;
  bool _isRestoring = false;
  int _restoredCount = 0;
  int _restoreFailedCount = 0;
  String? _restoreLastError;
  int _restoreHandlersInFlight = 0;
  DateTime? _lastRestoreHandlerFinishedAt;
  final Set<String> _handledPurchaseKeys = {};

  static const Duration _restoreMaxWait = Duration(seconds: 15);
  static const Duration _restoreIdleWindow = Duration(milliseconds: 800);

  static const String _iosReceiptUnavailableMessage =
      'Could not verify purchase with App Store. If testing in Xcode, disable '
      'the StoreKit Configuration file in the Run scheme, then try Restore Purchases.';

  final RxBool isLoadingProducts = false.obs;
  final RxBool isPurchasing = false.obs;

  bool get isPaymentSupported =>
      !kIsWeb && (Platform.isIOS || Platform.isAndroid);

  @override
  void onInit() {
    super.onInit();
    _initIap();
  }

  Future<void> _initIap() async {
    if (!isPaymentSupported) return;
    _iapReady = await _iap.initialize(
      onPurchase: _handlePurchase,
      onError: _handlePurchaseError,
      onCancelled: _handlePurchaseCancelled,
    );
  }

  /// Load store products once IAP is ready. Safe to call multiple times.
  Future<void> ensureStoreProductsLoaded({bool forceRefresh = false}) async {
    if (!isPaymentSupported) return;
    if (!_iapReady) {
      _iapReady = await _iap.initialize(
        onPurchase: _handlePurchase,
        onError: _handlePurchaseError,
        onCancelled: _handlePurchaseCancelled,
      );
      if (!_iapReady) return;
    }
    if (!forceRefresh &&
        _storeProducts.isNotEmpty &&
        _iap.hasCachedProducts) {
      return;
    }
    if (isLoadingProducts.value) return;
    await loadStoreProducts(forceRefresh: forceRefresh);
  }

  @override
  void onClose() {
    _iap.dispose();
    super.onClose();
  }

  Future<void> loadStoreProducts({bool forceRefresh = false}) async {
    if (!isPaymentSupported) return;
    isLoadingProducts.value = true;
    try {
      _storeProducts =
          await _iap.queryProducts(forceRefresh: forceRefresh);
    } finally {
      isLoadingProducts.value = false;
    }
  }

  String _iosStoreUnavailableMessage() {
    final code = _iap.lastQueryError?.code ?? '';
    if (code == 'storekit_no_response') {
      return AppConfig.storeKitNoResponseIos;
    }
    return AppConfig.storeProductsNotFoundIos;
  }

  /// App Store / Play localized price string for UI (e.g. `$4.99`).
  String? storePriceLabelForPlanIndex(int planIndex) {
    final product = _iap.productForPlanIndex(planIndex, _storeProducts);
    final label = product?.price;
    if (label == null || label.isEmpty) return null;
    return label;
  }

  /// App Store / Play localized subscription title.
  String? storeTitleForPlanIndex(int planIndex) {
    final product = _iap.productForPlanIndex(planIndex, _storeProducts);
    final title = product?.title;
    if (title == null || title.isEmpty) return null;
    return title;
  }

  String get _storeProductsNotFoundMessage => Platform.isIOS
      ? AppConfig.storeProductsNotFoundIos
      : AppConfig.storeProductsNotFoundAndroid;

  /// Start in-app subscription purchase for [plan].
  /// Set [guestMode] to true when the user has not created a backend account;
  /// the purchase will be activated locally without backend verification.
  Future<void> openCheckout(Plan plan, {bool fromSignup = false, bool guestMode = false}) async {
    _guestMode = guestMode;
    if (!isPaymentSupported) {
      MyDialogs.error(msg: 'Subscriptions are not supported on this device.');
      return;
    }
    if (!_iapReady) {
      _iapReady = await _iap.initialize(
        onPurchase: _handlePurchase,
        onError: _handlePurchaseError,
        onCancelled: _handlePurchaseCancelled,
      );
      if (!_iapReady) {
        MyDialogs.error(msg: 'Store is not available. Try again later.');
        return;
      }
    }
    if (_storeProducts.isEmpty) {
      await loadStoreProducts(forceRefresh: true);
    }

    final product = _iap.productForPlanIndex(plan.index, _storeProducts);
    if (product == null) {
      MyDialogs.error(
        msg: Platform.isIOS
            ? _iosStoreUnavailableMessage()
            : _storeProductsNotFoundMessage,
      );
      if (fromSignup) Get.offAll(() => const MainShellScreen());
      return;
    }

    _fromSignup = fromSignup;
    isPurchasing.value = true;
    try {
      final started = await _iap.buy(product);
      if (!started) {
        isPurchasing.value = false;
        MyDialogs.error(msg: 'Could not start purchase');
        _clearPending(fromSignup: fromSignup);
      }
    } catch (e) {
      isPurchasing.value = false;
      MyDialogs.error(msg: e.toString().replaceFirst('Exception: ', ''));
      _clearPending(fromSignup: fromSignup);
    }
  }

  Future<void> restorePurchases() async {
    await _restorePurchases(showUi: true);
  }

  /// Re-sync App Store / Play entitlements on launch (no dialogs).
  Future<void> syncSubscriptionFromStore() async {
    if (Pref.hasActiveSubscription) return;
    await _restorePurchases(showUi: false);
  }

  Future<void> _restorePurchases({required bool showUi}) async {
    if (!isPaymentSupported) {
      if (showUi) {
        MyDialogs.error(msg: 'Restore is not supported on this device.');
      }
      return;
    }
    if (!_iapReady) {
      _iapReady = await _iap.initialize(
        onPurchase: _handlePurchase,
        onError: _handlePurchaseError,
        onCancelled: _handlePurchaseCancelled,
      );
      if (!_iapReady) return;
    }
    if (showUi) {
      MyDialogs.showProgress();
    }
    _isRestoring = true;
    _restoredCount = 0;
    _restoreFailedCount = 0;
    _restoreLastError = null;
    _restoreHandlersInFlight = 0;
    _lastRestoreHandlerFinishedAt = null;
    try {
      await _iap.restorePurchases();
      _lastRestoreHandlerFinishedAt = DateTime.now();
      await _waitForRestoreEvents();

      if (showUi) {
        if (Get.isDialogOpen ?? false) {
          Get.back();
        }

        if (_restoredCount > 0) {
          MyDialogs.success(msg: 'Purchases restored successfully!');
          Get.offAll(() => const MainShellScreen());
        } else if (_restoreFailedCount > 0) {
          final detail = _restoreLastError?.replaceFirst('Exception: ', '');
          MyDialogs.error(
            msg: detail != null && detail.isNotEmpty
                ? 'Restore verification failed: $detail'
                : 'Restore verification failed. Please try again.',
          );
        } else {
          MyDialogs.info(msg: 'No active subscriptions found to restore.');
        }
      }
    } catch (e) {
      if (showUi) {
        if (Get.isDialogOpen ?? false) {
          Get.back();
        }
        MyDialogs.error(
          msg: 'Restore failed: ${e.toString().replaceFirst("Exception: ", "")}',
        );
      } else if (kDebugMode) {
        debugPrint('[PaymentController] silent restore failed: $e');
      }
    } finally {
      _isRestoring = false;
      _restoreHandlersInFlight = 0;
    }
  }

  Future<void> _waitForRestoreEvents() async {
    final deadline = DateTime.now().add(_restoreMaxWait);
    while (DateTime.now().isBefore(deadline)) {
      final idleSince = _lastRestoreHandlerFinishedAt;
      if (_restoreHandlersInFlight == 0 &&
          idleSince != null &&
          DateTime.now().difference(idleSince) >= _restoreIdleWindow) {
        return;
      }
      await Future<void>.delayed(const Duration(milliseconds: 200));
    }
  }

  void _handlePurchaseError(PurchaseDetails purchase) {
    isPurchasing.value = false;
    if (Get.isDialogOpen ?? false) {
      Get.back();
    }
    final message = purchase.error?.message;
    MyDialogs.error(
      msg: message != null && message.isNotEmpty
          ? message
          : 'Purchase failed. Please try again.',
    );
    _clearPending(fromSignup: _fromSignup);
  }

  void _handlePurchaseCancelled() {
    isPurchasing.value = false;
    if (Get.isDialogOpen ?? false) {
      Get.back();
    }
    onPurchaseCancelled(fromSignup: _fromSignup);
  }

  String _purchaseKey(PurchaseDetails purchase) =>
      '${purchase.productID}:${purchase.purchaseID ?? purchase.transactionDate ?? ''}';

  Future<void> _silentGuestActivation(int planIndex) async {
    final plan = PremiumPlan.values[planIndex.clamp(0, PremiumPlan.values.length - 1)];
    Pref.guestActivePlanIndex = planIndex;
    Pref.guestSubscriptionExpiresAt =
        DateTime.now().add(Duration(days: plan.daysInPlan));
  }

  Future<void> _silentLoggedInActivation({
    required int planIndex,
    required PurchaseDetails purchase,
  }) async {
    final backendUserId = Pref.currentUser?.backendUserId;
    if (backendUserId == null || backendUserId.isEmpty) return;

    final platform = Platform.isIOS ? 'ios' : 'android';
    final token = purchase.verificationData.serverVerificationData;
    final receiptData = platform == 'ios'
        ? await _iap.receiptDataForServerVerification(purchase)
        : null;
    if (platform == 'ios' &&
        (receiptData == null || IapService.looksLikeJws(receiptData))) {
      return;
    }
    final result = await PaymentApi.verifyStorePurchase(
      userId: backendUserId,
      platform: platform,
      productId: purchase.productID,
      purchaseToken: platform == 'android' ? token : null,
      receiptData: receiptData,
      transactionId: purchase.purchaseID,
    );
    if (result == null || !result.verified) return;

    final auth = Get.find<AuthController>();
    await _syncSubscriptionAfterVerify(
      auth: auth,
      result: result,
      planIndex: planIndex,
      showToast: false,
    );
  }

  Future<void> _syncSubscriptionAfterVerify({
    required AuthController auth,
    required StoreVerifyResponse result,
    required int planIndex,
    bool showToast = true,
  }) async {
    if (result.user != null) {
      final local = Pref.currentUser;
      auth.applyBackendUser(
        result.user!.copyWith(password: local?.password ?? ''),
      );
    } else {
      final premiumPlan = PremiumPlan
          .values[planIndex.clamp(0, PremiumPlan.values.length - 1)];
      await auth.updatePack(premiumPlan, showToast: showToast);
      if (result.subscriptionExpiresAt != null) {
        auth.setSubscriptionExpiresAt(result.subscriptionExpiresAt);
      }
    }
    await auth.refreshCurrentUserFromBackend();
  }

  Future<void> _handlePurchase(PurchaseDetails purchase) async {
    final purchaseKey = _purchaseKey(purchase);
    if (_handledPurchaseKeys.contains(purchaseKey)) {
      return;
    }

    final restoring = _isRestoring;
    final userInitiated = isPurchasing.value || restoring;
    if (restoring) {
      _restoreHandlersInFlight++;
    }

    final productId = purchase.productID;
    final planIndex = IapProducts.planIndexForProductId(productId);
    if (planIndex == null) {
      isPurchasing.value = false;
      if (restoring) {
        _restoreHandlersInFlight--;
        _lastRestoreHandlerFinishedAt = DateTime.now();
      }
      if (!restoring) {
        MyDialogs.error(msg: 'Unknown subscription product');
      }
      return;
    }

    final fromSignup = _fromSignup;
    final backendUserId = Pref.currentUser?.backendUserId;
    if (backendUserId == null || backendUserId.isEmpty) {
      await _silentGuestActivation(planIndex);
      _handledPurchaseKeys.add(purchaseKey);
      _guestMode = false;
      isPurchasing.value = false;
      if (restoring) {
        _restoredCount++;
        _restoreHandlersInFlight--;
        _lastRestoreHandlerFinishedAt = DateTime.now();
      } else if (userInitiated) {
        Get.offAll(() => const PaymentSuccessScreen());
        MyDialogs.success(msg: 'Subscription active');
      }
      return;
    }

    try {
      if (!userInitiated) {
        await _silentLoggedInActivation(
          planIndex: planIndex,
          purchase: purchase,
        );
        _handledPurchaseKeys.add(purchaseKey);
        isPurchasing.value = false;
        return;
      }

      final platform = Platform.isIOS ? 'ios' : 'android';
      final token = purchase.verificationData.serverVerificationData;
      final receiptData = platform == 'ios'
          ? await _iap.receiptDataForServerVerification(purchase)
          : null;
      if (platform == 'ios' &&
          (receiptData == null || IapService.looksLikeJws(receiptData))) {
        throw Exception(_iosReceiptUnavailableMessage);
      }
      final result = await PaymentApi.verifyStorePurchase(
        userId: backendUserId,
        platform: platform,
        productId: productId,
        purchaseToken: platform == 'android' ? token : null,
        receiptData: receiptData,
        transactionId: purchase.purchaseID,
      );

      if (result == null || !result.verified) {
        if (restoring) {
          _restoreFailedCount++;
          _restoreLastError = 'Subscription verification failed';
        } else {
          MyDialogs.error(msg: 'Subscription verification failed');
          _clearPending(fromSignup: fromSignup);
        }
        return;
      }

      final auth = Get.find<AuthController>();
      await _syncSubscriptionAfterVerify(
        auth: auth,
        result: result,
        planIndex: planIndex,
      );

      if (restoring) {
        _restoredCount++;
        _handledPurchaseKeys.add(purchaseKey);
        return;
      }

      _fromSignup = false;
      _handledPurchaseKeys.add(purchaseKey);
      Get.offAll(() => const PaymentSuccessScreen());
      MyDialogs.success(msg: 'Subscription active');
    } catch (e) {
      if (restoring) {
        _restoreFailedCount++;
        _restoreLastError = e.toString();
        if (kDebugMode) {
          debugPrint('[PaymentController] restore verify failed: $e');
        }
      } else {
        MyDialogs.error(msg: e.toString().replaceFirst('Exception: ', ''));
        _clearPending(fromSignup: fromSignup);
      }
    } finally {
      isPurchasing.value = false;
      if (restoring) {
        _restoreHandlersInFlight--;
        _lastRestoreHandlerFinishedAt = DateTime.now();
      }
    }
  }

  void _clearPending({required bool fromSignup}) {
    _fromSignup = false;
    _guestMode = false;
    if (fromSignup) {
      Get.offAll(() => const MainShellScreen());
    }
  }

  /// User cancelled before store sheet completes.
  void onPurchaseCancelled({bool fromSignup = false}) {
    if (fromSignup) {
      Get.offAll(() => const MainShellScreen());
    }
  }
}
