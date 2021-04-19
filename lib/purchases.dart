library purchases;

import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:purchases_flutter/purchases_flutter.dart' as rc;

import 'models/purchaser_info.dart';
export 'package:purchases_flutter/purchases_flutter.dart' hide Purchases;

class Purchases {
  static String? _apiKey;
  static String get apiKey => _apiKey!;
  static set apiKey(String value) {
    if (_apiKey == value) return;
    _apiKey = value;
    _setupFuture = rc.Purchases.setup(apiKey);
  }

  static late Future? _setupFuture;

  static const List<TargetPlatform> sdkSupportedPlatforms = [
    TargetPlatform.android,
    TargetPlatform.iOS,
    TargetPlatform.macOS
  ];

  static final bool supportsSDK =
      sdkSupportedPlatforms.contains(defaultTargetPlatform);

  static String? _userId;
  static String? get userId => _userId!;
  static set userId(String? value) {
    if (_userId == value) return;
    _userId = value;
    _updateUserId();
  }

  static late ValueNotifier<rc.PurchaserInfo> _purchaserInfo =
      _initPurchasesInfo();

  static ValueNotifier<rc.PurchaserInfo> _initPurchasesInfo() {
    _setupPurchasesInfo();
    return ValueNotifier<rc.PurchaserInfo>(PurchaserInfo.empty());
  }

  static void _setupPurchasesInfo() async {
    assert(_apiKey != null);
    if (supportsSDK) {
      await _setupFuture;
      rc.Purchases.addPurchaserInfoUpdateListener((purchaserInfo) {
        _purchaserInfo.value = purchaserInfo;
      });
    } else {
      await _getPurchaseInfo();
    }
  }

  static void _updateUserId() {
    if (supportsSDK) {
      if (userId == null) {
        rc.Purchases.reset();
      } else {
        rc.Purchases.identify(userId!);
      }
    } else {
      _getPurchaseInfo();
    }
    _purchaserInfo.value = PurchaserInfo.empty();
  }

  static ValueListenable<rc.PurchaserInfo> get purchaserInfo => _purchaserInfo;

  static Future<rc.PurchaserInfo> _getPurchaseInfo() async {
    assert(_apiKey != null, 'Needs to provide a useful key');
    if (_userId == null) return PurchaserInfo.empty();
    final url = 'https://api.revenuecat.com/v1/subscribers/app_user_id';
    final response = await http.get(Uri.parse(url), headers: {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $apiKey'
    });
    if (response.statusCode != 200) {
      throw Exception('${response.statusCode}, message ${response.body}');
    }
    final json = jsonDecode(response.body)['subscriber'];
    final info = PurchaserInfo.fromJson(json);
    _purchaserInfo.value = info;
    return info;
  }

  // Default to TRUE, set this to FALSE if you are consuming and acknowledging transactions outside of the Purchases SDK.
  ///
  /// [finishTransactions] The value to be passed to finishTransactions.
  ///
  static Future<void> setFinishTransactions(bool finishTransactions) {
    return rc.Purchases.setFinishTransactions(finishTransactions);
  }

  /// Set this to true if you are passing in an appUserID but it is anonymous.
  ///
  /// This is true by default if you didn't pass an appUserID.
  /// If a user tries to purchase a product that is active on the current app
  /// store account, we will treat it as a restore and alias the new ID with the
  /// previous id.
  static Future<void> setAllowSharingStoreAccount(bool allowSharing) {
    return rc.Purchases.setAllowSharingStoreAccount(allowSharing);
  }

  /// Fetch the configured offerings for this users. Offerings allows you to
  /// configure your in-app products via RevenueCat and greatly simplifies
  /// management. See [the guide](https://docs.revenuecat.com/offerings) for
  /// more info.
  ///
  /// Offerings will be fetched and cached on instantiation so that, by the time
  /// they are needed, your prices are loaded for your purchase flow.
  ///
  /// Time is money.
  static Future<rc.Offerings> getOfferings() {
    return rc.Purchases.getOfferings();
  }

  /// Fetch the product info. Returns a list of products or throws an error if
  /// the products are not properly configured in RevenueCat or if there is
  /// another error while retrieving them.
  ///
  /// [productIdentifiers] Array of product identifiers
  ///
  /// [type] If the products are Android INAPPs, this needs to be
  /// PurchaseType.INAPP otherwise the products won't be found.
  /// PurchaseType.Subs by default. This parameter only has effect in Android.
  static Future<List<rc.Product>> getProducts(List<String> productIdentifiers,
      {rc.PurchaseType type = rc.PurchaseType.subs}) {
    return rc.Purchases.getProducts(productIdentifiers, type: type);
  }

