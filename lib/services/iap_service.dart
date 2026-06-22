import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:in_app_purchase_platform_interface/in_app_purchase_platform_interface.dart';
import 'package:in_app_purchase_storekit/in_app_purchase_storekit.dart';
import 'package:in_app_purchase_storekit/store_kit_wrappers.dart';

import '../config/iap_products.dart';

typedef PurchaseHandler = Future<void> Function(PurchaseDetails purchase);
typedef PurchaseErrorHandler = void Function(PurchaseDetails purchase);
typedef PurchaseCancelledHandler = void Function();

/// Wraps [InAppPurchase] for subscription purchases on iOS and Android.
class IapService {
  IapService._();
  static final IapService instance = IapService._();

  final InAppPurchase _iap = InAppPurchase.instance;
  StreamSubscription<List<PurchaseDetails>>? _subscription;
  PurchaseHandler? _onPurchase;
  PurchaseErrorHandler? _onError;
  PurchaseCancelledHandler? _onCancelled;

  Future<List<ProductDetails>>? _productQueryInFlight;
  List<ProductDetails> _cachedProducts = const [];
  DateTime? _productsCachedAt;
  IAPError? _lastQueryError;
  String? _cachedIosReceipt;
  DateTime? _cachedIosReceiptAt;
  Future<String?>? _iosReceiptFetchInFlight;

  static const Duration _productCacheTtl = Duration(minutes: 10);
  static const Duration _receiptCacheTtl = Duration(minutes: 5);
  static const List<Duration> _receiptRetryDelays = [
    Duration(milliseconds: 500),
    Duration(milliseconds: 1000),
    Duration(milliseconds: 1500),
    Duration(milliseconds: 2000),
  ];

  bool get isSupported => !kIsWeb && (Platform.isIOS || Platform.isAndroid);

  /// True when [data] is a StoreKit 2 JWS token (not a verifyReceipt app receipt).
  static bool looksLikeJws(String? data) =>
      data != null && data.trim().startsWith('eyJ');

  /// Last StoreKit / Play Billing error from a product query, if any.
  IAPError? get lastQueryError => _lastQueryError;

  bool get hasCachedProducts => _cachedProducts.isNotEmpty;

  Future<bool> initialize({
    required PurchaseHandler onPurchase,
    PurchaseErrorHandler? onError,
    PurchaseCancelledHandler? onCancelled,
  }) async {
    if (!isSupported) return false;
    _onPurchase = onPurchase;
    _onError = onError;
    _onCancelled = onCancelled;
    final available = await _iap.isAvailable();
    if (!available) return false;
    await _subscription?.cancel();
    _subscription = _iap.purchaseStream.listen(
      _onPurchaseUpdate,
      onDone: () => _subscription?.cancel(),
      onError: (Object e) => debugPrint('IAP stream error: $e'),
    );
    await drainPendingTransactions();
    return true;
  }

  Future<void> dispose() async {
    await _subscription?.cancel();
    _subscription = null;
    _onPurchase = null;
    _onError = null;
    _onCancelled = null;
    _productQueryInFlight = null;
    _cachedProducts = const [];
    _productsCachedAt = null;
    _lastQueryError = null;
    invalidateReceiptCache();
  }

  void invalidateReceiptCache() {
    _cachedIosReceipt = null;
    _cachedIosReceiptAt = null;
  }

  bool _receiptCacheIsFresh() {
    final cachedAt = _cachedIosReceiptAt;
    final receipt = _cachedIosReceipt;
    if (cachedAt == null || receipt == null || receipt.isEmpty) return false;
    return DateTime.now().difference(cachedAt) < _receiptCacheTtl;
  }

  bool _cacheIsFresh() {
    final cachedAt = _productsCachedAt;
    if (cachedAt == null || _cachedProducts.isEmpty) return false;
    return DateTime.now().difference(cachedAt) < _productCacheTtl;
  }

