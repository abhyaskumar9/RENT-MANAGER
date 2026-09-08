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

// Fixed Loop: Yeh tarika bina kisi syntax crash ke sabhi background plugins ko SDK 36 par update kar dega
subprojects {
    afterEvaluate {
        if (hasProperty("android")) {
            val androidExtension = property("android")
            if (androidExtension is com.android.build.api.dsl.LibraryExtension) {
                androidExtension.compileSdk = 36
                androidExtension.defaultConfig.targetSdk = 36
            }
        }
    }
}
