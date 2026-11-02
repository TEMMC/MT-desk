import java.util.Properties

plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
}

// Release signing: app/android/key.properties (local) or MT_DESK_* env vars (CI).
val releaseKeystore = Properties().apply {
    rootProject.file("key.properties").takeIf { it.isFile }?.inputStream()?.use(::load)
}
fun releaseSetting(property: String, env: String): String? =
    (releaseKeystore.getProperty(property) ?: System.getenv(env))?.trim()?.takeIf { it.isNotEmpty() }
val releaseStoreFile = releaseSetting("storeFile", "MT_DESK_KEYSTORE")

android {
    namespace = "com.mtdesk.desktop"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion
    buildFeatures { aidl = true }
    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }
    kotlinOptions { jvmTarget = JavaVersion.VERSION_17.toString() }
    defaultConfig {
        applicationId = "com.mtdesk.desktop"
        minSdk = 28
        targetSdk = 28
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        ndk { abiFilters += listOf("arm64-v8a") }
    }
    signingConfigs {
        if (releaseStoreFile != null) {
            create("release") {
                storeFile = file(releaseStoreFile)
                storePassword = releaseSetting("storePassword", "MT_DESK_KEYSTORE_PASSWORD")
                keyAlias = releaseSetting("keyAlias", "MT_DESK_KEY_ALIAS")
                keyPassword = releaseSetting("keyPassword", "MT_DESK_KEY_PASSWORD")
            }
        }
    }
    buildTypes {
        release {
            signingConfig = if (releaseStoreFile != null) signingConfigs.getByName("release") else signingConfigs.getByName("debug")
            proguardFiles(getDefaultProguardFile("proguard-android-optimize.txt"), "proguard-rules.pro")
        }
    }
    externalNativeBuild {
        cmake {
            path = file("src/main/cpp/CMakeLists.txt")
            version = "3.22.1"
        }
    }
    lint {
        abortOnError = false
        checkReleaseBuilds = false
    }
    packaging { jniLibs.useLegacyPackaging = true }
}
flutter { source = "../.." }