  Future<List<ProductDetails>> queryProducts({bool forceRefresh = false}) async {
    if (!isSupported) return [];

    if (!forceRefresh && _cacheIsFresh()) {
      return _cachedProducts;
    }

    final inFlight = _productQueryInFlight;
    if (inFlight != null) {
      return inFlight;
    }

    final query = _queryProductsOnce();
    _productQueryInFlight = query;
    try {
      return await query;
    } finally {
      if (identical(_productQueryInFlight, query)) {
        _productQueryInFlight = null;
      }
    }
  }

  Future<List<ProductDetails>> _queryProductsOnce() async {
    if (Platform.isIOS) {
      await Future<void>.delayed(const Duration(milliseconds: 500));
    }

    final response =
        await _iap.queryProductDetails(IapProducts.allProductIds.toSet());
    _lastQueryError = response.error;

    if (response.error != null) {
      debugPrint('IAP query error: ${response.error}');
    }
    if (response.notFoundIDs.isNotEmpty && response.productDetails.isEmpty) {
      debugPrint('IAP products not found: ${response.notFoundIDs}');
      if (Platform.isIOS && response.error?.code == 'storekit_no_response') {
        debugPrint(
          'IAP hint (iOS): StoreKit returned no products. On Simulator, run '
          'from Xcode (Product → Run) so Products.storekit loads — flutter run '
          'does not apply the scheme StoreKit config. On device, create '
          'subscriptions in App Store Connect and use a Sandbox Apple ID.',
        );
      }
    }

    final products = response.productDetails.toList()
      ..sort((a, b) => a.id.compareTo(b.id));

    if (products.isNotEmpty) {
      _cachedProducts = products;
      _productsCachedAt = DateTime.now();
      _lastQueryError = null;
    }

    return products;
  }

  ProductDetails? productForPlanIndex(
      int planIndex, List<ProductDetails> products) {
    final id = IapProducts.productIdForPlanIndex(planIndex);
    if (id == null) return null;
    for (final p in products) {
      if (p.id == id) return p;
    }
    return null;
  }

  Future<bool> buy(ProductDetails product) async {
    invalidateReceiptCache();
    final param = PurchaseParam(productDetails: product);
    return _iap.buyNonConsumable(purchaseParam: param);
  }

  Future<void> restorePurchases() async {
    await _iap.restorePurchases();
  }

  /// Clears unfinished StoreKit / Play transactions so a new purchase can start.
  Future<void> drainPendingTransactions({bool includeRestore = false}) async {
    if (!isSupported) return;
    try {
      if (includeRestore) {
        await restorePurchases();
        await Future<void>.delayed(const Duration(milliseconds: 700));
      }
      if (Platform.isIOS) {
        await _finishStuckIosTransactions();
      }
    } catch (e) {
      debugPrint('IAP drain pending transactions: $e');
    }
  }

  Future<void> _finishStuckIosTransactions() async {
    final queue = SKPaymentQueueWrapper();
    final transactions = await queue.transactions();
    for (final tx in transactions) {
      final state = tx.transactionState;
      if (state == SKPaymentTransactionStateWrapper.purchasing ||
          state == SKPaymentTransactionStateWrapper.deferred) {
        continue;
      }
      try {
        await queue.finishTransaction(tx);
      } catch (e) {
        debugPrint(
          'IAP finish stuck transaction ${tx.payment.productIdentifier}: $e',
        );
      }
    }
  }

  /// Returns the base64 app receipt for Apple's verifyReceipt API, or null if
  /// unavailable. Never returns StoreKit 2 JWS transaction data.
  Future<String?> receiptDataForServerVerification(
    PurchaseDetails purchase, {
    bool forceRefresh = false,
  }) async {
    if (!Platform.isIOS) {
      final token = purchase.verificationData.serverVerificationData;
      return token.isNotEmpty ? token : null;
    }
    return _fetchIosAppReceipt(forceRefresh: forceRefresh);
  }

