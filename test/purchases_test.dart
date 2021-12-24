import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:purchases/models/purchaser_info.dart' as ext;
import 'package:purchases/purchases.dart';

//Response received using CURL
final String mockResponse = """
      { 
        "request_date": "2021-12-24T11:37:05Z", 
        "request_date_ms": "1640345825738", 
        "subscriber": {
          "entitlements": {
            "full_access": {
              "expires_date": "2021-12-09T07:54:21Z", 
              "grace_period_expires_date": null, 
              "product_identifier": "full_access_monthly_sub", 
              "purchase_date": "2021-12-09T07:46:21Z"
            }
          }, 
          "first_seen": "2021-04-07T13:55:23Z", 
          "last_seen": "2021-12-22T14:00:38Z", 
          "management_url": null, 
          "non_subscriptions": {}, 
          "original_app_user_id": "RCAnonymousID", 
          "original_application_version": null, 
          "original_purchase_date": null, 
          "other_purchases": {}, 
          "subscriptions": {
            "full_access_monthly_sub": {
              "billing_issues_detected_at": null, 
              "expires_date": "2021-12-09T07:54:21Z", 
              "grace_period_expires_date": null, 
              "is_sandbox": true, 
              "original_purchase_date": "2021-12-09T07:17:19Z", 
              "period_type": "normal", 
              "purchase_date": "2021-12-09T07:46:21Z", 
              "store": "play_store", 
              "unsubscribe_detected_at": "2021-12-09T08:02:10Z"
            }, 
            "full_access_yearly_sub": {
              "billing_issues_detected_at": null, 
              "expires_date": "2021-09-21T11:34:11Z", 
              "grace_period_expires_date": null, 
              "is_sandbox": true, 
              "original_purchase_date": "2021-09-21T11:04:14Z", 
              "period_type": "normal", 
              "purchase_date": "2021-09-21T11:04:14Z", 
              "store": "play_store", 
              "unsubscribe_detected_at": "2021-09-21T11:37:30Z"
            }
          }
        }
      }""";
