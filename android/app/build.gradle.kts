plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.rent_manager" // Agar aapka package name alag hai toh wahi rehne dein
    compileSdk = 34

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        freeCompilerArgs += listOf("-Xjsr305=strict")
    }

    // Naye standard ke mutabik jvmTarget ko yahan set karte hain
    kotlin {
        jvmToolchain(17)
    }

    defaultConfig {
        applicationId = "com.example.rent_manager"
        minSdk = 21
        targetSdk = 34
        versionCode = 1
        versionName = "1.0.0"
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("debug") // Ya jo bhi aapka release configuration ho
            isMinifyEnabled = false
            isShrinkResources = false
        }
    }
}

flutter {
    source = "../.."
}
