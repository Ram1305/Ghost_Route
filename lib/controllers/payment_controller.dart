import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';

import '../apis/payment_api.dart';
import '../helpers/my_dialogs.dart';
import '../helpers/pref.dart';
import '../models/plan.dart';
import '../models/subscription.dart';
import '../screens/login_screen.dart';
import '../screens/payment_success_screen.dart';
import 'auth_controller.dart';

/// Handles Razorpay checkout: create order → open checkout → verify → update pack.
/// Razorpay Flutter is supported on Android and iOS only.
class PaymentController extends GetxController {
  Razorpay? _razorpay;
  Plan? _pendingPlan;
  bool _fromSignup = false;

  bool get isPaymentSupported =>
      !kIsWeb && (Platform.isAndroid || Platform.isIOS);

  @override
  void onInit() {
    super.onInit();
    if (isPaymentSupported) {
      _razorpay = Razorpay();
      _razorpay!.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
      _razorpay!.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
      _razorpay!.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
    }
  }

  @override
  void onClose() {
    _razorpay?.clear();
    _razorpay = null;
    super.onClose();
  }

  /// Start payment for [plan]: create order from backend, open Razorpay checkout.
  /// When [fromSignup] is true: on success navigate to payment success screen then home; on failure navigate to login.
  Future<void> openCheckout(Plan plan, {bool fromSignup = false}) async {
    if (!isPaymentSupported) {
      MyDialogs.error(msg: 'Payments are not supported on this device.');
      return;
    }

    _pendingPlan = plan;
    _fromSignup = fromSignup;
    try {
      final order = await PaymentApi.createOrder(
        amount: plan.amount,
        currency: plan.currency,
        receipt: 'tronvpn_${plan.name}_${DateTime.now().millisecondsSinceEpoch}',
        notes: {'plan': plan.name},
      );
      if (order == null) {
        MyDialogs.error(msg: 'Could not create order');
        _pendingPlan = null;
        if (_fromSignup) {
          _fromSignup = false;
          Get.offAll(() => const LoginScreen());
        }
        return;
      }

      final options = {
        'key': order.keyId,
        'amount': order.amount,
        'currency': order.currency,
        'name': 'Tron VPN',
        'order_id': order.orderId,
        'description': '${plan.intervalLabel} · ${plan.price}',
      };

      _razorpay!.open(options);
    } catch (e) {
      _pendingPlan = null;
      MyDialogs.error(msg: e.toString().replaceFirst('Exception: ', ''));
      if (_fromSignup) {
        _fromSignup = false;
        Get.offAll(() => const LoginScreen());
      }
    }
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) {
    final plan = _pendingPlan;
    _pendingPlan = null;
    if (plan == null) return;

    final orderId = response.orderId;
    final paymentId = response.paymentId;
    final signature = response.signature;
    if (orderId == null || paymentId == null || signature == null) {
      MyDialogs.error(msg: 'Invalid payment response');
      return;
    }

    _verifyAndUpdatePack(
      plan: plan,
      razorpayOrderId: orderId,
      razorpayPaymentId: paymentId,
      razorpaySignature: signature,
    );
  }

  Future<void> _verifyAndUpdatePack({
    required Plan plan,
    required String razorpayOrderId,
    required String razorpayPaymentId,
    required String razorpaySignature,
  }) async {
    try {
      final result = await PaymentApi.verify(
        razorpayOrderId: razorpayOrderId,
        razorpayPaymentId: razorpayPaymentId,
        razorpaySignature: razorpaySignature,
      );

      if (result == null || !result.verified) {
        MyDialogs.error(msg: 'Payment verification failed');
        if (_fromSignup) {
          _fromSignup = false;
          Get.offAll(() => const LoginScreen());
        }
        return;
      }

      final auth = Get.find<AuthController>();
      final premiumPlan = PremiumPlan.values[plan.index.clamp(0, PremiumPlan.values.length - 1)];
      final ok = await auth.updatePack(premiumPlan);
      if (ok) {
        final backendUserId = Pref.currentUser?.backendUserId;
        if (backendUserId != null) {
          try {
            final activateResult = await PaymentApi.activateSubscription(
              userId: backendUserId,
              plan: plan.index,
              orderId: razorpayOrderId,
              paymentId: razorpayPaymentId,
            );
            if (activateResult?.subscriptionExpiresAt != null) {
              auth.setSubscriptionExpiresAt(activateResult!.subscriptionExpiresAt);
            }
          } catch (_) {
            // Local pack already updated; backend activation failed
          }
        }
        if (_fromSignup) {
          _fromSignup = false;
          Get.offAll(() => const PaymentSuccessScreen());
        } else {
          Get.back(); // leave premium screen
        }
      }
    } catch (e) {
      MyDialogs.error(msg: e.toString().replaceFirst('Exception: ', ''));
      if (_fromSignup) {
        _fromSignup = false;
        Get.offAll(() => const LoginScreen());
      }
    }
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    _pendingPlan = null;
    final msg = response.message ?? 'Payment failed';
    if (response.code == Razorpay.PAYMENT_CANCELLED) {
      if (_fromSignup) {
        _fromSignup = false;
        Get.offAll(() => const LoginScreen());
      }
      return; // user cancelled, no need to show error
    }
    MyDialogs.error(msg: msg);
    if (_fromSignup) {
      _fromSignup = false;
      Get.offAll(() => const LoginScreen());
    }
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    _pendingPlan = null;
    MyDialogs.info(msg: 'External wallet: ${response.walletName}');
  }
}
