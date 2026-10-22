import 'package:flutter/foundation.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'platform_support.dart';

class RevenueCatService extends ChangeNotifier {
  RevenueCatService._();
  static final RevenueCatService instance = RevenueCatService._();

  static const String entitlementId = 'pro_access';
  static const String packageLifetime = '\$rc_lifetime';
  static const String packageAnnual = '\$rc_annual';
  static const String packageMonthly = '\$rc_monthly';

  // Override at build time: --dart-define=RC_GOOGLE_KEY=... --dart-define=RC_APPLE_KEY=...
  static const String googleApiKey =
      String.fromEnvironment('RC_GOOGLE_KEY', defaultValue: 'goog_sample_playstore_api_key');
  static const String appleApiKey =
      String.fromEnvironment('RC_APPLE_KEY', defaultValue: 'appl_sample_appstore_api_key');

  bool _isProUser = false;
  bool get isProUser => _isProUser;

  List<Package> _availablePackages = [];
  List<Package> get availablePackages => _availablePackages;

  Future<void> initialize() async {
    if (!PlatformSupport.supportsBilling) return;
    try {
      await Purchases.setLogLevel(kDebugMode ? LogLevel.debug : LogLevel.warn);

      PurchasesConfiguration configuration;
      if (PlatformSupport.isAndroid) {
        configuration = PurchasesConfiguration(googleApiKey);
      } else {
        configuration = PurchasesConfiguration(appleApiKey);
      }

      await Purchases.configure(configuration);

      final customerInfo = await Purchases.getCustomerInfo();
      _updateEntitlementStatus(customerInfo);

      Purchases.addCustomerInfoUpdateListener((customerInfo) {
        _updateEntitlementStatus(customerInfo);
      });

      await fetchOfferings();
    } catch (e) {
      debugPrint('RevenueCat configuration note: $e');
    }
  }

  void _updateEntitlementStatus(CustomerInfo customerInfo) {
    final bool hasPro = customerInfo.entitlements.all[entitlementId]?.isActive ?? false;
    if (_isProUser != hasPro) {
      _isProUser = hasPro;
      notifyListeners();
    }
  }

  Future<void> fetchOfferings() async {
    try {
      final offerings = await Purchases.getOfferings();
      if (offerings.current != null) {
        _availablePackages = offerings.current!.availablePackages;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error fetching offerings: $e');
    }
  }

  Future<bool> purchasePackage(Package package) async {
    try {
      final result = await Purchases.purchase(PurchaseParams.package(package));
      _updateEntitlementStatus(result.customerInfo);
      return _isProUser;
    } catch (e) {
      debugPrint('Purchase error: $e');
      return false;
    }
  }

  Future<bool> restorePurchases() async {
    try {
      final customerInfo = await Purchases.restorePurchases();
      _updateEntitlementStatus(customerInfo);
      return _isProUser;
    } catch (e) {
      debugPrint('Restore error: $e');
      return false;
    }
  }

  void setDebugProStatus(bool pro) {
    _isProUser = pro;
    notifyListeners();
  }
}
