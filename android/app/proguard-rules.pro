# ProGuard rules for Wishlist App
# Safe keep Firebase / Flutter entry points & models

# Flutter Wrapper
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugins.** { *; }
-keep class io.flutter.embedding.** { *; }

# Keep generated registrant
-keep class io.flutter.plugins.GeneratedPluginRegistrant { *; }

# Firebase (analytics, messaging, auth, firestore, functions, core)
-keep class com.google.firebase.** { *; }
-dontwarn com.google.firebase.**

# Cloud Functions callable serialization
-keepclassmembers class * {
    @com.google.firebase.functions.FirebaseFunctionsApi <methods>;
}

# Cloudinary public SDK (avoid stripping helpers)
-keep class com.cloudinary.** { *; }
-dontwarn com.cloudinary.**

# SharedPreferences JSON / model reflection (if any future reflection is introduced)
-keep class ** extends java.lang.annotation.Annotation { *; }

# Kotlin (avoid warnings for metadata)
-keep class kotlin.Metadata { *; }

# Keep parcelables (Contacts / Sharing intents) – broad keep for plugin data classes
-keep class * implements android.os.Parcelable { *; }

# Prevent obfuscation of your app's main activities (adjust if package id changes)
-keep class com.example.wishlist_app.MainActivity { *; }

# TODO: After enabling minify, run mapping check & tighten these rules.
