import 'dart:io';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

import '../apis/auth_api.dart';
import '../helpers/pref.dart';

/// Requests notification permission (Android 13+ and iOS both require it) and
/// keeps the backend's copy of this device's FCM token in sync for any
/// logged-in user. Only admins actually receive anything today (new-
/// subscription alerts) — the backend only ever pushes to admin accounts —
/// but the OS permission prompt itself isn't gated by role.
class PushNotificationService {
  static bool _permissionRequested = false;

  /// Call once at app start (after Firebase/Pref are ready).
  static Future<void> initialize() async {
    if (!kIsWeb && !Platform.isAndroid && !Platform.isIOS) return;
    try {
      if (!_permissionRequested) {
        _permissionRequested = true;
        final settings = await FirebaseMessaging.instance.requestPermission();
        if (kDebugMode) {
          debugPrint('[Push] Permission status: ${settings.authorizationStatus}');
        }
        // Still attempt token registration even if denied — a denied
        // *display* permission doesn't always block FCM token delivery
        // (Android in particular), and bailing here silently prevented the
        // backend from ever learning about this device at all.
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
      // On iOS, FCM's getToken() needs the APNs token to already be set on
      // the native side — right after requestPermission() that registration
      // is often still in flight, so getToken() throws apns-token-not-set.
      // Poll briefly for it before asking FCM for its own token.
      if (!kIsWeb && Platform.isIOS) {
        String? apnsToken = await FirebaseMessaging.instance.getAPNSToken();
        var attempts = 0;
        while (apnsToken == null && attempts < 10) {
          await Future.delayed(const Duration(seconds: 1));
          apnsToken = await FirebaseMessaging.instance.getAPNSToken();
          attempts++;
        }
        if (apnsToken == null) {
          if (kDebugMode) debugPrint('[Push] APNs token never arrived, skipping getToken()');
          return;
        }
      }
      final token = await FirebaseMessaging.instance.getToken();
      if (token != null) await _sendTokenToBackend(token);
    } catch (e) {
      if (kDebugMode) debugPrint('[Push] getToken failed: $e');
    }
  }

  static Future<void> _sendTokenToBackend(String token) async {
    if (!Pref.isLoggedIn || Pref.authToken == null) {
      if (kDebugMode) {
        debugPrint(
          '[Push] Got FCM token but not sending — isLoggedIn=${Pref.isLoggedIn} '
          'authToken=${Pref.authToken != null}. Will retry on next login.',
        );
      }
      return;
    }
    if (Pref.registeredFcmToken == token) {
      if (kDebugMode) debugPrint('[Push] Token unchanged, skipping re-registration.');
      return;
    }
    try {
      await AuthApi.registerFcmToken(token);
      Pref.registeredFcmToken = token;
      if (kDebugMode) debugPrint('[Push] Registered FCM token with backend.');
    } catch (e) {
      if (kDebugMode) debugPrint('[Push] registerFcmToken failed: $e');
    }
  }
}
