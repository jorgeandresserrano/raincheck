# RainCheck Release Checklist

## Before Every Release

- Confirm `version` in `pubspec.yaml` has the intended semantic version and incremented build number.
- Run `flutter analyze`.
- Run `flutter test`.
- Run `flutter build appbundle --release`.
- Run `flutter build ios --release --no-codesign` before final Apple signing.
- Run `flutter build web --release` if distributing the web build.

## Android

- Generate an upload keystore and keep it out of git.
- Copy `android/key.properties.example` to `android/key.properties`.
- Fill in the keystore passwords, alias, and `storeFile`.
- Re-run `flutter build appbundle --release`.
- Verify the AAB is signed before upload:

```sh
jarsigner -verify -verbose -certs build/app/outputs/bundle/release/app-release.aab
```

- Upload `build/app/outputs/bundle/release/app-release.aab` to Google Play Console.

## iOS

- Set the Apple team and signing profile in Xcode.
- Confirm `com.jorgeandresserrano.raincheck` is available in Apple Developer.
- Create the App Store Connect app record.
- Build/archive from Xcode or run the Flutter iOS release build with signing configured.

## Store Listing

Suggested short description:

> Know whether it is worth washing your car before rain moves in.

Suggested full description:

> RainCheck turns local rain forecasts into a simple car-wash recommendation. Choose your forecast horizon and rain tolerance, then see whether conditions look dry enough to wash or whether you should wait.

Required store-console disclosures:

- Approximate location is used for local forecasts when permission is granted.
- Users can enter a city manually instead of granting location permission.
- Forecast and geocoding requests are sent to external services.
- No RainCheck account is required.

## Privacy Policy

Use `PRIVACY.md` as the starting point for the hosted privacy policy URL required by app stores. Replace the support contact placeholder before submitting.
