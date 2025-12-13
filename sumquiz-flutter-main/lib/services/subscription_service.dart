import 'dart:async';
import 'dart:developer' as developer;
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:purchases_ui_flutter/purchases_ui_flutter.dart';

/// CRITICAL FIX C2: Server-side receipt validation using RevenueCat
/// Comprehensive integration with Paywalls and Customer Center
class SubscriptionService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Product IDs (must match Google Play Console & RevenueCat Dashboard)
  static const String monthlyId = 'sumquiz_monthly';
  static const String yearlyId = 'sumquiz_yearly';
  static const String lifetimeId = 'sumquiz_lifetime';

  // Entitlement ID
  static const String proEntitlementId = 'pro';

  // RevenueCat API Key (TEST MODE)
  // IMPORTANT: Replace with production key before release
  static const String _revenueCatApiKey = 'test_wqsPCFIaiJgfTpMxzajXKdkHIWr';

  /// Initialize RevenueCat with user ID
  /// BEST PRACTICE: Call this after user logs in, before accessing any subscription features
  Future<void> initialize(String uid) async {
    try {
      // Configure RevenueCat with modern settings
      final configuration = PurchasesConfiguration(_revenueCatApiKey)
        ..appUserID = uid
        ..observerMode = false // RevenueCat handles purchases (recommended)
        ..usesStoreKit2IfAvailable = true; // iOS 15+ optimization

      await Purchases.configure(configuration);

      // Enable debug logging in development
      await Purchases.setLogLevel(LogLevel.debug);

      // Listen to customer info updates (purchases, renewals, expirations)
      // MODERN: Use addCustomerInfoUpdateListener instead of deprecated methods
      Purchases.addCustomerInfoUpdateListener((customerInfo) {
        developer.log('Customer info updated', name: 'SubscriptionService');
        _syncToFirestore(uid, customerInfo);
      });

      // Sync immediately on init
      final customerInfo = await Purchases.getCustomerInfo();
      await _syncToFirestore(uid, customerInfo);

      developer.log(
        'RevenueCat initialized for user $uid, '
        'Active entitlements: ${customerInfo.entitlements.active.keys}',
        name: 'SubscriptionService',
      );
    } catch (e) {
      developer.log('RevenueCat init failed',
          error: e, name: 'SubscriptionService');
      rethrow;
    }
  }

  /// Sync RevenueCat customer info to Firestore
  /// This is the single source of truth for Pro status
  Future<void> _syncToFirestore(String uid, CustomerInfo info) async {
    try {
      final entitlements = info.entitlements.active;

      bool isPro = entitlements.containsKey(proEntitlementId);
      DateTime? expiry;
      String? productId;

      if (isPro) {
        final proEntitlement = entitlements[proEntitlementId]!;
        expiry = proEntitlement.expirationDate;
        productId = proEntitlement.productIdentifier;
        // null expiry = lifetime access
      }

      await _firestore.collection('users').doc(uid).set({
        'isPro': isPro,
        'subscriptionExpiry': expiry != null
            ? Timestamp.fromDate(expiry)
            : null, // null = lifetime
        'currentProduct': productId,
        'lastVerified': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      developer.log(
        'Synced subscription: isPro=$isPro, expiry=${expiry?.toIso8601String() ?? "lifetime"}, product=$productId',
        name: 'SubscriptionService',
      );
    } catch (e) {
      developer.log('Firestore sync failed',
          error: e, name: 'SubscriptionService');
    }
  }

  /// Present RevenueCat Paywall (MODERN APPROACH)
  /// This displays the native paywall UI configured in RevenueCat Dashboard
  Future<PaywallResult> presentPaywall() async {
    try {
      final result = await RevenueCatUI.presentPaywall();

      developer.log(
        'Paywall result: ${result.toString()}',
        name: 'SubscriptionService',
      );

      return result;
    } on PlatformException catch (e) {
      developer.log('Paywall error', error: e, name: 'SubscriptionService');
      rethrow;
    }
  }

  /// Present RevenueCat Paywall with specific offering
  Future<PaywallResult> presentPaywallWithOffering(String offeringId) async {
    try {
      final result = await RevenueCatUI.presentPaywallWithOffering(offeringId);

      developer.log(
        'Paywall result for offering $offeringId: ${result.toString()}',
        name: 'SubscriptionService',
      );

      return result;
    } on PlatformException catch (e) {
      developer.log('Paywall error', error: e, name: 'SubscriptionService');
      rethrow;
    }
  }

  /// Present Customer Center (MODERN FEATURE)
  /// Allows users to manage subscriptions, view billing info, cancel, etc.
  Future<void> presentCustomerCenter() async {
    try {
      await RevenueCatUI.presentCustomerCenter();

      developer.log('Customer Center presented', name: 'SubscriptionService');
    } on PlatformException catch (e) {
      developer.log('Customer Center error',
          error: e, name: 'SubscriptionService');
      rethrow;
    }
  }

  /// Purchase a subscription (MANUAL APPROACH - use paywall for better UX)
  /// RevenueCat validates receipt server-side automatically
  Future<void> purchasePlan(String planId) async {
    try {
      // Get available offerings from RevenueCat
      final offerings = await Purchases.getOfferings();

      if (offerings.current == null) {
        throw Exception('No offerings available. Check RevenueCat dashboard.');
      }

      // Find the package by product ID
      Package? package;
      for (final p in offerings.current!.availablePackages) {
        if (p.storeProduct.identifier == planId) {
          package = p;
          break;
        }
      }

      if (package == null) {
        throw Exception('Product $planId not found in offerings');
      }

      // Purchase - RevenueCat validates receipt automatically
      final customerInfo = await Purchases.purchasePackage(package);

      // Firestore updated automatically via listener
      developer.log(
        'Purchase successful: ${customerInfo.entitlements.active.keys}',
        name: 'SubscriptionService',
      );
    } on PlatformException catch (e) {
      _handlePurchaseError(e);
      rethrow;
    } catch (e) {
      developer.log('Purchase failed', error: e, name: 'SubscriptionService');
      rethrow;
    }
  }

  /// Handle purchase errors with detailed logging
  void _handlePurchaseError(PlatformException e) {
    final errorCode = PurchasesErrorHelper.getErrorCode(e);

    switch (errorCode) {
      case PurchasesErrorCode.purchaseCancelledError:
        developer.log('User cancelled purchase', name: 'SubscriptionService');
        break;
      case PurchasesErrorCode.receiptAlreadyInUseError:
        developer.log('Receipt already in use', name: 'SubscriptionService');
        break;
      case PurchasesErrorCode.invalidReceiptError:
        developer.log('SECURITY: Invalid receipt detected!',
            error: e, name: 'SubscriptionService');
        break;
      case PurchasesErrorCode.networkError:
        developer.log('Network error during purchase',
            error: e, name: 'SubscriptionService');
        break;
      case PurchasesErrorCode.paymentPendingError:
        developer.log('Payment pending approval', name: 'SubscriptionService');
        break;
      default:
        developer.log('Purchase error: ${errorCode.name}',
            error: e, name: 'SubscriptionService');
    }
  }

  /// Restore purchases
  /// BEST PRACTICE: Always provide a "Restore Purchases" button
  Future<void> restorePurchases() async {
    try {
      final customerInfo = await Purchases.restorePurchases();

      developer.log(
        'Restored: ${customerInfo.entitlements.active.keys}',
        name: 'SubscriptionService',
      );

      // Firestore updated automatically via listener
    } catch (e) {
      developer.log('Restore failed', error: e, name: 'SubscriptionService');
      rethrow;
    }
  }

  /// Check if user has Pro access (MODERN - uses entitlement)
  /// BEST PRACTICE: Always check entitlements, not product IDs
  Future<bool> hasProAccess() async {
    try {
      final customerInfo = await Purchases.getCustomerInfo();
      return customerInfo.entitlements.active.containsKey(proEntitlementId);
    } catch (e) {
      developer.log('Failed to check Pro access',
          error: e, name: 'SubscriptionService');
      return false;
    }
  }

  /// Get customer info (for displaying subscription details)
  Future<CustomerInfo?> getCustomerInfo() async {
    try {
      return await Purchases.getCustomerInfo();
    } catch (e) {
      developer.log('Failed to get customer info',
          error: e, name: 'SubscriptionService');
      return null;
    }
  }

  /// Get formatted subscription details for display
  Future<SubscriptionDetails?> getSubscriptionDetails() async {
    try {
      final customerInfo = await Purchases.getCustomerInfo();
      final proEntitlement = customerInfo.entitlements.active[proEntitlementId];

      if (proEntitlement == null) {
        return null; // Not subscribed
      }

      return SubscriptionDetails(
        productId: proEntitlement.productIdentifier,
        expiryDate: proEntitlement.expirationDate,
        isLifetime: proEntitlement.expirationDate == null,
        periodType: proEntitlement.periodType,
        willRenew: proEntitlement.willRenew,
        originalPurchaseDate: proEntitlement.originalPurchaseDate,
      );
    } catch (e) {
      developer.log('Failed to get subscription details',
          error: e, name: 'SubscriptionService');
      return null;
    }
  }

  /// Stream Pro status from Firestore (single source of truth)
  /// This matches UserModel.isPro logic
  Stream<bool> isProStream(String uid) {
    return _firestore.collection('users').doc(uid).snapshots().map((snapshot) {
      if (!snapshot.exists) return false;
      final data = snapshot.data() as Map<String, dynamic>;

      // Check for 'subscriptionExpiry' field
      if (data.containsKey('subscriptionExpiry')) {
        // Lifetime access is handled by a null expiry date
        if (data['subscriptionExpiry'] == null) return true;

        final expiryDate = (data['subscriptionExpiry'] as Timestamp).toDate();
        return expiryDate.isAfter(DateTime.now());
      }
      return false;
    }).onErrorReturn(false);
  }

  /// Get available subscription offerings
  /// MODERN: Returns the default offering configured in RevenueCat
  Future<Offering?> getCurrentOffering() async {
    try {
      final offerings = await Purchases.getOfferings();
      return offerings.current;
    } catch (e) {
      developer.log('Failed to get offerings',
          error: e, name: 'SubscriptionService');
      return null;
    }
  }

  /// Get all available offerings
  Future<Offerings?> getAllOfferings() async {
    try {
      return await Purchases.getOfferings();
    } catch (e) {
      developer.log('Failed to get offerings',
          error: e, name: 'SubscriptionService');
      return null;
    }
  }

  /// Set user attributes (for analytics and segmentation)
  /// BEST PRACTICE: Set attributes to track user behavior
  Future<void> setUserAttributes(Map<String, String> attributes) async {
    try {
      await Purchases.setAttributes(attributes);
      developer.log('User attributes set: $attributes',
          name: 'SubscriptionService');
    } catch (e) {
      developer.log('Failed to set attributes',
          error: e, name: 'SubscriptionService');
    }
  }

  /// Invalidate customer info cache (force refresh)
  Future<CustomerInfo> invalidateCustomerInfoCache() async {
    return await Purchases.invalidateCustomerInfoCache();
  }

  /// Dispose resources
  void dispose() {
    // RevenueCat handles cleanup automatically
    developer.log('SubscriptionService disposed', name: 'SubscriptionService');
  }
}

/// Data class for subscription details
class SubscriptionDetails {
  final String productId;
  final DateTime? expiryDate;
  final bool isLifetime;
  final PeriodType periodType;
  final bool willRenew;
  final DateTime? originalPurchaseDate;

  SubscriptionDetails({
    required this.productId,
    required this.expiryDate,
    required this.isLifetime,
    required this.periodType,
    required this.willRenew,
    this.originalPurchaseDate,
  });

  String get formattedExpiry {
    if (isLifetime) return 'Lifetime Access';
    if (expiryDate == null) return 'Unknown';
    return 'Expires: ${expiryDate!.toLocal().toString().split(' ')[0]}';
  }

  String get productName {
    if (productId.contains('monthly')) return 'Monthly';
    if (productId.contains('yearly')) return 'Yearly';
    if (productId.contains('lifetime')) return 'Lifetime';
    return productId;
  }

  String get renewalStatus {
    if (isLifetime) return 'Never expires';
    return willRenew ? 'Auto-renews' : 'Will not renew';
  }
}
