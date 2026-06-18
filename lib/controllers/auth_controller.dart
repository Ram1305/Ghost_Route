import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

import '../apis/auth_api.dart';
import '../helpers/my_dialogs.dart';
import '../helpers/pref.dart';
import '../models/subscription.dart';
import '../models/user.dart';

class AuthController extends GetxController {
  final Rx<User?> currentUser = (Pref.currentUser).obs;

  @override
  void onInit() {
    super.onInit();
    currentUser.value = Pref.currentUser;
  }

  /// Sends OTP to email via backend. [purpose]: 'signup' or 'forgot_password'.
  Future<bool> sendOtp(String email, [String purpose = 'signup']) async {
    if (email.trim().isEmpty) {
      MyDialogs.error(msg: 'Enter email');
      return false;
    }
    try {
      if (purpose == 'forgot_password') {
        await AuthApi.forgotPasswordSendOtp(email);
      } else {
        await AuthApi.sendOtp(email, purpose);
      }
      MyDialogs.success(msg: 'OTP sent to $email');
      return true;
    } catch (e) {
      MyDialogs.error(msg: e.toString().replaceFirst('Exception: ', ''));
      return false;
    }
  }

  /// Verifies OTP via backend. [purpose]: 'signup' or 'forgot_password'.
  Future<bool> verifyOtp(String email, String code, [String purpose = 'signup']) async {
    if (code.trim().isEmpty) {
      MyDialogs.error(msg: 'Enter OTP');
      return false;
    }
    try {
      final ok = await AuthApi.verifyOtp(email, code, purpose);
      if (ok) return true;
      MyDialogs.error(msg: 'Invalid or expired OTP');
      return false;
    } catch (e) {
      MyDialogs.error(msg: e.toString().replaceFirst('Exception: ', ''));
      return false;
    }
  }

  /// Sign up via backend. Also syncs user to Pref with backendUserId.
  Future<bool> signUp({
    required String username,
    required String email,
    required String phone,
    required String password,
    required String confirmPassword,
  }) async {
    if (username.trim().isEmpty) {
      MyDialogs.error(msg: 'Enter username');
      return false;
    }
    if (email.trim().isEmpty) {
      MyDialogs.error(msg: 'Enter email');
      return false;
    }
    if (password.isEmpty) {
      MyDialogs.error(msg: 'Enter password');
      return false;
    }
    if (password != confirmPassword) {
      MyDialogs.error(msg: 'Passwords do not match');
      return false;
    }
    try {
      final user = await AuthApi.register(
        email: email,
        password: password,
        username: username,
        phone: phone,
      );
      final users = Pref.users;
      final existing = users.where((u) => u.email.toLowerCase() == user.email.toLowerCase());
      if (existing.isEmpty) {
        users.add(user);
      } else {
        final idx = users.indexWhere((u) => u.email.toLowerCase() == user.email.toLowerCase());
        users[idx] = user;
      }
      Pref.users = users;
      Pref.currentUser = user;
      currentUser.value = user;
      MyDialogs.success(msg: 'Account created');
      return true;
    } catch (e) {
      MyDialogs.error(msg: e.toString().replaceFirst('Exception: ', ''));
      return false;
    }
  }

