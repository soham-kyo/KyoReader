import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:in_app_purchase_android/in_app_purchase_android.dart';
import 'storage_service.dart';

const String kProProductId = 'pro_unlock';
const String kProPrice = '₹11';

class PurchaseResult {
  final bool success;
  final String? error;
  final bool restored;

  const PurchaseResult({
    required this.success,
    this.error,
    this.restored = false,
  });
}

class PurchaseService {
  static final InAppPurchase _iap = InAppPurchase.instance;
  static StreamSubscription<List<PurchaseDetails>>? _subscription;
  static bool _available = false;
  static ProductDetails? _product;
  static final _purchaseController =
      StreamController<PurchaseResult>.broadcast();

  static Stream<PurchaseResult> get purchaseStream =>
      _purchaseController.stream;

  static Future<void> init() async {
    _available = await _iap.isAvailable();
    if (!_available) return;

    // Listen to purchase updates
    _subscription = _iap.purchaseStream.listen(
      _onPurchaseUpdate,
      onError: (Object e) {
        debugPrint('IAP stream error: $e');
      },
    );

    // Load product
    final response = await _iap.queryProductDetails({kProProductId});
    if (response.productDetails.isNotEmpty) {
      _product = response.productDetails.first;
    }
  }

  static void _onPurchaseUpdate(List<PurchaseDetails> purchases) {
    for (final purchase in purchases) {
      _handlePurchase(purchase);
    }
  }

  static Future<void> _handlePurchase(PurchaseDetails purchase) async {
    if (purchase.status == PurchaseStatus.purchased ||
        purchase.status == PurchaseStatus.restored) {
      final token =
          purchase.purchaseID ??
          DateTime.now().millisecondsSinceEpoch.toRadixString(16);
      await StorageService.setProUnlocked(value: true, token: token);
      _purchaseController.add(
        PurchaseResult(
          success: true,
          restored: purchase.status == PurchaseStatus.restored,
        ),
      );
    } else if (purchase.status == PurchaseStatus.error) {
      _purchaseController.add(
        PurchaseResult(
          success: false,
          error: purchase.error?.message ?? 'Purchase failed',
        ),
      );
    } else if (purchase.status == PurchaseStatus.canceled) {
      _purchaseController.add(
        const PurchaseResult(success: false, error: 'Purchase cancelled'),
      );
    }

    if (purchase.pendingCompletePurchase) {
      await _iap.completePurchase(purchase);
    }
  }

  static Future<PurchaseResult> purchasePro() async {
    if (!_available) {
      return const PurchaseResult(
        success: false,
        error: 'Billing not available on this device',
      );
    }

    if (_product == null) {
      return const PurchaseResult(
        success: false,
        error: 'Product not found. Please check your connection.',
      );
    }

    PurchaseParam param;
    if (Platform.isAndroid) {
      param = GooglePlayPurchaseParam(productDetails: _product!);
    } else {
      param = PurchaseParam(productDetails: _product!);
    }

    try {
      await _iap.buyNonConsumable(purchaseParam: param);
      final result = await purchaseStream.first.timeout(
        const Duration(seconds: 60),
      );
      return result;
    } catch (e) {
      return PurchaseResult(success: false, error: e.toString());
    }
  }

  static Future<PurchaseResult> restorePurchase() async {
    if (!_available) {
      return const PurchaseResult(
        success: false,
        error: 'Billing not available on this device',
      );
    }

    // Check local token first
    final token = StorageService.getPurchaseToken();
    if (token != null) {
      await StorageService.setProUnlocked(value: true);
      return const PurchaseResult(success: true, restored: true);
    }

    try {
      await _iap.restorePurchases();
      final result = await purchaseStream.first.timeout(
        const Duration(seconds: 30),
      );
      return result;
    } catch (e) {
      return const PurchaseResult(
        success: false,
        error: 'No previous purchase found',
      );
    }
  }

  static String get displayPrice {
    return _product?.price ?? kProPrice;
  }

  static bool get isAvailable => _available;

  static void dispose() {
    _subscription?.cancel();
    _purchaseController.close();
  }
}
