import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:in_app_purchase_storekit/in_app_purchase_storekit.dart';

import 'firebase_options.dart';
import 'theme/nexus_theme.dart';
import 'helpers/config.dart';
import 'helpers/my_dialogs.dart';
import 'helpers/pref.dart';
import 'screens/splash_screen.dart';
import 'services/push_notification_service.dart';

import 'package:firebase_messaging/firebase_messaging.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  if (Firebase.apps.isEmpty) {
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  }
}

//global object for accessing device screen size
late Size mq;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // StoreKit 1 provides base64 app receipts compatible with verifyReceipt.
  if (!kIsWeb && Platform.isIOS) {
    // ignore: deprecated_member_use
    await InAppPurchaseStoreKitPlatform.enableStoreKit1();
  }

  // Immersive system UI / orientation lock are Android & iOS phone concepts;
  // meaningless (and on Windows, actively wrong) for a resizable desktop window.
  final isMobile = !kIsWeb && (Platform.isAndroid || Platform.isIOS);

  //enter full-screen
  if (isMobile) {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersive);
  }

  // iOS may auto-configure from GoogleService-Info.plist before Dart sees any apps.
  if (Firebase.apps.isEmpty) {
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    } on FirebaseException catch (e) {
      if (e.code != 'duplicate-app') rethrow;
    }
  }

  if (isMobile) {
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  }

  // Remote config (app update checks, etc.) — firebase_remote_config has no
  // Windows implementation; calling it there throws MissingPluginException
  // before runApp(), which leaves the native window created but never shown.
  if (!Platform.isWindows) {
    await Config.initConfig();
  }

  await Pref.initializeHive();

  // Ask for notification permission on every app open (Android 13+ and iOS
  // both require it). Only admins receive anything today (new-subscription
  // alerts), but the OS prompt itself isn't gated by role. Fire-and-forget
  // so a slow permission dialog never blocks first paint.
  if (isMobile) {
    unawaited(PushNotificationService.initialize());
  }

  // VPN engine init is deferred until first connect on both platforms so the
  // Activity (Android) is ready for VpnService.prepare() and permission dialog.
  // Early init on Android caused IPC/context issues and VPN not working.

  //for setting orientation to portrait only
  if (isMobile) {
    await SystemChrome.setPreferredOrientations(
        [DeviceOrientation.portraitUp, DeviceOrientation.portraitDown]);
  }
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Ghost Route',
      scaffoldMessengerKey: MyDialogs.rootScaffoldMessengerKey,
      home: const SplashScreen(),

      // Tron VPN theme — dark by default; Settings > Appearance can switch to
      // light (Pref.isDarkMode), applied via Get.changeThemeMode + forceAppUpdate.
      theme: NexusTheme.lightTheme,
      darkTheme: NexusTheme.darkTheme,
      themeMode: Pref.isDarkMode ? ThemeMode.dark : ThemeMode.light,

      debugShowCheckedModeBanner: false,
    );
  }
}

extension AppTheme on ThemeData {
  Color get lightText => NexusTheme.text2;
  Color get bottomNav => NexusTheme.teal;
}
