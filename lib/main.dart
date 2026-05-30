import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:firebase_core/firebase_core.dart';

import 'firebase_options.dart';
import 'services/vpn_engine.dart';
import 'theme/nexus_theme.dart';
// TODO: Restore ads - import 'helpers/ad_helper.dart';
// TODO: Restore ads - import 'helpers/config.dart';
import 'helpers/my_dialogs.dart';
import 'helpers/pref.dart';
import 'screens/splash_screen.dart';

//global object for accessing device screen size
late Size mq;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  //enter full-screen
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersive);

  //firebase initialization
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // TODO: Restore ads - initializing remote config
  // await Config.initConfig();

  await Pref.initializeHive();

  // Initialize VPN engine on Android only at startup. On iOS, init is deferred
  // until first connect — avoids crash when init fails (simulator or permissions)
  // as the plugin may call stopVPN internally on failure.
  if (Platform.isAndroid) {
    try {
      await VpnEngine.initialize();
    } catch (e) {
      debugPrint('VPN init skipped: $e');
    }
  }

  // TODO: Restore ads
  // await AdHelper.initAds();

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
      title: 'Yencode VPN',
      scaffoldMessengerKey: MyDialogs.rootScaffoldMessengerKey,
      home: const SplashScreen(),

      // Yencode VPN dark theme
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
