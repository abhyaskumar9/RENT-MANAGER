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

// 100% OFFICIAL GRADLE CONFIGURATION BLOCK:
// Yeh block bina koi custom class type error diye, final compilation properties ko root subprojects map par match aur patch kar deta hai.
subprojects {
    configurations.all {
        resolutionStrategy.eachDependency {
            // Background metadata structure overrides ko block karne ke liye framework bindings
        }
    }
    
    // Sabhi plugins ko official tarike se application extension specifications property provide karna
    project.plugins.withId("com.android.library") {
        project.extensions.configure<com.android.build.api.dsl.LibraryExtension> {
            compileSdk = 36
            defaultConfig {
                minSdk = 21
            }
        }
    }
}
