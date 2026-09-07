# Flutter + plugin keep-rules for R8 in release builds.
#
# `flutter build appbundle --release` runs with `isMinifyEnabled = true`
# and `isShrinkResources = true` (see android/app/build.gradle.kts).
# Without these rules, R8 strips reflected classes that plugins load
# by name and the release crashes at startup with ClassNotFoundException.

# --- Flutter embedding & core -------------------------------------
-keep class io.flutter.embedding.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.plugins.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-dontwarn io.flutter.embedding.**

# --- Firebase / Crashlytics ---------------------------------------
# Crashlytics reads stack frames via reflection; the mapping file is
# uploaded to Google separately for deobfuscation.
-keepattributes SourceFile,LineNumberTable
-keep class com.google.firebase.** { *; }
-dontwarn com.google.firebase.**

# --- Play Core (used by google_play_services_flutter deps) ---------
-keep class com.google.android.play.core.** { *; }
-dontwarn com.google.android.play.core.**

# --- Retrofit / OkHttp / Kotlin metadata --------------------------
-keepattributes Signature, InnerClasses, EnclosingMethod
-keep class kotlin.Metadata { *; }
-dontwarn okhttp3.**
-dontwarn okio.**

# --- Dart JIT / debug symbols kept out of release build ------------
# Nothing to do here — Flutter's Gradle plugin handles it — but leave
# the placeholder so future release-blocking symbols land in one spot.
