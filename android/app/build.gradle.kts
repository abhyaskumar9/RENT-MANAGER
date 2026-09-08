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

// STABLE DECLARATIVE CONFIGURATION: Sabhi plugins (jaise file_picker) ko safe parameters assign karne ke liye
subprojects {
    val subproject = this
    subproject.plugins.configureEach {
        if (this::class.java.name.contains("LibraryPlugin")) {
            val androidExt = subproject.extensions.findByName("android")
            if (androidExt != null) {
                try {
                    val setCompileSdk = androidExt.javaClass.getMethod("setCompileSdkVersion", Int::class.javaPrimitiveType)
                    setCompileSdk.invoke(androidExt, 36)
                } catch (e: Exception) {
                    try {
                        val setCompileSdkAlt = androidExt.javaClass.getMethod("setCompileSdk", Int::class.javaPrimitiveType)
                        setCompileSdkAlt.invoke(androidExt, 36)
                    } catch (ex: Exception) {}
                }
            }
        }
    }
}
