import java.util.Properties

plugins {
    id("com.android.application")
    id("com.google.gms.google-services")
    id("com.google.firebase.crashlytics")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// Release signing: create android/key.properties (gitignored) with storeFile, storePassword, keyAlias, keyPassword.
val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    keystorePropertiesFile.inputStream().use { keystoreProperties.load(it) }
}

android {
    namespace = "com.sevanest.customer"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
        isCoreLibraryDesugaringEnabled = true
    }

    defaultConfig {
        // Must match the Firebase Android app (google-services.json).
        applicationId = "com.sevanest.customer"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildFeatures {
        resValues = true
    }

    flavorDimensions += "env"
    // No applicationIdSuffix: Firebase only has com.sevanest.customer registered, so every flavor shares it.
    productFlavors {
        create("dev") {
            dimension = "env"
            // Dev release APKs (manual testing) are debug-signed; stg and prod need the release keystore.
            signingConfig = signingConfigs.getByName("debug")
            resValue("string", "app_name", "SevaNest Dev")
        }
        create("stg") {
            dimension = "env"
            resValue("string", "app_name", "SevaNest Stg")
        }
        create("prod") {
            dimension = "env"
            resValue("string", "app_name", "SevaNest")
        }
    }

    signingConfigs {
        if (keystorePropertiesFile.exists()) {
            create("release") {
                keyAlias = keystoreProperties["keyAlias"] as String
                keyPassword = keystoreProperties["keyPassword"] as String
                storeFile = file(keystoreProperties["storeFile"] as String)
                storePassword = keystoreProperties["storePassword"] as String
            }
        }
    }

    buildTypes {
        release {
            // No debug-signing fallback: a release build without android/key.properties fails (see below).
            signingConfig = signingConfigs.findByName("release")
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(getDefaultProguardFile("proguard-android-optimize.txt"), "proguard-rules.pro")
        }
    }
}

// Fail any stg/prod release assemble/bundle early when the keystore config is missing.
if (!keystorePropertiesFile.exists()) {
    gradle.taskGraph.whenReady {
        if (allTasks.any { Regex("(assemble|bundle)(Stg|Prod)Release").matches(it.name) }) {
            throw GradleException("android/key.properties is missing: release builds must be signed with the release keystore.")
        }
    }
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

flutter {
    source = "../.."
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.5")
}
