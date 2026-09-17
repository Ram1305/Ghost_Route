import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/app_config.dart';
import '../helpers/pref.dart';
import '../helpers/subscription_expiry.dart';
import '../models/subscription.dart';
import '../models/user.dart';

/// Result of a register/login call: the user plus the bearer token to send
/// on subsequent authenticated requests (e.g. admin endpoints).
class AuthResult {
  final User user;
  final String? token;
  AuthResult(this.user, this.token);
}

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

  static List<Subscription> subscriptionHistoryFromJson(dynamic historyRaw) {
    if (historyRaw is! List) return [];
    final history = <Subscription>[];
    for (final e in historyRaw) {
      if (e is! Map) continue;
      try {
        history.add(
          Subscription.fromJson(Map<String, dynamic>.from(e)),
        );
      } catch (_) {
        // Skip malformed entries so one bad row does not break login/sync.
      }
    }
    return history;
  }

  static User userFromBackendJson(Map<String, dynamic> json, {String? backendUserId}) {
    final id = backendUserId ?? json['_id']?.toString();
    final history = subscriptionHistoryFromJson(json['subscriptionHistory']);
    final activePlanRaw = json['activePlan'];
    PremiumPlan? active;
    if (activePlanRaw != null && activePlanRaw is int) {
      active = PremiumPlanX.fromStoredIndex(activePlanRaw);
    }
    final expiresAtRaw = json['subscriptionExpiresAt'];
    final DateTime? expiresAt = parseSubscriptionDate(expiresAtRaw);
    final roleRaw = json['role'];
    final role = roleRaw == 'admin' ? 'admin' : 'user';
    return User(
      username: json['username'] as String? ?? '',
      email: json['email'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      password: '',
      subscriptionHistory: history,
      activePlan: active,
      subscriptionExpiresAt: expiresAt,
      backendUserId: id,
      role: role,
    );
  }

  /// Register after OTP verified. Returns created user, backendUserId and auth token.
  static Future<AuthResult> register({
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
    final user = userFromBackendJson(Map<String, dynamic>.from(userJson), backendUserId: backendUserId);
    return AuthResult(user, data['token'] as String?);
  }

  /// Login. Returns user with backendUserId and auth token.
  static Future<AuthResult> login(String email, String password) async {
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
    final user = userFromBackendJson(Map<String, dynamic>.from(userJson), backendUserId: backendUserId);
    return AuthResult(user, data['token'] as String?);
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

  /// Permanently deletes the account on the backend.
  static Future<void> deleteAccount({
    required String email,
    required String password,
  }) async {
    final res = await http.post(
      Uri.parse('$_base/api/auth/delete-account'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': email.trim().toLowerCase(),
        'password': password,
      }),
    );
    if (res.statusCode == 204) return;
    final data = jsonDecode(res.body) as Map<String, dynamic>?;
    throw Exception(data?['error'] as String? ?? 'Failed to delete account');
  }

  /// Registers this device's FCM token for push notifications. Requires
  /// [Pref.authToken] (set after login/register); no-ops silently if absent.
  static Future<void> registerFcmToken(String token) async {
    final authToken = Pref.authToken;
    if (authToken == null) return;
    final res = await http.post(
      Uri.parse('$_base/api/users/me/fcm-token'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $authToken',
      },
      body: jsonEncode({'token': token}),
    );
    if (res.statusCode != 200) {
      final data = jsonDecode(res.body) as Map<String, dynamic>?;
      throw Exception(data?['error'] as String? ?? 'Failed to register device for push');
    }
  }
}
