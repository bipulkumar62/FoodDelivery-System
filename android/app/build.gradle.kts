plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.pawanbiryani.pawan_biryani"

    // Flutter ke compatible SDK versions use karo.
    
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        applicationId = "com.pawanbiryani.pawan_biryani"

        minSdk = 24
        targetSdk = flutter.targetSdkVersion

        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    packaging {
        jniLibs {
            // Flutter ki native library ko dobara strip karne ki koshish mat karo.
            keepDebugSymbols += "**/libapp.so"
        }
    }

    buildTypes {
        release {
            // Testing ke liye temporary.
            // Play Store upload se pehle proper release keystore use karna hoga.
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}
