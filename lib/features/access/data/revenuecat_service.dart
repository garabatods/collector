import 'dart:io';

import 'package:purchases_flutter/purchases_flutter.dart';

class RevenueCatService {
  RevenueCatService._();

  static const entitlementId = 'pro';
  static const monthlyProductId = 'com.neoncartridgelabs.ownzith.pro.monthly';
  static const annualProductId = 'com.neoncartridgelabs.ownzith.pro.annual';
  static const _iosApiKey = String.fromEnvironment('REVENUECAT_IOS_API_KEY');
  static const _androidApiKey = String.fromEnvironment(
    'REVENUECAT_ANDROID_API_KEY',
  );

  static bool get hasPlatformKey =>
      (Platform.isIOS && _iosApiKey.isNotEmpty) ||
      (Platform.isAndroid && _androidApiKey.isNotEmpty);

  static Future<bool> syncUser(String userId) async {
    if (!hasPlatformKey) return false;
    try {
      final configured = await Purchases.isConfigured;
      if (!configured) {
        final configuration = PurchasesConfiguration(
          Platform.isIOS ? _iosApiKey : _androidApiKey,
        )..appUserID = userId;
        await Purchases.configure(configuration);
      } else {
        await Purchases.logIn(userId);
      }
      return true;
    } catch (_) {
      return false;
    }
  }

  static Future<List<Package>> packages() async {
    if (!await Purchases.isConfigured) return const [];
    final offerings = await Purchases.getOfferings();
    return offerings.current?.availablePackages ?? const [];
  }

  static Future<CustomerInfo> purchase(Package package) async {
    final result = await Purchases.purchase(PurchaseParams.package(package));
    return result.customerInfo;
  }

  static Future<CustomerInfo?> restore() async {
    if (!await Purchases.isConfigured) return null;
    return Purchases.restorePurchases();
  }

  static Future<String?> managementUrl() async {
    try {
      if (!await Purchases.isConfigured) return null;
      return (await Purchases.getCustomerInfo()).managementURL;
    } catch (_) {
      return null;
    }
  }

  static Future<void> logOut() async {
    try {
      if (await Purchases.isConfigured) await Purchases.logOut();
    } catch (_) {
      // Supabase sign-out must still proceed if the billing SDK is unavailable.
    }
  }
}
