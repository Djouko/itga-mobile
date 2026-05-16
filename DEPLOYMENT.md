# ITGA Mobile Deployment

This repository contains the Flutter Android/iOS app.

## Required local files

These files are intentionally ignored by Git:

```text
android/app/google-services.json
ios/Runner/GoogleService-Info.plist
android/local.properties
android/key.properties
```

Keep the real files locally or store them as secure files/variables in CI.

## Required build variable

Every release build must receive:

```text
--dart-define=ITGA_API_KEY=replace-with-backend-API_SECRET_KEY
```

## Android validation

```bash
flutter pub get
flutter test --no-pub
flutter build apk --release --dart-define=ITGA_API_KEY=replace-with-backend-API_SECRET_KEY
flutter build appbundle --release --dart-define=ITGA_API_KEY=replace-with-backend-API_SECRET_KEY
```

The current Gradle release signing still uses debug signing. Configure a real upload keystore before Play Store production.

## iOS Codemagic variables

Set these secure environment variables in Codemagic:

```env
ITGA_API_KEY=replace-with-backend-API_SECRET_KEY
FIREBASE_IOS_PLIST_B64=base64-of-ios/Runner/GoogleService-Info.plist
FIREBASE_ANDROID_JSON_B64=base64-of-android/app/google-services.json
```

Run `ios-test-no-codesign` first, then `ios-testflight-signed`.