  /// Refreshes current user from backend (subscription, activePlan, subscriptionExpiresAt).
  /// Call on app start when user is logged in so "already purchased" is always in sync.
  Future<bool> refreshCurrentUserFromBackend() async {
    final u = Pref.currentUser;
    if (u == null || u.email.isEmpty || u.password.isEmpty) return false;
    try {
      final user = await AuthApi.login(u.email, u.password);
      var toStore = user.copyWith(password: u.password);
      // Keep locally verified subscription if backend profile is stale.
      final localPlan = u.activePlan ?? Pref.currentUserActivePlan;
      if (toStore.activePlan == null &&
          localPlan != null &&
          !Pref.isSubscriptionExpired(u, localPlan)) {
        toStore = toStore.copyWith(
          activePlan: localPlan,
          subscriptionExpiresAt: u.subscriptionExpiresAt,
          subscriptionHistory: u.subscriptionHistory.isNotEmpty
              ? u.subscriptionHistory
              : toStore.subscriptionHistory,
        );
      }
      final users = Pref.users;
      final idx = users.indexWhere((e) => e.email.toLowerCase() == user.email.toLowerCase());
      if (idx >= 0) {
        users[idx] = toStore;
      } else {
        users.add(toStore);
      }
      Pref.users = users;
      Pref.currentUser = toStore;
      currentUser.value = toStore;
      return true;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[AuthController] refreshCurrentUserFromBackend failed: $e');
      }
      return false;
    }
  }

  /// Login via backend. Stores user and backendUserId in Pref.
  Future<bool> login(String email, String password) async {
    if (email.trim().isEmpty) {
      MyDialogs.error(msg: 'Enter email');
      return false;
    }
    if (password.isEmpty) {
      MyDialogs.error(msg: 'Enter password');
      return false;
    }
    try {
      final user = await AuthApi.login(email, password);
      final users = Pref.users;
      final idx = users.indexWhere((u) => u.email.toLowerCase() == user.email.toLowerCase());
      final toStore = user.copyWith(password: password);
      if (idx >= 0) {
        users[idx] = toStore;
      } else {
        users.add(toStore);
      }
      Pref.users = users;
      Pref.currentUser = toStore;
      currentUser.value = toStore;
      MyDialogs.success(msg: 'Logged in');
      return true;
    } catch (e) {
      MyDialogs.error(msg: e.toString().replaceFirst('Exception: ', ''));
      return false;
    }
  }

  /// Replace local user with backend profile (subscription history, plan, expiry).
  void applyBackendUser(User backendUser) {
    final u = Pref.currentUser;
    if (u == null) return;
    final toStore = backendUser.copyWith(password: u.password);
    final users = Pref.users;
    final idx = users.indexWhere((e) => e.email.toLowerCase() == u.email.toLowerCase());
    if (idx >= 0) {
      users[idx] = toStore;
    }
    Pref.users = users;
    Pref.currentUser = toStore;
    currentUser.value = toStore;
  }

  /// Update current user's pack locally. Backend sync via activate-subscription when backendUserId is set.
  Future<bool> updatePack(PremiumPlan plan, {bool showToast = true}) async {
    final u = Pref.currentUser;
    if (u == null) return false;
    final updatedHistory = List<Subscription>.from(u.subscriptionHistory)
      ..add(Subscription(plan: plan, date: DateTime.now()));
    final updatedUser = u.copyWith(
      subscriptionHistory: updatedHistory,
      activePlan: plan,
    );
    final users = Pref.users;
    final idx = users.indexWhere((e) => e.email == u.email);
    if (idx == -1) return false;
    users[idx] = updatedUser;
    Pref.users = users;
    Pref.currentUser = updatedUser;
    currentUser.value = updatedUser;
    if (showToast) {
      final label = Subscription(plan: plan, date: DateTime.now()).planLabel;
      MyDialogs.success(msg: 'Plan updated to $label');
    }
    return true;
  }

  void setSubscriptionExpiresAt(DateTime? expiresAt) {
    final u = Pref.currentUser;
    if (u == null) return;
    final updated = u.copyWith(subscriptionExpiresAt: expiresAt);
    final users = Pref.users;
    final idx = users.indexWhere((e) => e.email == u.email);
    if (idx == -1) return;
    users[idx] = updated;
    Pref.users = users;
    Pref.currentUser = updated;
    currentUser.value = updated;
  }

  /// Reset password via backend (OTP verified in same request).
  Future<bool> resetPassword({
    required String email,
    required String otp,
    required String newPassword,
    required String confirmPassword,
  }) async {
    if (email.trim().isEmpty) {
      MyDialogs.error(msg: 'Enter email');
      return false;
    }
    if (newPassword.isEmpty) {
      MyDialogs.error(msg: 'Enter new password');
      return false;
    }
    if (newPassword != confirmPassword) {
      MyDialogs.error(msg: 'Passwords do not match');
      return false;
    }
    try {
      await AuthApi.forgotPasswordVerifyAndReset(
        email: email,
        code: otp,
        newPassword: newPassword,
      );
      final users = Pref.users;
      final idx = users.indexWhere((u) => u.email.toLowerCase() == email.trim().toLowerCase());
      if (idx >= 0) {
        users[idx] = users[idx].copyWith(password: newPassword);
        Pref.users = users;
        if (Pref.currentUser?.email.toLowerCase() == email.trim().toLowerCase()) {
          Pref.currentUser = users[idx];
          currentUser.value = users[idx];
        }
      }
      MyDialogs.success(msg: 'Password changed');
      return true;
    } catch (e) {
      MyDialogs.error(msg: e.toString().replaceFirst('Exception: ', ''));
      return false;
    }
  }

  /// Permanently deletes account on server and clears local session.
  Future<bool> deleteAccount({required String password}) async {
    final u = Pref.currentUser;
    if (u == null || u.email.isEmpty) {
      MyDialogs.error(msg: 'Not logged in');
      return false;
    }
    if (password.isEmpty) {
      MyDialogs.error(msg: 'Enter your password to confirm');
      return false;
    }
    try {
      await AuthApi.deleteAccount(email: u.email, password: password);
      final email = u.email.toLowerCase();
      final users = Pref.users.where((e) => e.email.toLowerCase() != email).toList();
      Pref.users = users;
      Pref.currentUser = null;
      currentUser.value = null;
      MyDialogs.success(msg: 'Account deleted');
      return true;
    } catch (e) {
      MyDialogs.error(msg: e.toString().replaceFirst('Exception: ', ''));
      return false;
    }
  }

  void logout() {
    Pref.currentUser = null;
    currentUser.value = null;
  }
}