final String mockActiveResponse = """
  {
    "request_date":"2021-12-24T19:11:16Z",
    "request_date_ms":1640373076005,
    "subscriber":{
      "entitlements":{
        "full_access":{
          "expires_date":"2221-09-05T07:22:28Z",
          "grace_period_expires_date":null,
          "product_identifier":"rc_promo_full_access_lifetime",
          "purchase_date":"2021-10-23T07:22:28Z"
        }
      },
      "first_seen":"2021-04-22T15:17:12Z",
      "last_seen":"2021-12-21T13:47:44Z",
      "management_url":null,
      "non_subscriptions":{},
      "original_app_user_id":"RCAnonymousID",
      "original_application_version":null,
      "original_purchase_date":null,
      "other_purchases":{},
      "subscriptions":{
        "rc_promo_full_access_lifetime":{
          "billing_issues_detected_at":null,
          "expires_date":"2221-09-05T07:22:28Z",
          "grace_period_expires_date":null,
          "is_sandbox":false,
          "original_purchase_date":"2021-10-23T07:22:28Z",
          "period_type":"normal",
          "purchase_date":"2021-10-23T07:22:28Z",
          "store":"promotional",
          "unsubscribe_detected_at":null
        }
      }
    }
  }
""";

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('Parse subscriber info correctly', () {
    final purchaserInfo = ext.PurchaserInfo.fromJson(jsonDecode(mockResponse));
    final firstEntitlementEntry = purchaserInfo.entitlements.all.entries.first;
    final firstEntitlement = firstEntitlementEntry.value;
    expect(firstEntitlementEntry.key, "full_access");
    expect(firstEntitlement.identifier, "full_access");
    expect(firstEntitlement.productIdentifier, "full_access_monthly_sub");
    expect(firstEntitlement.expirationDate, "2021-12-09T07:54:21Z");
    expect(firstEntitlement.latestPurchaseDate, "2021-12-09T07:46:21Z");
    expect(firstEntitlement.originalPurchaseDate, "2021-12-09T07:17:19Z");
    expect(firstEntitlement.periodType, PeriodType.normal);
    expect(firstEntitlement.store, Store.playStore);
    expect(firstEntitlement.isActive, false);
    expect(firstEntitlement.willRenew, false);
    expect(firstEntitlement.isSandbox, true);
    expect(firstEntitlement.unsubscribeDetectedAt, "2021-12-09T08:02:10Z");

    expect(purchaserInfo.entitlements.active, {});
    expect(purchaserInfo.activeSubscriptions, []);
    expect(purchaserInfo.latestExpirationDate, "2021-12-09T07:54:21Z");
    expect(purchaserInfo.allExpirationDates, {
      "full_access": "2021-12-09T07:54:21Z",
    });
    expect(purchaserInfo.allPurchasedProductIdentifiers, ["full_access_monthly_sub", "full_access_yearly_sub"]);
    expect(purchaserInfo.firstSeen, "2021-04-07T13:55:23Z");
    expect(purchaserInfo.originalAppUserId, "RCAnonymousID");
    expect(purchaserInfo.requestDate, "2021-12-24T11:37:05Z");
    expect(purchaserInfo.allPurchaseDates, {
      "full_access_monthly_sub": "2021-12-09T07:46:21Z",
      "full_access_yearly_sub": "2021-09-21T11:04:14Z",
    });
    expect(purchaserInfo.originalApplicationVersion, isNull);
    expect(purchaserInfo.originalPurchaseDate, isNull);
    expect(purchaserInfo.managementURL, isNull);
    expect(purchaserInfo.nonSubscriptionTransactions, []);
  });

  test('Parse active subscription info', () {
    final purchaserInfo = ext.PurchaserInfo.fromJson(jsonDecode(mockActiveResponse));
    final firstEntitlementEntry = purchaserInfo.entitlements.all.entries.first;
    final firstEntitlement = firstEntitlementEntry.value;
    expect(firstEntitlementEntry.key, "full_access");
    expect(firstEntitlement.identifier, "full_access");
    expect(firstEntitlement.productIdentifier, "rc_promo_full_access_lifetime");
    expect(firstEntitlement.expirationDate, "2221-09-05T07:22:28Z");
    expect(firstEntitlement.latestPurchaseDate, "2021-10-23T07:22:28Z");
    expect(firstEntitlement.originalPurchaseDate, "2021-10-23T07:22:28Z");
    expect(firstEntitlement.periodType, PeriodType.normal);
    expect(firstEntitlement.store, Store.promotional);
    expect(firstEntitlement.isActive, true);
    expect(firstEntitlement.willRenew, true);
    expect(firstEntitlement.isSandbox, false);
    expect(firstEntitlement.unsubscribeDetectedAt, isNull);

    expect(purchaserInfo.entitlements.active["full_access"]!.identifier, "full_access");
    expect(purchaserInfo.activeSubscriptions, ["rc_promo_full_access_lifetime"]);
    expect(purchaserInfo.latestExpirationDate, "2221-09-05T07:22:28Z");
    expect(purchaserInfo.allExpirationDates, {
      "full_access": "2221-09-05T07:22:28Z",
    });
    expect(purchaserInfo.allPurchasedProductIdentifiers, ["rc_promo_full_access_lifetime"]);
    expect(purchaserInfo.firstSeen, "2021-04-22T15:17:12Z");
    expect(purchaserInfo.originalAppUserId, "RCAnonymousID");
    expect(purchaserInfo.requestDate, "2021-12-24T19:11:16Z");
    expect(purchaserInfo.allPurchaseDates, {
      "rc_promo_full_access_lifetime": "2021-10-23T07:22:28Z",
    });
    expect(purchaserInfo.originalApplicationVersion, isNull);
    expect(purchaserInfo.originalPurchaseDate, "2021-10-23T07:22:28Z");
    expect(purchaserInfo.managementURL, isNull);
    expect(purchaserInfo.nonSubscriptionTransactions, []);
  });
}
