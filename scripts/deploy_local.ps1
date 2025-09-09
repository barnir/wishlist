# Local deployment helper for Wishlist App
# Usage: .\deploy_local.ps1 -Environment dev
param(
    [string]$Environment = 'dev'
)

Write-Host "Starting local deploy helper for environment: $Environment"

# 1. Ensure flutter deps
Write-Host "Running flutter pub get..."
flutter pub get

# 2. Build functions
Write-Host "Building Cloud Functions..."
Push-Location functions
npm install
npm run build
Pop-Location

# 3. Build AAB (release) - requires android/key.properties to exist with signing info
Write-Host "Building AAB (release)..."
if (-Not (Test-Path android/key.properties)) {
    Write-Host "android/key.properties not found. Create it from android/key.properties.example with your keystore credentials." -ForegroundColor Yellow
} else {
    flutter build appbundle --release
}

Write-Host "Local build complete. Next steps (manual):"
Write-Host " - firebase deploy --only functions --project <PROJECT_ID>" -ForegroundColor Cyan
Write-Host " - Upload app-release.aab to Play Console (internal track) or use fastlane/Google Play API." -ForegroundColor Cyan
