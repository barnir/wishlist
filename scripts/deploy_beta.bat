@echo off
echo 🚀 Building and deploying beta version...

echo 📱 Building APK...
flutter build apk --release

echo 📤 Resolving App Distribution settings from firebase.json...
for /f "usebackq delims=" %%J in (`powershell -NoProfile -Command "(Get-Content -Raw 'firebase.json' | ConvertFrom-Json).appDistribution | ConvertTo-Json -Compress"`) do set _APPDIST=%%J

rem parse JSON with PowerShell to extract app and groups
for /f "usebackq delims=" %%A in (`powershell -NoProfile -Command "$j = ConvertFrom-Json '%_APPDIST%'; Write-Output $j.app` 2^>^&1`) do set FIRE_APP=%%~A
for /f "usebackq delims=" %%B in (`powershell -NoProfile -Command "$j = ConvertFrom-Json '%_APPDIST%'; if ($j.groups) { $j.groups -join ',' }` 2^>^&1`) do set FIRE_GROUPS=%%~B

if "%FIRE_APP%"=="" (
  echo [WARN] No app id found in firebase.json; falling back to hard-coded value
  set FIRE_APP=1:515293340951:android:c9caa6afc7bcfd5f040352
)
if "%FIRE_GROUPS%"=="" (
  echo [WARN] No groups found in firebase.json; falling back to wishlist-beta-testers
  set FIRE_GROUPS=wishlist-beta-testers
)

echo 📤 Deploying to Firebase App Distribution (app=%FIRE_APP%, groups=%FIRE_GROUPS%)...
firebase appdistribution:distribute build\app\outputs\flutter-apk\app-release.apk --app %FIRE_APP% --groups "%FIRE_GROUPS%" --release-notes-file release_notes.txt

if %ERRORLEVEL% EQU 0 (
  echo ✅ Deployment completed!
) else (
  echo ❌ Deployment failed with exit code %ERRORLEVEL%
)