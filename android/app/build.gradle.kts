plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.rent_manager.app"
    compileSdk = 36 

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlin {
        jvmToolchain(17)
    }

    defaultConfig {
        applicationId = "com.rent_manager.app"
        minSdk = 21
        targetSdk = 36 
        versionCode = 1
        versionName = "1.0.0"
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("debug")
            isMinifyEnabled = false
            isShrinkResources = false
        }
    }
}

flutter {
    source = "../.."
}

// Subprojects configuration block jo safely bina kisi syntax crash ke plugins ko patch karega
subprojects {
    afterEvaluate {
        if (project.hasProperty("android")) {
            val androidExt = project.extensions.findByName("android")
            if (androidExt != null) {
                // Yeh check karta hai ki plugin library hai ya application aur unhe target karta hai
                try {
                    val libExt = androidExt as? com.android.build.api.dsl.LibraryExtension
                    libExt?.compileSdk = 36
                    libExt?.defaultConfig?.targetSdk = 36
                } catch (e: Exception) {
                    // Fallback configuration error ko bypass karne ke liye
                }
            }
        }
    }
}
