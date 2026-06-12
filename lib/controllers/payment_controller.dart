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
import '../screens/home_screen.dart';
import '../screens/payment_success_screen.dart';
import '../services/iap_service.dart';
import 'auth_controller.dart';

/// Subscriptions via App Store / Google Play (in_app_purchase).
class PaymentController extends GetxController {
  final IapService _iap = IapService.instance;
  List<ProductDetails> _storeProducts = [];
  bool _fromSignup = false;
  bool _iapReady = false;
  bool _isRestoring = false;
  int _restoredCount = 0;

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
  Future<void> openCheckout(Plan plan, {bool fromSignup = false}) async {
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
      if (fromSignup) Get.offAll(() => HomeScreen());
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
    if (!isPaymentSupported) {
      MyDialogs.error(msg: 'Restore is not supported on this device.');
      return;
    }
    if (!Pref.isLoggedIn) {
      MyDialogs.error(msg: 'Please log in first to restore your purchases.');
      return;
    }
    if (!_iapReady) {
      _iapReady = await _iap.initialize(
        onPurchase: _handlePurchase,
        onError: _handlePurchaseError,
        onCancelled: _handlePurchaseCancelled,
      );
    }
    MyDialogs.showProgress();
    _isRestoring = true;
    _restoredCount = 0;
    try {
      await _iap.restorePurchases();
      // Allow some time for native platforms to query and emit any past purchases to the stream
      await Future.delayed(const Duration(seconds: 2));
      
      if (Get.isDialogOpen ?? false) {
        Get.back();
      }

      if (_restoredCount > 0) {
        MyDialogs.success(msg: 'Purchases restored successfully!');
      } else {
        MyDialogs.info(msg: 'No active subscriptions found to restore.');
      }
    } catch (e) {
      if (Get.isDialogOpen ?? false) {
        Get.back();
      }
      MyDialogs.error(msg: 'Restore failed: ${e.toString().replaceFirst("Exception: ", "")}');
    } finally {
      _isRestoring = false;
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

  Future<void> _handlePurchase(PurchaseDetails purchase) async {
    final productId = purchase.productID;
    final planIndex = IapProducts.planIndexForProductId(productId);
    if (planIndex == null) {
      isPurchasing.value = false;
      MyDialogs.error(msg: 'Unknown subscription product');
      return;
    }

    final fromSignup = _fromSignup;
    final backendUserId = Pref.currentUser?.backendUserId;
    if (backendUserId == null || backendUserId.isEmpty) {
      isPurchasing.value = false;
      MyDialogs.error(msg: 'Sign in required before purchasing');
      return;
    }

    try {
      final platform = Platform.isIOS ? 'ios' : 'android';
      final token = purchase.verificationData.serverVerificationData;
      final result = await PaymentApi.verifyStorePurchase(
        userId: backendUserId,
        platform: platform,
        productId: productId,
        purchaseToken: platform == 'android' ? token : null,
        receiptData: platform == 'ios' ? token : null,
        transactionId: purchase.purchaseID,
      );

      if (result == null || !result.verified) {
        MyDialogs.error(msg: 'Subscription verification failed');
        _clearPending(fromSignup: fromSignup);
        return;
      }

      final auth = Get.find<AuthController>();
      if (result.user != null) {
        final local = Pref.currentUser;
        auth.applyBackendUser(
          result.user!.copyWith(password: local?.password ?? ''),
        );
      } else {
        final premiumPlan =
            PremiumPlan.values[planIndex.clamp(0, PremiumPlan.values.length - 1)];
        await auth.updatePack(premiumPlan);
        if (result.subscriptionExpiresAt != null) {
          auth.setSubscriptionExpiresAt(result.subscriptionExpiresAt);
        }
      }

      if (_isRestoring) {
        _restoredCount++;
      }

      _fromSignup = false;

      Get.offAll(() => const PaymentSuccessScreen());
      MyDialogs.success(msg: 'Subscription active');
    } catch (e) {
      MyDialogs.error(msg: e.toString().replaceFirst('Exception: ', ''));
      _clearPending(fromSignup: fromSignup);
    } finally {
      isPurchasing.value = false;
    }
  }

  void _clearPending({required bool fromSignup}) {
    _fromSignup = false;
    if (fromSignup) {
      Get.offAll(() => HomeScreen());
    }
  }

  /// User cancelled before store sheet completes.
  void onPurchaseCancelled({bool fromSignup = false}) {
    if (fromSignup) {
      Get.offAll(() => HomeScreen());
    }
  }
}
