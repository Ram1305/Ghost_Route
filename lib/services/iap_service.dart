import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

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

  static const Duration _productCacheTtl = Duration(minutes: 10);

  bool get isSupported => !kIsWeb && (Platform.isIOS || Platform.isAndroid);

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
    final param = PurchaseParam(productDetails: product);
    return _iap.buyNonConsumable(purchaseParam: param);
  }

  Future<void> restorePurchases() async {
    await _iap.restorePurchases();
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
    if (purchase.pendingCompletePurchase) {
      if (purchase.productID.isEmpty || purchase.purchaseID == null) {
        debugPrint('Skipping completePurchase because productID is empty or purchaseID is null.');
        return;
      }
      try {
        await _iap.completePurchase(purchase);
      } catch (e) {
        debugPrint('Error completing purchase: $e');
      }
    }
  }
}
