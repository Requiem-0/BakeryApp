import java.util.Properties
import java.io.FileInputStream

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// Firebase build plugins. Applied only when `google-services.json`
// exists in this directory — without that file, the plugins fail
// the build. Dev machines that don't have the secret config can
// still build the app without Firebase / Crashlytics (the Dart-side
// init is wrapped in a try/catch to match).
//
// To enable on this machine:
//   1. Drop the `google-services.json` provided by the backend team
//      into `android/app/google-services.json` (gitignored).
//   2. Run `flutter clean && flutter run` — the plugins kick in
//      automatically.
if (file("google-services.json").exists()) {
    apply(plugin = "com.google.gms.google-services")
    apply(plugin = "com.google.firebase.crashlytics")
}

// Release signing config — read from `android/key.properties` if it
// exists. That file is gitignored and lives outside the repo (or on
// the build machine only). When it's absent (dev machines that don't
// have the upload keystore yet) the build falls back to debug keys so
// `flutter run --release` still works for smoke testing.
val keystorePropertiesFile = rootProject.file("key.properties")
val keystoreProperties = Properties()
val hasUploadKeystore = keystorePropertiesFile.exists()
if (hasUploadKeystore) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

android {
    namespace = "com.brandbuilder.breakingbread"
    // compileSdk follows whichever Android SDK our plugins are built
    // against — multiple Flutter plugins (geolocator, package_info_plus,
    // shared_preferences, sqflite) compile against 36, so we match.
    // Backward compatible — doesn't affect minSdk / targetSdk / what
    // devices can install. [targetSdk] below is what Play Store cares
    // about; bumped to 36 to meet Google Play's Aug 31 2026 target
    // API requirement (apps must target within one year of the
    // latest Android release).
    compileSdk = 36
    // Pinned to a locally-installed NDK so Gradle doesn't try to fetch
    // `flutter.ndkVersion` (28.2.13676358) every cold build. orderB is
    // pure Flutter — no JNI — so any NDK on the path works.
    ndkVersion = "29.0.13846066"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        applicationId = "com.brandbuilder.breakingbread"
        // Android 6 (Marshmallow). Covers ~99% of active devices in
        // Nepal and gives us runtime permission APIs by default.
        minSdk = flutter.minSdkVersion
        // Android 16 (API 36). Meets Google Play's target-API floor
        // that kicks in on 2026-08-31. Bumped from 35 to 36 here;
        // behavioural changes to watch for on this app: (a) mandatory
        // edge-to-edge rendering — already handled since the status
        // bar is hidden globally and SafeArea wraps the bottom nav,
        // (b) predictive-back gesture — opt-in below in the manifest.
        targetSdk = 36
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        create("release") {
            if (hasUploadKeystore) {
                keyAlias = keystoreProperties["keyAlias"] as String?
                keyPassword = keystoreProperties["keyPassword"] as String?
                storeFile = (keystoreProperties["storeFile"] as String?)?.let { file(it) }
                storePassword = keystoreProperties["storePassword"] as String?
            }
        }
    }

    buildTypes {
        release {
            // Use the upload keystore when present, fall back to debug
            // keys otherwise so contributors who don't have the
            // production key can still build the release variant for
            // local profiling.
            signingConfig = if (hasUploadKeystore)
                signingConfigs.getByName("release")
            else
                signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}
