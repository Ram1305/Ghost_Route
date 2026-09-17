import 'dart:async';
import 'dart:io';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import '../apis/auth_api.dart';
import '../helpers/pref.dart';

/// Requests notification permission (Android 13+ and iOS both require it) and
/// keeps the backend's copy of this device's FCM token in sync for any
/// logged-in user. Only admins actually receive anything today (new-
/// subscription alerts) — the backend only ever pushes to admin accounts —
/// but the OS permission prompt itself isn't gated by role.
class PushNotificationService {
  static bool _permissionRequested = false;
  static bool _refreshListening = false;
  static bool _lifecycleObserving = false;
  static Timer? _retryTimer;
  static int _retryCount = 0;
  static const int _maxRetries = 10;
  static final _lifecycleObserver = _PushLifecycleObserver();

  /// Call once at app start (after Firebase/Pref are ready).
  static Future<void> initialize() async {
    if (!kIsWeb && !Platform.isAndroid && !Platform.isIOS) return;
    try {
      // Listen before requesting a token so a late APNs/FCM callback is not missed.
      _listenForTokenRefresh();
      _observeLifecycle();
      if (!_permissionRequested) {
        _permissionRequested = true;
        final settings = await FirebaseMessaging.instance.requestPermission(
          alert: true,
          badge: true,
          sound: true,
        );
        await FirebaseMessaging.instance
            .setForegroundNotificationPresentationOptions(
          alert: true,
          badge: true,
          sound: true,
        );
        FirebaseMessaging.onMessage.listen((message) {
          if (kDebugMode) {
            debugPrint(
              '[Push] Foreground message: ${message.notification?.title} '
              '${message.notification?.body}',
            );
          }
        });
        if (kDebugMode) {
          debugPrint('[Push] Permission status: ${settings.authorizationStatus}');
        }
        // Still attempt token registration even if denied — a denied
        // *display* permission doesn't always block FCM token delivery
        // (Android in particular), and bailing here silently prevented the
        // backend from ever learning about this device at all.
      }
      await _registerCurrentToken();
    } catch (e) {
      if (kDebugMode) debugPrint('[Push] initialize failed: $e');
      _scheduleRetry();
    }
  }

  /// Call after a fresh login/signup/token-refresh so a token obtained
  /// before the user was authenticated gets sent now that we have one.
  static Future<void> registerAfterLogin() => _registerCurrentToken();

  static void _listenForTokenRefresh() {
    if (_refreshListening) return;
    _refreshListening = true;
    FirebaseMessaging.instance.onTokenRefresh.listen(_sendTokenToBackend);
  }

  static void _observeLifecycle() {
    if (_lifecycleObserving) return;
    _lifecycleObserving = true;
    WidgetsBinding.instance.addObserver(_lifecycleObserver);
  }

  static Future<void> _registerCurrentToken() async {
    try {
      // On iOS, FCM's getToken() needs the APNs token to already be set on
      // the native side — right after requestPermission() that registration
      // is often still in flight, so getToken() throws apns-token-not-set.
      if (!kIsWeb && Platform.isIOS) {
        final apnsReady = await _waitForApnsToken();
        if (!apnsReady) {
          _scheduleRetry();
          return;
        }
      }
      final token = await FirebaseMessaging.instance.getToken();
      if (token == null || token.isEmpty) {
        if (kDebugMode) debugPrint('[Push] getToken returned empty');
        _scheduleRetry();
        return;
      }
      if (kDebugMode) {
        final preview = token.length > 8
            ? '${token.substring(0, 4)}...${token.substring(token.length - 4)}'
            : token;
        debugPrint('[Push] Got FCM token len=${token.length} $preview');
      }
      await _sendTokenToBackend(token);
    } catch (e) {
      if (kDebugMode) debugPrint('[Push] getToken failed: $e');
      _scheduleRetry();
    }
  }

  /// Polls for the APNs device token. Returns false if it never arrived so
  /// the caller can retry later instead of giving up for the whole session.
  static Future<bool> _waitForApnsToken() async {
    String? apnsToken = await FirebaseMessaging.instance.getAPNSToken();
    var attempts = 0;
    while (apnsToken == null && attempts < 20) {
      await Future.delayed(const Duration(seconds: 1));
      apnsToken = await FirebaseMessaging.instance.getAPNSToken();
      attempts++;
    }
    if (apnsToken == null) {
      if (kDebugMode) {
        debugPrint('[Push] APNs token not ready yet, will retry');
      }
      return false;
    }
    return true;
  }

  static void _scheduleRetry() {
    if (_retryCount >= _maxRetries) return;
    _retryTimer?.cancel();
    final seconds = (5 * (1 + _retryCount)).clamp(5, 30);
    _retryCount++;
    _retryTimer = Timer(Duration(seconds: seconds), () {
      unawaited(_registerCurrentToken());
    });
  }

  static void _cancelRetry() {
    _retryTimer?.cancel();
    _retryTimer = null;
    _retryCount = 0;
  }

  static Future<void> _sendTokenToBackend(String token) async {
    if (token.isEmpty) return;
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
      _cancelRetry();
      if (kDebugMode) debugPrint('[Push] Token unchanged, skipping re-registration.');
      return;
    }
    try {
      await AuthApi.registerFcmToken(token);
      Pref.registeredFcmToken = token;
      _cancelRetry();
      if (kDebugMode) debugPrint('[Push] Registered FCM token with backend.');
    } catch (e) {
      if (kDebugMode) debugPrint('[Push] registerFcmToken failed: $e');
      _scheduleRetry();
    }
  }
}

class _PushLifecycleObserver with WidgetsBindingObserver {
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(PushNotificationService.registerAfterLogin());
    }
  }
}
