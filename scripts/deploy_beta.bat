@echo off
echo 🚀 Building and deploying beta version...

echo 📱 Building APK...
flutter build apk --release

echo 📤 Deploying to Firebase App Distribution...
firebase appdistribution:distribute build\app\outputs\flutter-apk\app-release.apk ^
  --app 1:515293340951:android:c9caa6afc7bcfd5f040352 ^
  --groups "wishlist-beta-testers" ^
  --release-notes-file release_notes.txt

echo ✅ Deployment completed!