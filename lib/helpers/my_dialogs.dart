import 'package:flutter/material.dart';
import 'package:get/get.dart';

class MyDialogs {
  /// Global key for ScaffoldMessenger - avoids Overlay.of/_Theater errors during
  /// route transitions or when Get.overlayContext is not ready.
  static final rootScaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();

  /// Shows snackbar via ScaffoldMessenger (no Overlay.of lookup needed).
  static void _showSnackbar(SnackBar snackBar) {
    void tryShow() {
      rootScaffoldMessengerKey.currentState?.showSnackBar(snackBar);
    }

    if (rootScaffoldMessengerKey.currentContext != null &&
        rootScaffoldMessengerKey.currentState != null) {
      tryShow();
      return;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (rootScaffoldMessengerKey.currentState != null) {
        tryShow();
      } else {
        Future.delayed(const Duration(milliseconds: 100), tryShow);
      }
    });
  }

  /// Shared snackbar styling so messages are visible above bottom nav and in dark theme.
  static SnackBar _snackBar({
    required String msg,
    required Color backgroundColor,
    Duration duration = const Duration(seconds: 3),
  }) {
    return SnackBar(
      content: Text(
        msg,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      ),
      backgroundColor: backgroundColor,
      behavior: SnackBarBehavior.floating,
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 100),
      duration: duration,
    );
  }

  static success({required String msg}) {
    _showSnackbar(_snackBar(
      msg: msg,
      backgroundColor: Colors.green.withOpacity(0.95),
    ));
  }

  static error({required String msg}) {
    _showSnackbar(_snackBar(
      msg: msg,
      backgroundColor: Colors.redAccent.withOpacity(0.95),
      duration: const Duration(seconds: 4),
    ));
  }

  static info({required String msg}) {
    _showSnackbar(_snackBar(
      msg: msg,
      backgroundColor: const Color(0xFF1E2D2A),
    ));
  }

  static showProgress() {
    Get.dialog(Center(child: CircularProgressIndicator(strokeWidth: 2)));
  }
}