  /// Makes a purchase. Returns a [PurchaserInfo] object. Throws a
  /// [PlatformException] if the purchase is unsuccessful.
  /// Check if `PurchasesErrorHelper.getErrorCode(e)` is
  /// `PurchasesErrorCode.purchaseCancelledError` to check if the user cancelled
  /// the purchase.
  ///
  /// [productIdentifier] The product identifier of the product you want to
  /// purchase.
  ///
  /// [upgradeInfo] Android only. Optional UpgradeInfo you wish to upgrade from
  /// containing the oldSKU and the optional prorationMode.
  ///
  /// [type] If the product is an Android INAPP, this needs to be
  /// PurchaseType.INAPP otherwise the product won't be found.
  /// PurchaseType.Subs by default. This parameter only has effect in Android.
  static Future<rc.PurchaserInfo> purchaseProduct(String productIdentifier,
      {rc.UpgradeInfo? upgradeInfo,
      rc.PurchaseType type = rc.PurchaseType.subs}) {
    return rc.Purchases.purchaseProduct(productIdentifier,
        upgradeInfo: upgradeInfo, type: type);
  }

  /// Makes a purchase. Returns a [PurchaserInfo] object. Throws a
  /// [PlatformException] if the purchase is unsuccessful.
  /// Check if `PurchasesErrorHelper.getErrorCode(e)` is
  /// `PurchasesErrorCode.purchaseCancelledError` to check if the user cancelled
  /// the purchase.
  ///
  /// [packageToPurchase] The Package you wish to purchase
  ///
  /// [upgradeInfo] Android only. Optional UpgradeInfo you wish to upgrade from
  /// containing the oldSKU and the optional prorationMode.
  static Future<rc.PurchaserInfo> purchasePackage(rc.Package packageToPurchase,
      {rc.UpgradeInfo? upgradeInfo}) async {
    return rc.Purchases.purchasePackage(packageToPurchase,
        upgradeInfo: upgradeInfo);
  }

  /// iOS only. Purchase a product applying a given discount.
  ///
  /// Returns a [PurchaserInfo] object. Throws a
  /// [PlatformException] if the purchase is unsuccessful.
  /// Check if `PurchasesErrorHelper.getErrorCode(e)` is
  /// `PurchasesErrorCode.purchaseCancelledError` to check if the user cancelled
  /// the purchase.
  ///
  /// [product] The product to purchase.
  ///
  /// [paymentDiscount] Discount to apply to the product. Retrieve this discount
  /// using [getPaymentDiscount].
  static Future<rc.PurchaserInfo> purchaseDiscountedProduct(
      rc.Product product, rc.PaymentDiscount discount) async {
    return rc.Purchases.purchaseDiscountedProduct(product, discount);
  }

  /// iOS only. Purchase a package applying a given discount.
  ///
  /// Returns a [PurchaserInfo] object. Throws a
  /// [PlatformException] if the purchase is unsuccessful.
  /// Check if `PurchasesErrorHelper.getErrorCode(e)` is
  /// `PurchasesErrorCode.purchaseCancelledError` to check if the user cancelled
  /// the purchase.
  ///
  /// [packageToPurchase] The Package you wish to purchase
  ///
  /// [paymentDiscount] Discount to apply to the product. Retrieve this discount
  /// using [getPaymentDiscount].
  static Future<rc.PurchaserInfo> purchaseDiscountedPackage(
      rc.Package packageToPurchase, rc.PaymentDiscount discount) async {
    return rc.Purchases.purchaseDiscountedPackage(packageToPurchase, discount);
  }

  /// Restores a user's previous purchases and links their appUserIDs to any
  /// user's also using those purchases.
  ///
  /// Returns a [PurchaserInfo] object, or throws a [PlatformException] if there
  /// was a problem restoring transactions.
  static Future<rc.PurchaserInfo> restoreTransactions() async {
    return rc.Purchases.restoreTransactions();
  }

  /// This function will alias two appUserIDs together.
  ///
  /// Returns a [PurchaserInfo] object, or throws a [PlatformException] if there
  /// was a problem restoring transactions.
  ///
  /// [newAppUserID] The new appUserID that should be linked to the currently
  /// identified appUserID.
  static Future<rc.PurchaserInfo> createAlias(String newAppUserID) async {
    return rc.Purchases.createAlias(newAppUserID);
  }

  /// Enables/Disables debugs logs
  static Future<void> setDebugLogsEnabled(bool enabled) {
    return rc.Purchases.setDebugLogsEnabled(enabled);
  }