  Future<String?> _fetchIosAppReceipt({bool forceRefresh = false}) async {
    if (!forceRefresh && _receiptCacheIsFresh()) {
      return _cachedIosReceipt;
    }

    final inFlight = _iosReceiptFetchInFlight;
    if (inFlight != null) {
      return inFlight;
    }

    final fetch = _fetchIosAppReceiptOnce(forceRefresh: forceRefresh);
    _iosReceiptFetchInFlight = fetch;
    try {
      final receipt = await fetch;
      if (receipt != null && receipt.isNotEmpty && !looksLikeJws(receipt)) {
        _cachedIosReceipt = receipt;
        _cachedIosReceiptAt = DateTime.now();
      }
      return receipt;
    } finally {
      if (identical(_iosReceiptFetchInFlight, fetch)) {
        _iosReceiptFetchInFlight = null;
      }
    }
  }

  Future<String?> _fetchIosAppReceiptOnce({required bool forceRefresh}) async {
    if (!forceRefresh) {
      final local = await _readIosReceiptWithoutRefresh();
      if (local != null) {
        if (kDebugMode) {
          debugPrint(
            '[IapService] App receipt read from disk (len=${local.length})',
          );
        }
        return local;
      }
    }

    final addition = InAppPurchasePlatformAddition.instance;
    if (addition is! InAppPurchaseStoreKitPlatformAddition) {
      if (kDebugMode) {
        debugPrint('[IapService] StoreKit platform addition unavailable');
      }
      return null;
    }

    for (var attempt = 0; attempt < _receiptRetryDelays.length; attempt++) {
      if (attempt > 0) {
        await Future<void>.delayed(_receiptRetryDelays[attempt]);
      }
      try {
        final refreshed = await addition.refreshPurchaseVerificationData();
        final receipt = refreshed?.serverVerificationData;
        if (receipt == null || receipt.isEmpty) {
          continue;
        }
        if (looksLikeJws(receipt)) {
          continue;
        }
        if (kDebugMode) {
          debugPrint(
            '[IapService] App receipt refreshed (attempt ${attempt + 1}, len=${receipt.length})',
          );
        }
        return receipt;
      } catch (e) {
        if (kDebugMode) {
          debugPrint(
            '[IapService] App receipt refresh failed (attempt ${attempt + 1}): $e',
          );
        }
      }
    }
    if (kDebugMode) {
      debugPrint('[IapService] Could not obtain app receipt after retries');
    }
    return null;
  }

  Future<String?> _readIosReceiptWithoutRefresh() async {
    try {
      final receipt = await SKReceiptManager.retrieveReceiptData();
      if (receipt.isEmpty || looksLikeJws(receipt)) {
        return null;
      }
      return receipt;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[IapService] Local receipt read failed: $e');
      }
      return null;
    }
  }

  bool _isUserCancelled(PurchaseDetails purchase) {
    final code = purchase.error?.code ?? '';
    return code == 'purchase_cancelled' ||
        code == 'storekit2_purchase_cancelled' ||
        code == 'BillingResponse.userCanceled' ||
        code.toLowerCase().contains('cancel');
  }

  Future<void> _onPurchaseUpdate(List<PurchaseDetails> purchases) async {
    for (final purchase in purchases) {
      if (purchase.status == PurchaseStatus.pending) continue;
      if (purchase.status == PurchaseStatus.error) {
        if (_isUserCancelled(purchase)) {
          _onCancelled?.call();
        } else {
          _onError?.call(purchase);
        }
        await _safeCompletePurchase(purchase);
        continue;
      }
      if (purchase.status == PurchaseStatus.purchased ||
          purchase.status == PurchaseStatus.restored) {
        try {
          await _onPurchase?.call(purchase);
        } finally {
          await _safeCompletePurchase(purchase);
        }
      } else if (purchase.pendingCompletePurchase) {
        await _safeCompletePurchase(purchase);
      }
    }
  }

  Future<void> _safeCompletePurchase(PurchaseDetails purchase) async {
    if (!purchase.pendingCompletePurchase || purchase.productID.isEmpty) {
      return;
    }
    try {
      await _iap.completePurchase(purchase);
    } catch (e) {
      debugPrint('Error completing purchase: $e');
    }
  }
}
