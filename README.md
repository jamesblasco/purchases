# purchases

https://pub.dev/packages/purchases

An extension for the [purchases_flutter](https://pub.dev/packages/purchases_flutter), that allows to get the purchased information for every platform.

```dart

Purchases.apiKey = 'Add your api key';
Purchases.userId = 'Add the user id';

Purchases.purchasesInfo.addListener((info) {
    // For platforms that support the revenue cat native sdk(android, ios and macos),
    // this information will be updated whenever there is new changes.
    // For platform not supported by the official plugin this information will only be retrieved once, 
    // after the user id has been set
});
```

To use the native sdk endpoints you can check 
```dart 
if(Purchases.sdkSupported) {
    ///...
}
```
