import 'package:flutter/foundation.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

// Product IDs must match exactly what is configured in
// Google Play Console and RevenueCat dashboard.
const String _kMonthlyProductId = 'mindaware_premium_monthly';
const String _kAnnualProductId  = 'mindaware_premium_annual';
const String _kEntitlementId    = 'premium';

class SubscriptionService {
  static final SubscriptionService _instance = SubscriptionService._internal();
  factory SubscriptionService() => _instance;
  SubscriptionService._internal();

  bool _isInitialized = false;

  // Call once at app startup, after Supabase.initialize().
  // userId should be the Supabase anonymous or authenticated user ID
  // so RevenueCat can link purchases to the correct user in its dashboard.
  Future<void> init(String userId) async {
    if (_isInitialized) return;

    await Purchases.setLogLevel(
      kDebugMode ? LogLevel.debug : LogLevel.error,
    );

    final configuration = PurchasesConfiguration(
      const String.fromEnvironment('REVENUECAT_API_KEY'),
    )..appUserID = userId;

    await Purchases.configure(configuration);
    _isInitialized = true;
  }

  // Single source of truth for whether the user has an active
  // paid subscription. Does NOT include the trial — trial is
  // managed separately via EconomyService.premiumTrialEnd.
  Future<bool> isPremiumActive() async {
    final customerInfo = await Purchases.getCustomerInfo();
    return customerInfo.entitlements.active.containsKey(_kEntitlementId);
  }

  // Returns the active product ID string, or empty string if none.
  Future<String> activeProductId() async {
    final customerInfo = await Purchases.getCustomerInfo();
    final entitlement = customerInfo.entitlements.active[_kEntitlementId];
    return entitlement?.productIdentifier ?? '';
  }

  Future<bool> purchaseMonthly() async {
    return _purchase(_kMonthlyProductId);
  }

  Future<bool> purchaseAnnual() async {
    return _purchase(_kAnnualProductId);
  }

  Future<bool> _purchase(String productId) async {
    final offerings = await Purchases.getOfferings();
    final package = offerings.current?.availablePackages.firstWhere(
      (p) => p.storeProduct.identifier == productId,
      orElse: () => offerings.current!.availablePackages.first,
    );

    if (package == null) {
      debugPrint('SubscriptionService: package not found for $productId');
      return false;
    }

    final result = await Purchases.purchasePackage(package);
    final isActive =
        result.customerInfo.entitlements.active.containsKey(_kEntitlementId);
    debugPrint(
      'SubscriptionService: purchase result for $productId — active: $isActive',
    );
    return isActive;
  }

  // Called from the PaywallScreen "Restore Purchases" button.
  // Returns true if a valid entitlement was restored.
  Future<bool> restorePurchases() async {
    final customerInfo = await Purchases.restorePurchases();
    final isActive =
        customerInfo.entitlements.active.containsKey(_kEntitlementId);
    debugPrint('SubscriptionService: restore — active: $isActive');
    return isActive;
  }
}
