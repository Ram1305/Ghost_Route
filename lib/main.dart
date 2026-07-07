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

//global object for accessing device screen size
late Size mq;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // StoreKit 1 provides base64 app receipts compatible with verifyReceipt.
  if (!kIsWeb && Platform.isIOS) {
    // ignore: deprecated_member_use
    await InAppPurchaseStoreKitPlatform.enableStoreKit1();
  }

  //enter full-screen
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersive);

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

  // Remote config (app update checks, etc.)
  await Config.initConfig();

  await Pref.initializeHive();

  // VPN engine init is deferred until first connect on both platforms so the
  // Activity (Android) is ready for VpnService.prepare() and permission dialog.
  // Early init on Android caused IPC/context issues and VPN not working.

  //for setting orientation to portrait only
  await SystemChrome.setPreferredOrientations(
      [DeviceOrientation.portraitUp, DeviceOrientation.portraitDown]).then((v) {
    runApp(const MyApp());
  });
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Ghost Route',
      scaffoldMessengerKey: MyDialogs.rootScaffoldMessengerKey,
      home: const SplashScreen(),

      // Tron VPN dark theme
      theme: NexusTheme.darkTheme,
      themeMode: ThemeMode.dark,

      debugShowCheckedModeBanner: false,
    );
  }
}

extension AppTheme on ThemeData {
  Color get lightText => NexusTheme.text2;
  Color get bottomNav => NexusTheme.teal;
}
