plugins {
    id("com.android.application")
    // START: FlutterFire Configuration
    id("com.google.gms.google-services")
    // END: FlutterFire Configuration
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.buendidev.travel_ready"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_23
        targetCompatibility = JavaVersion.VERSION_23
        isCoreLibraryDesugaringEnabled = true
    }

    kotlinOptions {
        jvmTarget = "23"
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.buendidev.travel_ready"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        create("release") {
            val propsFile = file("../key.properties")
            val props = if (propsFile.exists()) {
                propsFile.readLines(Charsets.UTF_8)
                    .filter { it.contains("=") && !it.trimStart().startsWith("#") }
                    .associate {
                        val line = it.removePrefix("\uFEFF")
                        val parts = line.split("=", limit = 2)
                        parts[0].trim() to parts[1].trim()
                    }
            } else emptyMap()
            keyAlias = props["keyAlias"]
            keyPassword = props["keyPassword"]
            val storeFilePath = props["storeFile"]
            storeFile = if (storeFilePath != null) file(storeFilePath) else null
            storePassword = props["storePassword"]
        }
    }

    buildTypes {
        release {
            // TODO: Add your own signing config for the release build.
            // Signing with the debug keys for now, so `flutter run --release` works.
            signingConfig = signingConfigs.getByName("release")
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}
