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
    namespace = "com.brandbuilder.breakingbread.bakery"
    // compileSdk follows whichever Android SDK our plugins are built
    // against — multiple Flutter plugins (geolocator, package_info_plus,
    // shared_preferences, sqflite) compile against 36, so we match.
    // Backward compatible — doesn't affect minSdk / targetSdk / what
    // devices can install. [targetSdk] below is what Play Store cares
    // about; that stays at 35 to match the current Play floor.
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
        applicationId = "com.brandbuilder.breakingbread.bakery"
        // Android 6 (Marshmallow). Covers ~99% of active devices in
        // Nepal and gives us runtime permission APIs by default.
        minSdk = flutter.minSdkVersion
        targetSdk = 35
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
