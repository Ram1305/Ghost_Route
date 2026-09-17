import 'dart:io';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

import '../apis/auth_api.dart';
import '../helpers/pref.dart';

/// Registers this device for push notifications and keeps the backend's copy
/// of the FCM token in sync. Currently used only for admin "new subscription"
/// alerts — safe to call for any logged-in user; only admins will actually
/// receive anything given today's single notification trigger.
class PushNotificationService {
  static bool _permissionRequested = false;

  /// Call once at app start (after Firebase/Pref are ready).
  static Future<void> initialize() async {
    if (!kIsWeb && !Platform.isAndroid && !Platform.isIOS) return;
    try {
      if (!_permissionRequested) {
        _permissionRequested = true;
        final settings = await FirebaseMessaging.instance.requestPermission();
        if (settings.authorizationStatus == AuthorizationStatus.denied) return;
      }
      await _registerCurrentToken();
      FirebaseMessaging.instance.onTokenRefresh.listen(_sendTokenToBackend);
    } catch (e) {
      if (kDebugMode) debugPrint('[Push] initialize failed: $e');
    }
  }

  /// Call after a fresh login/signup/token-refresh so a token obtained
  /// before the user was authenticated gets sent now that we have one.
  static Future<void> registerAfterLogin() => _registerCurrentToken();

  static Future<void> _registerCurrentToken() async {
    try {
      final token = await FirebaseMessaging.instance.getToken();
      if (token != null) await _sendTokenToBackend(token);
    } catch (e) {
      if (kDebugMode) debugPrint('[Push] getToken failed: $e');
    }
  }

  static Future<void> _sendTokenToBackend(String token) async {
    if (!Pref.isLoggedIn || Pref.authToken == null) return;
    if (Pref.registeredFcmToken == token) return;
    try {
      await AuthApi.registerFcmToken(token);
      Pref.registeredFcmToken = token;
    } catch (e) {
      if (kDebugMode) debugPrint('[Push] registerFcmToken failed: $e');
    }
  }
}
