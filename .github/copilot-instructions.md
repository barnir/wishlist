## Copilot Instructions – Wishlist Flutter App

Purpose
Single‑repo Flutter application (EXCLUSIVELY ANDROID – no web/iOS targets) with Firebase (Auth, Firestore, Functions, Messaging, Analytics) and Cloudinary for image handling. Functions code lives under `functions/` (TypeScript) – only `secureScraper` + Firestore aggregate triggers remain (purge/admin utilities removed). Do NOT suggest or run web (`-d chrome`) or iOS build/test commands.

Discovery (follow this order)
1. `pubspec.yaml`: versions (Flutter 3.22+, Dart 3.4), dependencies, firebase plugin versions, splash + l10n setup.
2. `README.md`: high‑level features, architecture diagram, env variables required.
3. Entrypoint: `lib/main.dart` (loads `.env` via `flutter_dotenv`, sets up Firebase, localization, themes).
4. Configuration & helpers: `lib/config.dart`, `theme.dart`, `theme_extensions.dart`.
5. Domain models: `lib/models/*.dart` (e.g. `wish_item.dart` includes quantity, price, optional Cloudinary public id).
6. Repositories & services: `lib/services/` (auth, cloudinary, functions wrapper, analytics, rate limiting, image cache/prefetch) + any repository classes under `lib/repositories/`.
7. UI composition: `lib/screens/` (each screen minimal business logic, defers to services) and `lib/widgets/` (reusable components, optimized Cloudinary image).
8. Functions backend: `functions/src/index.ts` (incremental wishlist aggregates + `secureScraper`).
9. Localization: `l10n.yaml`, ARB files under `lib/l10n/`, generated outputs under `lib/generated/l10n/` – do NOT edit generated files.

Architecture & Patterns
- Clean-ish layering: Screens → Services/Repositories → Firestore/Firebase/Cloudinary.
- State is mostly ephemeral via service singletons; no heavy state management library (avoid introducing one unless necessary).
- Image handling central: always resolve Cloudinary transforms via `cloudinary_service.dart` / `OptimizedCloudinaryImage` widget. Don’t inline transformation URLs.
- Async guards & validation: use `ValidationUtils` and existing null/empty checks; mimic patterns in `add_edit_item_screen.dart` for forms.
- Aggregates: Firestore triggers maintain `wishlists.item_count` & `wishlists.total_value`; client should not attempt to compute these fields directly.
- Environment variables: accessed via `dotenv.env[...]` in Dart; Functions use `process.env` (dotenv loaded server-side). Never hardcode secrets in code.

Key Services (examples)
- Auth: `auth_service.dart` / `firebase_auth_service.dart` – prefer calling high-level methods (e.g. sign-in flows) rather than direct FirebaseAuth usage.
- Cloudinary: `cloudinary_service.dart` handles upload, deletion, optimized URL building; reuse existing enums / builders when adding image contexts.
- Web scraping: call callable `secureScraper` through existing function wrapper; respect domain allow‑list (don’t extend without updating allow arrays + security notes).
- Analytics: use provider wrapper; sanitize parameter maps (see `firebase_analytics_provider.dart`).

Conventions
- Models: factory `fromMap` / `toMap` with null safety & default fallbacks (copy style from `wish_item.dart`).
- Strings & UI text: Always retrieve from `AppLocalizations` (no raw user-facing literals except temporary debug logs).
- Theming: Extend with `AppSemanticColors`; if new semantic role needed, add to extension in `theme_extensions.dart` for both light & dark.
- Error surfacing: Use `AppSnack.show(context, message, type: ...)` rather than ScaffoldMessenger directly.
- Image public IDs naming: `profile_<uid>`, `wishlist_<wishlistId>`, `product_<wishItemId>` – maintain pattern for cleanup consistency.

Adding Features (example flow)
1. Model field: add to relevant model + serialization + (if aggregated) adapt Firestore trigger or create new one.
2. Service logic: implement in a new method inside appropriate existing service instead of a new service unless boundary clearly different.
3. UI: update screen; keep build methods lean – push side effects & I/O to service calls.
4. Localization: add keys to `lib/l10n/app_pt.arb` & `app_en.arb`, then run flutter gen-l10n (flutter pub run intl_utils / built-in l10n tool depending on project setup).
5. Testing (when added): prefer lightweight unit tests (if harness introduced later) for serialization & service logic.

Do / Avoid
DO reuse existing Cloudinary transformation constants.  
DO respect existing rate limiting patterns in services.  
DO keep new Firebase callable functions minimal and secured (auth + allowlist).  
AVOID introducing blocking synchronous waits in build methods.  
AVOID duplicating business logic inside widgets/screens (delegate to services).  
AVOID editing generated localization files or mixing languages directly.

Build & Run
- App (Android only): `flutter pub get` then `flutter run -d <android-device>` (physical or emulator). Do NOT invoke `flutter run -d chrome` or other platforms.  
- Functions: `cd functions && npm install && npm run build && firebase deploy --only functions` (only `secureScraper` + triggers exist now).  
- Analyze: `flutter analyze` must stay at 0 issues (one tolerated info is documented in context – don’t introduce new ones).  
- Image testing: use small sample uploads; verify URL transformation (check width/quality params).  
- If a command would target web/iOS (e.g. `flutter build web`), skip and request clarification instead.

Edge Cases / Pitfalls
- Wish item migrations: if adding non-nullable fields, backfill or provide default in `fromMap` to avoid crashes on older docs.
- Network-heavy screens: ensure pagination respects existing throttle/backoff pattern (see repository logic for wish items).
- Scraper expansions: update trust lists & ensure no SSRF vectors (disallow internal hosts, maintain suspicious patterns array).
- Environment leakage: never commit real `.env` values (placeholders only). Secrets were sanitized – keep it that way.

Validation Before PR / Commit
- `flutter analyze` clean.  
- Hot reload still works for modified screens.  
- Added localization keys present in both PT & EN.  
- No direct string literals in Portuguese inside code (except logs) – use l10n.

When Unsure
Search for a similar pattern (e.g. existing image upload flow) and mirror it. Ask for clarification if a new cross-cutting concern arises (e.g. need for caching layer or new aggregate field).

End of instructions.
