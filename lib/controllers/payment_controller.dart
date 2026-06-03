import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

import '../apis/payment_api.dart';
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
    _iapReady = await _iap.initialize(_handlePurchase);
    if (_iapReady) {
      await loadStoreProducts();
    }
  }

  @override
  void onClose() {
    _iap.dispose();
    super.onClose();
  }

  Future<void> loadStoreProducts() async {
    if (!isPaymentSupported) return;
    isLoadingProducts.value = true;
    try {
      _storeProducts = await _iap.queryProducts();
    } finally {
      isLoadingProducts.value = false;
    }
  }

  /// Start in-app subscription purchase for [plan].
  Future<void> openCheckout(Plan plan, {bool fromSignup = false}) async {
    if (!isPaymentSupported) {
      MyDialogs.error(msg: 'Subscriptions are not supported on this device.');
      return;
    }
    if (!_iapReady) {
      _iapReady = await _iap.initialize(_handlePurchase);
      if (!_iapReady) {
        MyDialogs.error(msg: 'Store is not available. Try again later.');
        return;
      }
    }
    if (_storeProducts.isEmpty) {
      await loadStoreProducts();
    }

    final product = _iap.productForPlanIndex(plan.index, _storeProducts);
    if (product == null) {
      MyDialogs.error(
        msg:
            'Subscription not found in the store. Ensure products are configured in App Store Connect / Play Console.',
      );
      if (fromSignup) Get.offAll(() => HomeScreen());
      return;
    }

    _fromSignup = fromSignup;
    isPurchasing.value = true;
    try {
      final started = await _iap.buy(product);
      if (!started) {
        MyDialogs.error(msg: 'Could not start purchase');
        _clearPending(fromSignup: fromSignup);
      }
    } catch (e) {
      MyDialogs.error(msg: e.toString().replaceFirst('Exception: ', ''));
      _clearPending(fromSignup: fromSignup);
    } finally {
      isPurchasing.value = false;
    }
  }

  Future<void> restorePurchases() async {
    if (!isPaymentSupported) {
      MyDialogs.error(msg: 'Restore is not supported on this device.');
      return;
    }
    if (!_iapReady) {
      _iapReady = await _iap.initialize(_handlePurchase);
    }
    MyDialogs.info(msg: 'Restoring purchases…');
    await _iap.restorePurchases();
  }

  Future<void> _handlePurchase(PurchaseDetails purchase) async {
    final productId = purchase.productID;
    final planIndex = IapProducts.planIndexForProductId(productId);
    if (planIndex == null) {
      MyDialogs.error(msg: 'Unknown subscription product');
      return;
    }

    final fromSignup = _fromSignup;
    final backendUserId = Pref.currentUser?.backendUserId;
    if (backendUserId == null || backendUserId.isEmpty) {
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
      final premiumPlan =
          PremiumPlan.values[planIndex.clamp(0, PremiumPlan.values.length - 1)];
      await auth.updatePack(premiumPlan);
      if (result.subscriptionExpiresAt != null) {
        auth.setSubscriptionExpiresAt(result.subscriptionExpiresAt);
      }

      _fromSignup = false;

      if (fromSignup) {
        Get.offAll(() => const PaymentSuccessScreen());
      } else if (Get.key.currentState?.canPop() == true) {
        Get.back();
      }
      MyDialogs.success(msg: 'Subscription active');
    } catch (e) {
      MyDialogs.error(msg: e.toString().replaceFirst('Exception: ', ''));
      _clearPending(fromSignup: fromSignup);
    }
  }

  void _clearPending({required bool fromSignup}) {
    _fromSignup = false;
    if (fromSignup) {
      Get.offAll(() => HomeScreen());
    }
  }

  /// User cancelled before store sheet — used if we add explicit cancel handling.
  void onPurchaseCancelled({bool fromSignup = false}) {
    if (fromSignup) {
      Get.offAll(() => HomeScreen());
    }
  }
}
