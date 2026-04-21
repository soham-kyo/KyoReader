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

  // Initialize IAP and load product details
  static Future<void> init() async {
    try {
      _available = await _iap.isAvailable();
      if (!_available) {
        debugPrint("IAP not available on this device");
        return;
      }

      // Listen to purchase updates
      _subscription = _iap.purchaseStream.listen(
        (purchases) => _onPurchaseUpdate(purchases),
        onError: (Object error) {
          debugPrint("Purchase stream error: $error");
        },
        cancelOnError: true,
      );

      // Load product details
      final response = await _iap.queryProductDetails({kProProductId});
      if (response.notFoundIDs.isNotEmpty) {
        debugPrint("Product not found: ${response.notFoundIDs}");
        return;
      }

      if (response.productDetails.isNotEmpty) {
        _product = response.productDetails.first;
        debugPrint("Product loaded: ${_product?.title}");
      }
    } catch (e) {
      debugPrint("Error initializing IAP: $e");
      _available = false;
    }
  }

  // Handle purchase stream updates
  static void _onPurchaseUpdate(List<PurchaseDetails> purchases) {
    for (final purchase in purchases) {
      _handlePurchase(purchase).onError((error, stackTrace) {
        debugPrint('Error handling purchase: $error');
      });
    }
  }

  /// Handle purchase result
  static Future<void> _handlePurchase(PurchaseDetails purchase) async {
    if (purchase.status == PurchaseStatus.pending) {
      debugPrint('Purchase pending...');
      return;
    }

    if (purchase.status == PurchaseStatus.purchased ||
        purchase.status == PurchaseStatus.restored) {
      try {
        // Save pro unlock locally with token for receipt verification
        await StorageService.setProUnlocked(
          value: true,
          token: purchase.purchaseID,
        );

        _purchaseController.add(
          PurchaseResult(
            success: true,
            restored: purchase.status == PurchaseStatus.restored,
          ),
        );

        debugPrint(
          "Purchase successful: ${purchase.status}, Token: ${purchase.purchaseID}",
        );
      } catch (e) {
        debugPrint("Error saving purchase locally: $e");
        _purchaseController.add(
          PurchaseResult(success: false, error: "Failed to save purchase: $e"),
        );
      }
    } else if (purchase.status == PurchaseStatus.error) {
      debugPrint("Purchase error: ${purchase.error?.message}");
      _purchaseController.add(
        PurchaseResult(
          success: false,
          error: purchase.error?.message ?? "Purchase failed",
        ),
      );
    } else if (purchase.status == PurchaseStatus.canceled) {
      debugPrint("Purchase canceled by user");
      _purchaseController.add(
        const PurchaseResult(
          success: false,
          error: "Purchase cancelled",
        ),
      );
    }

    // Complete purchase to acknowledge
    if (purchase.pendingCompletePurchase) {
      try {
        await _iap.completePurchase(purchase);
        debugPrint("Purchase completed on store");
      } catch (e) {
        debugPrint("Error completing purchase: $e");
      }
    }
  }

  // Start purchase flow for pro unlock
  static Future<PurchaseResult> purchasePro() async {
    if (!_available) {
      return const PurchaseResult(
        success: false,
        error: "Billing not available on this device",
      );
    }

    if (_product == null) {
      return const PurchaseResult(
        success: false,
        error: "Product not loaded. Please try again.",
      );
    }

    try {
      final PurchaseParam param;
      if (Platform.isAndroid) {
        param = GooglePlayPurchaseParam(productDetails: _product!);
      } else {
        param = PurchaseParam(productDetails: _product!);
      }

      debugPrint("Starting purchase for: ${_product?.id}");
      await _iap.buyNonConsumable(purchaseParam: param);

      // Wait for purchase result from stream with timeout
      final result = await purchaseStream.first.timeout(
        const Duration(seconds: 120),
        onTimeout: () => const PurchaseResult(
          success: false,
          error: "Purchase request timed out",
        ),
      );
      return result;
    } catch (e) {
      debugPrint("Purchase error: $e");
      return PurchaseResult(
        success: false,
        error: "Purchase failed: ${e.toString()}",
      );
    }
  }

  // Restore previous purchases
  static Future<PurchaseResult> restorePurchase() async {
    if (!_available) {
      return const PurchaseResult(
        success: false,
        error: "Billing not available on this device",
      );
    }

    try {
      // Check local token first (optimization to avoid API call)
      final token = StorageService.getPurchaseToken();
      if (token != null && token.isNotEmpty) {
        debugPrint("Restoring from local token: $token");
        await StorageService.setProUnlocked(value: true, token: token);
        return const PurchaseResult(success: true, restored: true);
      }

      // If no local token, restore from store
      debugPrint("Restoring purchases from store...");
      await _iap.restorePurchases();

      // Wait for restore result with timeout
      final result = await purchaseStream.first.timeout(
        const Duration(seconds: 60),
        onTimeout: () => const PurchaseResult(
          success: false,
          error: "Restore request timed out",
        ),
      );
      return result;
    } catch (e) {
      debugPrint("Restore purchases error: $e");
      return PurchaseResult(
        success: false,
        error: e.toString().contains("timeout")
            ? "Restore request timed out"
            : "No previous purchase found",
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
