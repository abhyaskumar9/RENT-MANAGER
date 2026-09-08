plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.rent_manager.app"
    compileSdk = 36 // Main app ko direct 36 par set kiya

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
        targetSdk = 36 // Target version ko bhi 36 kiya
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

// SAFE OVERRIDE: Yeh block 'file_picker' aur baaki plugins ko safely compileSdk 36 standard par push karega
gradle.api.Project.getDependencies() // Initial validation link karne ke liye
subprojects {
    afterEvaluate {
        if (project.hasProperty("android")) {
            val extension = project.extensions.findByName("android")
            if (extension != null) {
                // Bina kisi data casting issue ke methods ke through SDK 36 load karna
                try {
                    val setCompileSdk = extension.javaClass.getMethod("setCompileSdkVersion", Int::class.javaPrimitiveType)
                    setCompileSdk.invoke(extension, 36)
                } catch (e: Exception) {
                    // Agar property direct available ho
                    try {
                        val compileSdkProp = extension.javaClass.getMethod("setCompileSdk", Int::class.javaPrimitiveType)
                        compileSdkProp.invoke(extension, 36)
                    } catch (ex: Exception) {}
                }
            }
        }
    }
}
