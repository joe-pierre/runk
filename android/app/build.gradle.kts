plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.senluxtech.runk"
    // Version explicite requise par androidx.core:core-ktx 1.18.0 (dépendance
    // transitive de connectivity_plus, ajouté Tâche 9 pour SyncService), qui
    // exige de compiler contre l'API 36 — voir DECISIONS.md.
    compileSdk = 36
    // Version explicite requise par plusieurs plugins (isar_community_flutter_libs,
    // receive_sharing_intent, path_provider, url_launcher, ...) qui embarquent
    // du code natif compilé avec un NDK plus récent que celui par défaut de
    // Flutter — voir DECISIONS.md.
    ndkVersion = "27.0.12077973"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.senluxtech.runk"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        // isar_community_flutter_libs impose minSdk 23 (Android 6.0) — voir DECISIONS.md.
        minSdk = 23
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            // TODO: Add your own signing config for the release build.
            // Signing with the debug keys for now, so `flutter run --release` works.
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}
