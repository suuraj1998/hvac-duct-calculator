import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:purchases_ui_flutter/purchases_ui_flutter.dart';
import 'platform_support.dart';

class RevenueCatService extends ChangeNotifier {
  RevenueCatService._();
  static final RevenueCatService instance = RevenueCatService._();

  /// Entitlement ID configured in RevenueCat dashboard
  static const String entitlementId = 'hvac_pro';

  /// Product identifiers
  static const String productLifetime = 'lifetime';
  static const String productYearly = 'yearly';
  static const String productMonthly = 'monthly';

  /// RevenueCat API key provided
  static const String apiKey = String.fromEnvironment(
    'RC_API_KEY',
    defaultValue: 'test_zKDjuSuobrDGJWqCFJdmYumbRAs',
  );

  bool _isProUser = false;
  bool get isProUser => _isProUser;

  CustomerInfo? _customerInfo;
  CustomerInfo? get customerInfo => _customerInfo;

  List<Package> _availablePackages = [];
  List<Package> get availablePackages => _availablePackages;

  Offerings? _offerings;
  Offerings? get offerings => _offerings;

  /// Initialize RevenueCat SDK with robust error handling
  Future<void> initialize() async {
    if (!PlatformSupport.supportsBilling) {
      debugPrint('RevenueCat: Billing not supported on current platform.');
      return;
    }

    try {
      await Purchases.setLogLevel(kDebugMode ? LogLevel.debug : LogLevel.warn);

      final configuration = PurchasesConfiguration(apiKey);
      await Purchases.configure(configuration);

      // Fetch initial customer info
      _customerInfo = await Purchases.getCustomerInfo();
      _updateEntitlementStatus(_customerInfo!);

      // Listen for real-time customer info updates (e.g. renewals, cancellations)
      Purchases.addCustomerInfoUpdateListener((customerInfo) {
        _customerInfo = customerInfo;
        _updateEntitlementStatus(customerInfo);
      });

      await fetchOfferings();
    } on PlatformException catch (e) {
      debugPrint('RevenueCat initialization error (${e.code}): ${e.message}');
    } catch (e) {
      debugPrint('RevenueCat unexpected initialization error: $e');
    }
  }

  /// Evaluates active status of `hvac_pro` entitlement
  void _updateEntitlementStatus(CustomerInfo customerInfo) {
    final bool hasPro = customerInfo.entitlements.all[entitlementId]?.isActive ?? false;
    if (_isProUser != hasPro) {
      _isProUser = hasPro;
      notifyListeners();
    }
  }

  /// Fetches available offerings and packages (lifetime, yearly, monthly)
  Future<void> fetchOfferings() async {
    if (!PlatformSupport.supportsBilling) return;
    try {
      _offerings = await Purchases.getOfferings();
      if (_offerings?.current != null) {
        _availablePackages = _offerings!.current!.availablePackages;
        notifyListeners();
      }
    } on PlatformException catch (e) {
      debugPrint('Error fetching RevenueCat offerings (${e.code}): ${e.message}');
    } catch (e) {
      debugPrint('Unexpected error fetching offerings: $e');
    }
  }

  /// Purchases a specific RevenueCat package using PurchaseParams
  Future<bool> purchasePackage(Package package) async {
    if (!PlatformSupport.supportsBilling) return false;
    try {
      final purchaseResult = await Purchases.purchase(PurchaseParams.package(package));
      _customerInfo = purchaseResult.customerInfo;
      _updateEntitlementStatus(purchaseResult.customerInfo);
      return _isProUser;
    } on PlatformException catch (e) {
      final errorCode = PurchasesErrorHelper.getErrorCode(e);
      if (errorCode != PurchasesErrorCode.purchaseCancelledError) {
        debugPrint('Purchase error (${e.code}): ${e.message}');
      } else {
        debugPrint('User cancelled purchase.');
      }
      return false;
    } catch (e) {
      debugPrint('Unexpected purchase error: $e');
      return false;
    }
  }

  /// Restores previous purchases
  Future<bool> restorePurchases() async {
    if (!PlatformSupport.supportsBilling) return false;
    try {
      final customerInfo = await Purchases.restorePurchases();
      _customerInfo = customerInfo;
      _updateEntitlementStatus(customerInfo);
      return _isProUser;
    } on PlatformException catch (e) {
      debugPrint('Restore purchases error (${e.code}): ${e.message}');
      return false;
    } catch (e) {
      debugPrint('Unexpected restore error: $e');
      return false;
    }
  }

  /// Presents the official RevenueCat Paywall UI
  Future<PaywallResult> presentPaywall() async {
    if (!PlatformSupport.supportsBilling) {
      setDebugProStatus(true);
      return PaywallResult.purchased;
    }
    try {
      final paywallResult = await RevenueCatUI.presentPaywall(
        displayCloseButton: true,
      );
      if (paywallResult == PaywallResult.purchased ||
          paywallResult == PaywallResult.restored) {
        final info = await Purchases.getCustomerInfo();
        _customerInfo = info;
        _updateEntitlementStatus(info);
      }
      return paywallResult;
    } on PlatformException catch (e) {
      debugPrint('RevenueCat Paywall error (${e.code}): ${e.message}');
      return PaywallResult.error;
    } catch (e) {
      debugPrint('Unexpected Paywall error: $e');
      return PaywallResult.error;
    }
  }

  /// Presents the official RevenueCat Paywall if `hvac_pro` entitlement is not active
  Future<PaywallResult> presentPaywallIfNeeded() async {
    if (!PlatformSupport.supportsBilling) {
      setDebugProStatus(true);
      return PaywallResult.purchased;
    }
    try {
      return await RevenueCatUI.presentPaywallIfNeeded(
        entitlementId,
        displayCloseButton: true,
      );
    } catch (e) {
      debugPrint('Error presenting Paywall if needed: $e');
      return PaywallResult.error;
    }
  }

  /// Presents the RevenueCat Customer Center for subscription management
  Future<void> presentCustomerCenter() async {
    if (!PlatformSupport.supportsBilling) return;
    try {
      await RevenueCatUI.presentCustomerCenter();
    } catch (e) {
      debugPrint('Error presenting Customer Center: $e');
    }
  }

  /// Debug helper for non-billing platforms (Web/Desktop)
  void setDebugProStatus(bool pro) {
    _isProUser = pro;
    notifyListeners();
  }
}
