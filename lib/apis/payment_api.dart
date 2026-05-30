import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/app_config.dart';
import '../models/plan.dart';

/// Payment API – create order, verify, and get plans via backend (Razorpay).
class PaymentApi {
  static String get _base => AppConfig.apiBaseUrl;

  /// Fetch all plans from backend. Returns list sorted by index (0–5).
  static Future<List<Plan>> getPlans() async {
    final res = await http.get(Uri.parse('$_base/api/payments/plans'));
    if (res.statusCode != 200) {
      final err = jsonDecode(res.body) as Map<String, dynamic>?;
      throw Exception(err?['error'] ?? 'Failed to load plans');
    }
    final list = jsonDecode(res.body) as List<dynamic>;
    return list.map((e) => Plan.fromJson(e as Map<String, dynamic>)).toList();
  }

  /// Create a Razorpay order. [amount] in smallest unit (paise for INR, cents for USD).
  static Future<CreateOrderResponse?> createOrder({
    required int amount,
    String currency = 'INR',
    String? receipt,
    Map<String, String>? notes,
  }) async {
    try {
      final res = await http.post(
        Uri.parse('$_base/api/payments/create-order'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'amount': amount,
          'currency': currency,
          if (receipt != null) 'receipt': receipt,
          if (notes != null) 'notes': notes,
        }),
      );
      if (res.statusCode != 201) {
        final err = jsonDecode(res.body);
        throw Exception(err['error'] ?? 'Failed to create order');
      }
      final data = jsonDecode(res.body) as Map<String, dynamic>;
      return CreateOrderResponse(
        orderId: data['orderId'] as String,
        amount: (data['amount'] as num).toInt(),
        currency: data['currency'] as String? ?? currency,
        keyId: data['keyId'] as String,
      );
    } catch (e) {
      rethrow;
    }
  }

  /// Verify payment after Razorpay success.
  static Future<VerifyPaymentResponse?> verify({
    required String razorpayOrderId,
    required String razorpayPaymentId,
    required String razorpaySignature,
  }) async {
    try {
      final res = await http.post(
        Uri.parse('$_base/api/payments/verify'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'razorpay_order_id': razorpayOrderId,
          'razorpay_payment_id': razorpayPaymentId,
          'razorpay_signature': razorpaySignature,
        }),
      );
      final data = jsonDecode(res.body) as Map<String, dynamic>;
      if (res.statusCode != 200) {
        throw Exception(data['error'] ?? 'Verification failed');
      }
      return VerifyPaymentResponse(
        verified: data['verified'] as bool? ?? false,
        orderId: data['orderId'] as String?,
        paymentId: data['paymentId'] as String?,
      );
    } catch (e) {
      rethrow;
    }
  }

  /// Activate subscription on backend after successful payment.
  /// Call when user has backendUserId (e.g. logged in via API).
  static Future<ActivateSubscriptionResponse?> activateSubscription({
    required String userId,
    required int plan,
    String? orderId,
    String? paymentId,
  }) async {
    try {
      final res = await http.post(
        Uri.parse('$_base/api/payments/activate-subscription'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'userId': userId,
          'plan': plan,
          if (orderId != null) 'orderId': orderId,
          if (paymentId != null) 'paymentId': paymentId,
        }),
      );
      final data = jsonDecode(res.body) as Map<String, dynamic>;
      if (res.statusCode != 200) {
        throw Exception(data['error'] ?? 'Failed to activate subscription');
      }
      final expiresAtRaw = data['subscriptionExpiresAt'];
      final DateTime? subscriptionExpiresAt = expiresAtRaw is String
          ? DateTime.tryParse(expiresAtRaw)
          : null;
      return ActivateSubscriptionResponse(
        activePlan: data['activePlan'] as int?,
        subscriptionExpiresAt: subscriptionExpiresAt,
      );
    } catch (e) {
      rethrow;
    }
  }
}

class ActivateSubscriptionResponse {
  final int? activePlan;
  final DateTime? subscriptionExpiresAt;

  ActivateSubscriptionResponse({
    this.activePlan,
    this.subscriptionExpiresAt,
  });
}

class CreateOrderResponse {
  final String orderId;
  final int amount;
  final String currency;
  final String keyId;

  CreateOrderResponse({
    required this.orderId,
    required this.amount,
    required this.currency,
    required this.keyId,
  });
}

class VerifyPaymentResponse {
  final bool verified;
  final String? orderId;
  final String? paymentId;

  VerifyPaymentResponse({
    required this.verified,
    this.orderId,
    this.paymentId,
  });
}