  ///
  /// iOS only. Set this property to true *only* when testing the ask-to-buy / SCA purchases flow.
  /// More information: http://errors.rev.cat/ask-to-buy
  ///
  static Future<void> setSimulatesAskToBuyInSandbox(bool enabled) async {
 return rc.Purchases.setDebugLogsEnabled(enabled);
  }

  ///
  /// Set this property to your proxy URL before configuring Purchases *only* if you've received a proxy key value from your RevenueCat contact.
  ///
  static Future<void> setProxyURL(String url) async {
     return rc.Purchases.setProxyURL(url);
  }

  /// Gets current purchaser info, which will normally be cached.
  static Future<rc.PurchaserInfo> getPurchaserInfo() async {
     return rc.Purchases.getPurchaserInfo();
  }

  ///  This method will send all the purchases to the RevenueCat backend.
  ///
  ///  **WARNING**: Call this when using your own implementation of in-app
  ///  purchases.
  ///
  ///  This method should be called anytime a sync is needed, like after a
  ///  successful purchase.
  static Future<void> syncPurchases() async {
     return rc.Purchases.syncPurchases();
  }

  /// iOS only. Enable automatic collection of Apple Search Ad attribution. Disabled by
  /// default
  static Future<void> setAutomaticAppleSearchAdsAttributionCollection(
      bool enabled) async {
    return rc.Purchases.setDebugLogsEnabled(enabled);
  }

  /// If the `appUserID` has been generated by RevenueCat
  static Future<bool> get isAnonymous async {
    return rc.Purchases.isAnonymous;
  }

  /// iOS only. Computes whether or not a user is eligible for the introductory
  /// pricing period of a given product. You should use this method to determine
  /// whether or not you show the user the normal product price or the
  /// introductory price. This also applies to trials (trials are considered a
  /// type of introductory pricing).
  ///
  /// @note Subscription groups are automatically collected for determining
  /// eligibility. If RevenueCat can't definitively compute the eligibility,
  /// most likely because of missing group information, it will return
  /// `introEligibilityStatusUnknown`. The best course of action on unknown
  /// status is to display the non-intro pricing, to not create a misleading
  /// situation. To avoid this, make sure you are testing with the latest
  /// version of iOS so that the subscription group can be collected by the SDK.
  /// Android always returns introEligibilityStatusUnknown.
  ///
  /// [productIdentifiers] Array of product identifiers
  static Future<Map<String, rc.IntroEligibility>>
      checkTrialOrIntroductoryPriceEligibility(
          List<String> productIdentifiers) async {
 return rc.Purchases.checkTrialOrIntroductoryPriceEligibility(productIdentifiers);
  }

  /// Invalidates the cache for purchaser information.
  ///
  /// Most apps will not need to use this method; invalidating the cache can leave your app in an invalid state.
  /// Refer to https://docs.revenuecat.com/docs/purchaserinfo#section-get-user-information for more information on
  /// using the cache properly.
  ///
  /// This is useful for cases where purchaser information might have been updated outside of the app, like if a
  /// promotional subscription is granted through the RevenueCat dashboard.
  static Future<void> invalidatePurchaserInfoCache() async {
     return rc.Purchases.invalidatePurchaserInfoCache();
  }

  /// iOS only. Presents a code redemption sheet, useful for redeeming offer codes
  /// Refer to https://docs.revenuecat.com/docs/ios-subscription-offers#offer-codes for more information on how
  /// to configure and use offer codes
  static Future<void> presentCodeRedemptionSheet() async {
 return rc.Purchases.presentCodeRedemptionSheet();
  }

  ///================================================================================
  /// Subscriber Attributes
  ///================================================================================

  /// Subscriber attributes are useful for storing additional, structured information on a user.
  /// Since attributes are writable using a public key they should not be used for
  /// managing secure or sensitive information such as subscription status, coins, etc.
  ///
  /// Key names starting with "$" are reserved names used by RevenueCat. For a full list of key
  /// restrictions refer to our guide: https://docs.revenuecat.com/docs/subscriber-attributes
  ///
  /// [attributes] Map of attributes by key. Set the value as an empty string to delete an attribute.
  static Future<void> setAttributes(Map<String, String> attributes) async {
     return rc.Purchases.setAttributes(attributes);
  }

  /// Subscriber attribute associated with the email address for the user
  ///
  /// [email] Empty String or null will delete the subscriber attribute.
  static Future<void> setEmail(String email) async {
    return rc.Purchases.setEmail(email);
  }

  /// Subscriber attribute associated with the phone number for the user
  ///
  /// [phoneNumber] Empty String or null will delete the subscriber attribute.
  static Future<void> setPhoneNumber(String phoneNumber) async {
    return rc.Purchases.setPhoneNumber(phoneNumber);
  }

