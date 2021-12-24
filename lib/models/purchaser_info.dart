import 'package:purchases_flutter/purchases_flutter.dart' as rc;
import 'package:collection/collection.dart';

/// Class containing all information regarding the purchaser
class PurchaserInfo extends rc.PurchaserInfo {
  factory PurchaserInfo.fromJson(Map<dynamic, dynamic> value) {
    final subscriber = value['subscriber'];

    Map<dynamic, dynamic> map = {};
    Iterable<MapEntry<dynamic, dynamic>> entitlements = Map.from(subscriber['entitlements']).entries;
    Iterable<MapEntry<dynamic, dynamic>> subscriptions = Map.from(subscriber['subscriptions']).entries;
    Iterable<MapEntry<dynamic, dynamic>> nonSubscriptions = Map.from(subscriber['non_subscriptions']).entries;
    List<MapEntry<dynamic, dynamic>> allProducts = subscriptions.toList() + nonSubscriptions.toList();

    //RevenueCat ask for entitlement here and expect full Entitlement Info object
    //See: entitlement_info_wrapper.dart
    //But REST Api gives limited number of fields.
    //See: https://docs.revenuecat.com/reference/subscribers#the-entitlement-object
    //Seems like mapping entitlement to subscription object is impossible due to lack of identifier in subscription.
    //Trying to combile entitlement info with subscription info for this entitlement
    final fullEntitlements = {};
    entitlements.forEach((entitlement) {
      final entitlementId = entitlement.key;
      final entitlementValue = entitlement.value;
      final Map<String, dynamic> fullEntitlementMap = {};

      final subscriptionId = entitlementValue['product_identifier'];
      final subscriptionEntry = subscriptions.firstWhereOrNull((subscriptionEntry) => subscriptionEntry.key == subscriptionId);
      if (subscriptionEntry != null) {
        final subscription = subscriptionEntry.value;
        fullEntitlementMap['periodType'] = (subscription['period_type'] as String).toUpperCase();
        fullEntitlementMap['store'] = (subscription['store'] as String).toUpperCase();
        fullEntitlementMap['ownershipType'] = (subscription['ownership_type'] as String?)?.toUpperCase();
        fullEntitlementMap['identifier'] = entitlementId;
        fullEntitlementMap['isActive'] = DateTime.parse(subscription['expires_date']).isAfter(DateTime.now());
        fullEntitlementMap['willRenew'] = subscription['unsubscribe_detected_at'] == null && subscription['billing_issues_detected_at'] == null;
        fullEntitlementMap['latestPurchaseDate'] = subscription['purchase_date'];
        fullEntitlementMap['originalPurchaseDate'] = subscription['original_purchase_date'];
        fullEntitlementMap['expirationDate'] = subscription['expires_date'];
        fullEntitlementMap['productIdentifier'] = subscriptionEntry.key;
        fullEntitlementMap['isSandbox'] = subscription['is_sandbox'];
        fullEntitlementMap['unsubscribeDetectedAt'] = subscription['unsubscribe_detected_at'];
        fullEntitlementMap['billingIssueDetectedAt'] = subscription['billing_issues_detected_at'];

        fullEntitlements[entitlementId] = fullEntitlementMap;
      }
    });
    final activeEntitlement = fullEntitlements.entries.firstWhereOrNull(
      (entry) => entry.value['isActive'] == true,
    );
    map['entitlements'] = {
      'all': fullEntitlements,
      'active': activeEntitlement != null ? {activeEntitlement.key: activeEntitlement.value} : {} ,
    };

    final activeSubscriptions = subscriptions.where((item) => DateTime.parse(item.value['expires_date']).isAfter(DateTime.now()));
    final activeSubscriptionsIds = activeSubscriptions.map((item) => item.key as String).toList();

    map['activeSubscriptions'] = activeSubscriptionsIds;

    final List<MapEntry<dynamic, dynamic>> sortedEntitlements = entitlements.toList()
      ..sort((item1, item2) => DateTime.parse(item1.value['expires_date']).compareTo(DateTime.parse(item2.value['expires_date'])));
    map['latestExpirationDate'] = sortedEntitlements.isNotEmpty ? sortedEntitlements.first.value['expires_date'] : null;

    //Considering that only subscriptions have expiration dates, and since entitlements represents subscriptions, I parse them to get all expiration dates
    map['allExpirationDates'] = Map.fromIterable(sortedEntitlements, key: (entry) => entry.key, value: (entry) => entry.value['expires_date']);

    //Assume here it's not about entitlements but about all products
    map['allPurchasedProductIdentifiers'] = allProducts.map((product) => product.key).toList();

    //The same as above, use all products to identify all purchase dates
    map['allPurchaseDates'] = Map.fromIterable(allProducts, key: (entry) => entry.key, value: (entry) => entry.value['purchase_date']);

    map['nonSubscriptionTransactions'] = Map.from(subscriber['non_subscriptions']).values.toList();
    map['firstSeen'] = subscriber['first_seen'];
    map['originalAppUserId'] = subscriber['original_app_user_id'];
    map['requestDate'] = value['request_date'];
    map['originalApplicationVersion'] = subscriber['original_application_version'];

    //From documetation is not clear for which purchase date should be provided. Let's assume we need date from first active subscription
    map['originalPurchaseDate'] = activeSubscriptions.isNotEmpty ? activeSubscriptions.first.value['original_purchase_date'] : null;

    map['managementURL'] = subscriber['management_url'];
    // Since I'm in the plugin domain and have no info about the app, I can populate it

    return PurchaserInfo._(map);
  }

  PurchaserInfo._(Map<dynamic, dynamic> map) : super.fromJson(map);
}
