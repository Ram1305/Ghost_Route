import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/app_config.dart';
import '../models/subscription.dart';
import '../models/user.dart';

/// Auth API – OTP, register, login, forgot password (backend).
class AuthApi {
  static String get _base => AppConfig.apiBaseUrl;

  static Future<bool> sendOtp(String email, String purpose) async {
    try {
      final res = await http.post(
        Uri.parse('$_base/api/auth/send-otp'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email.trim().toLowerCase(), 'purpose': purpose}),
      );
      if (res.statusCode == 200) return true;
      final data = jsonDecode(res.body) as Map<String, dynamic>?;
      throw Exception(data?['error'] as String? ?? 'Failed to send OTP');
    } catch (e) {
      rethrow;
    }
  }

  static Future<bool> verifyOtp(String email, String code, String purpose) async {
    try {
      final res = await http.post(
        Uri.parse('$_base/api/auth/verify-otp'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email.trim().toLowerCase(),
          'code': code.trim(),
          'purpose': purpose,
        }),
      );
      if (res.statusCode == 200) return true;
      final data = jsonDecode(res.body) as Map<String, dynamic>?;
      throw Exception(data?['error'] as String? ?? 'Invalid or expired OTP');
    } catch (e) {
      rethrow;
    }
  }

  static User _userFromBackendJson(Map<String, dynamic> json, {String? backendUserId}) {
    final id = backendUserId ?? json['_id']?.toString();
    final historyRaw = json['subscriptionHistory'];
    List<Subscription> history = [];
    if (historyRaw is List) {
      for (final e in historyRaw) {
        if (e is Map) history.add(Subscription.fromJson(Map<String, dynamic>.from(e as Map)));
      }
    }
    final activePlanRaw = json['activePlan'];
    PremiumPlan? active;
    if (activePlanRaw != null && activePlanRaw is int && activePlanRaw >= 0 && activePlanRaw < PremiumPlan.values.length) {
      active = PremiumPlan.values[activePlanRaw];
    }
    final expiresAtRaw = json['subscriptionExpiresAt'];
    final DateTime? expiresAt = expiresAtRaw is String ? DateTime.tryParse(expiresAtRaw) : null;
    return User(
      username: json['username'] as String? ?? '',
      email: json['email'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      password: '',
      subscriptionHistory: history,
      activePlan: active,
      subscriptionExpiresAt: expiresAt,
      backendUserId: id,
    );
  }

  /// Register after OTP verified. Returns created user and backendUserId.
  static Future<User> register({
    required String email,
    required String password,
    required String username,
    String phone = '',
  }) async {
    final res = await http.post(
      Uri.parse('$_base/api/auth/register'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': email.trim().toLowerCase(),
        'password': password,
        'username': username.trim(),
        'phone': phone.trim(),
      }),
    );
    final data = jsonDecode(res.body) as Map<String, dynamic>;
    if (res.statusCode != 201) {
      throw Exception(data['error'] as String? ?? 'Registration failed');
    }
    final userJson = data['user'] as Map<String, dynamic>? ?? data;
    final backendUserId = data['backendUserId'] as String?;
    return _userFromBackendJson(Map<String, dynamic>.from(userJson), backendUserId: backendUserId);
  }

  /// Login. Returns user with backendUserId.
  static Future<User> login(String email, String password) async {
    final res = await http.post(
      Uri.parse('$_base/api/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': email.trim().toLowerCase(),
        'password': password,
      }),
    );
    final data = jsonDecode(res.body) as Map<String, dynamic>;
    if (res.statusCode != 200) {
      throw Exception(data['error'] as String? ?? 'Login failed');
    }
    final userJson = data['user'] as Map<String, dynamic>? ?? data;
    final backendUserId = data['backendUserId'] as String?;
    return _userFromBackendJson(Map<String, dynamic>.from(userJson), backendUserId: backendUserId);
  }

  static Future<bool> forgotPasswordSendOtp(String email) async {
    try {
      final res = await http.post(
        Uri.parse('$_base/api/auth/forgot-password/send-otp'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email.trim().toLowerCase()}),
      );
      if (res.statusCode == 200) return true;
      final data = jsonDecode(res.body) as Map<String, dynamic>?;
      throw Exception(data?['error'] as String? ?? 'Failed to send OTP');
    } catch (e) {
      rethrow;
    }
  }

  static Future<bool> forgotPasswordVerifyAndReset({
    required String email,
    required String code,
    required String newPassword,
  }) async {
    final res = await http.post(
      Uri.parse('$_base/api/auth/forgot-password/verify-and-reset'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': email.trim().toLowerCase(),
        'code': code.trim(),
        'newPassword': newPassword,
      }),
    );
    if (res.statusCode == 200) return true;
    final data = jsonDecode(res.body) as Map<String, dynamic>?;
    throw Exception(data?['error'] as String? ?? 'Failed to reset password');
  }
}