  /// Subscriber attribute associated with the display name for the user
  ///
  /// [displayName] Empty String or null will delete the subscriber attribute.
  static Future<void> setDisplayName(String displayName) async {
     return rc.Purchases.setDisplayName(displayName);
  }

  /// Subscriber attribute associated with the push token for the user
  ///
  /// [pushToken] Empty String or null will delete the subscriber attribute.
  static Future<void> setPushToken(String pushToken) async {
 return rc.Purchases.setPushToken(pushToken);
  }

  /// Subscriber attribute associated with the Adjust Id for the user
  /// Required for the RevenueCat Adjust integration
  ///
  /// [adjustID] Empty String or null will delete the subscriber attribute.
  static Future<void> setAdjustID(String adjustID) async {
 return rc.Purchases.setAdjustID(adjustID);
  }

  /// Subscriber attribute associated with the Appsflyer Id for the user
  /// Required for the RevenueCat Appsflyer integration
  ///
  /// [appsflyerID] Empty String or null will delete the subscriber attribute.
  static Future<void> setAppsflyerID(String appsflyerID) async {
    return rc.Purchases.setAppsflyerID(appsflyerID);
  }

  /// Subscriber attribute associated with the Facebook SDK Anonymous Id for the user
  /// Recommended for the RevenueCat Facebook integration
  ///
  /// [fbAnonymousID] Empty String or null will delete the subscriber attribute.
  static Future<void> setFBAnonymousID(String fbAnonymousID) async {
     return rc.Purchases.setFBAnonymousID(fbAnonymousID);
  }

  /// Subscriber attribute associated with the mParticle Id for the user
  /// Recommended for the RevenueCat mParticle integration
  ///
  /// [mparticleID] Empty String or null will delete the subscriber attribute.
  static Future<void> setMparticleID(String mparticleID) async {
   return rc.Purchases.setMparticleID(mparticleID);
  }

  /// Subscriber attribute associated with the OneSignal Player Id for the user
  /// Required for the RevenueCat OneSignal integration
  ///
  /// [onesignalID] Empty String or null will delete the subscriber attribute.
  static Future<void> setOnesignalID(String onesignalID) async {
 return rc.Purchases.setOnesignalID(onesignalID);
  }

  /// Subscriber attribute associated with the install media source for the user
  ///
  /// [mediaSource] Empty String or null will delete the subscriber attribute.
  static Future<void> setMediaSource(String mediaSource) async {
     return rc.Purchases.setMediaSource(mediaSource);
  }

  /// Subscriber attribute associated with the install campaign for the user
  ///
  /// [campaign] Empty String or null will delete the subscriber attribute.
  static Future<void> setCampaign(String campaign) async {
    return rc.Purchases.setCampaign(campaign);
  }

  /// Subscriber attribute associated with the install ad group for the user
  ///
  /// [adGroup] Empty String or null will delete the subscriber attribute.
  static Future<void> setAdGroup(String adGroup) async {
    return rc.Purchases.setAdGroup(adGroup);
  }

  ///
  /// Subscriber attribute associated with the install ad for the user
  ///
  /// [ad] Empty String or null will delete the subscriber attribute.
  static Future<void> setAd(String ad) async {
    return rc.Purchases.setAd(ad);
  }

  /// Subscriber attribute associated with the install keyword for the user
  ///
  /// [keyword] Empty String or null will delete the subscriber attribute.
  static Future<void> setKeyword(String keyword) async {
    return rc.Purchases.setKeyword(keyword);
  }

  /// Subscriber attribute associated with the install ad creative for the user
  ///
  /// [creative] Empty String or null will delete the subscriber attribute.
  static Future<void> setCreative(String creative) async {
    return rc.Purchases.setCreative(creative);
  }

  /// Automatically collect subscriber attributes associated with the device identifiers
  /// $idfa, $idfv, $ip on iOS
  /// $gpsAdId, $androidId, $ip on Android
  static Future<void> collectDeviceIdentifiers() async {
    return rc.Purchases.collectDeviceIdentifiers();
  }

  /// iOS only. Use this function to retrieve the `PurchasesPaymentDiscount`
  /// for a given `PurchasesPackage`.
  ///
  /// Returns a [PaymentDiscount] object. Pass this object
  /// to [purchaseDiscountedProduct] or [purchaseDiscountedPackage] to complete
  /// the purchase. A null PaymentDiscount means
  ///
  /// [product] The `Product` the user intends to purchase.
  ///
  /// [discount] The `Discount` to apply to the product.
  static Future<rc.PaymentDiscount> getPaymentDiscount(
      rc.Product product, rc.Discount discount) async {
     return rc.Purchases.getPaymentDiscount(product, discount);
  }
}
