# RainCheck

RainCheck is a Flutter app that answers one car-wash question: is it worth washing now, or is rain likely to ruin it soon?

The app combines a location, a forecast horizon, and a user rain-tolerance setting to produce a clear wash-or-wait recommendation.

## Release Checks

Run these before preparing a store build:

```sh
flutter analyze
flutter test
flutter build appbundle --release
flutter build ipa --release
flutter build web --release
```

## Android Signing

Create an upload keystore outside source control, then copy `android/key.properties.example` to `android/key.properties` and fill in your local values.

`android/key.properties` and `android/app/upload-keystore.jks` are ignored by git.

## Store Metadata

Suggested short description:

> Know whether it is worth washing your car before rain moves in.

Suggested full description:

> RainCheck turns local rain forecasts into a simple car-wash recommendation. Choose your forecast horizon and rain tolerance, then see whether conditions look dry enough to wash or whether you should wait.

Privacy notes for store listings:

- Location is used to fetch a local forecast.
- Manual city search is available if users do not want to use device location.
- Forecast and geocoding requests are sent to external weather/location services.
- No account is required.
