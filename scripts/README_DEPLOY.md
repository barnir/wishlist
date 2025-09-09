# Deploy helpers and CI

This project includes a GitHub Actions workflow and a local PowerShell helper to build and deploy the app and Cloud Functions.

## Secrets required for CI/CD
Add these repository secrets in GitHub Settings → Secrets → Actions:

- KEYSTORE_BASE64: Base64-encoded content of android/app/release.keystore (optional but needed to sign in CI)
- KEYSTORE_PASSWORD: keystore password
- KEY_ALIAS: signing key alias
- KEY_PASSWORD: key password
- GOOGLE_PLAY_SERVICE_ACCOUNT_JSON: JSON content of service account key for Google Play (plain text)
- GOOGLE_PLAY_PACKAGE_NAME: Android package id (p.ex. com.mycompany.myapp)
- FIREBASE_TOKEN: CI token for firebase CLI (use `firebase login:ci` locally to generate)
- FIREBASE_PROJECT_ID: Firebase project id to deploy functions to

## Local deploy
Use `scripts/deploy_local.ps1` to build artifacts locally and compile Cloud Functions. For publishing use firebase CLI and Play Console.
