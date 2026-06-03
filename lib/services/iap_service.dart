import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

import '../config/iap_products.dart';

typedef PurchaseHandler = Future<void> Function(PurchaseDetails purchase);

/// Wraps [InAppPurchase] for subscription purchases on iOS and Android.
class IapService {
  IapService._();
  static final IapService instance = IapService._();

  final InAppPurchase _iap = InAppPurchase.instance;
  StreamSubscription<List<PurchaseDetails>>? _subscription;
  PurchaseHandler? _onPurchase;

  bool get isSupported => !kIsWeb && (Platform.isIOS || Platform.isAndroid);

  Future<bool> initialize(PurchaseHandler onPurchase) async {
    if (!isSupported) return false;
    _onPurchase = onPurchase;
    final available = await _iap.isAvailable();
    if (!available) return false;
    await _subscription?.cancel();
    _subscription = _iap.purchaseStream.listen(
      _onPurchaseUpdate,
      onError: (Object e) => debugPrint('IAP stream error: $e'),
    );
    return true;
  }

  Future<void> dispose() async {
    await _subscription?.cancel();
    _subscription = null;
    _onPurchase = null;
  }

  Future<List<ProductDetails>> queryProducts() async {
    if (!isSupported) return [];
    final response = await _iap.queryProductDetails(IapProducts.allProductIds.toSet());
    if (response.error != null) {
      debugPrint('IAP query error: ${response.error}');
    }
    if (response.notFoundIDs.isNotEmpty) {
      debugPrint('IAP products not found: ${response.notFoundIDs}');
    }
    final products = response.productDetails.toList()
      ..sort((a, b) => a.id.compareTo(b.id));
    return products;
  }

  ProductDetails? productForPlanIndex(int planIndex, List<ProductDetails> products) {
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

  Future<void> _onPurchaseUpdate(List<PurchaseDetails> purchases) async {
    for (final purchase in purchases) {
      if (purchase.status == PurchaseStatus.pending) continue;
      if (purchase.status == PurchaseStatus.error) {
        debugPrint('IAP purchase error: ${purchase.error}');
        if (purchase.pendingCompletePurchase) {
          await _iap.completePurchase(purchase);
        }
        continue;
      }
      if (purchase.status == PurchaseStatus.purchased ||
          purchase.status == PurchaseStatus.restored) {
        try {
          await _onPurchase?.call(purchase);
        } finally {
          if (purchase.pendingCompletePurchase) {
            await _iap.completePurchase(purchase);
          }
        }
      } else if (purchase.pendingCompletePurchase) {
        await _iap.completePurchase(purchase);
      }
    }
  }
}
