plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    // File_picker ke liye SDK 36 enforce kiya gaya hai
    compileSdk = 36

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    // Naya syntax compilerOptions use karein jo error ko door karega
    compilerOptions {
        jvmTarget.set(org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17)
    }

    sourceSets {
        getByName("main") {
            // Naye Gradle me directories mutable set ka use hota hai
            java.directories.set(setOf("src/main/kotlin"))
        }
    }

    defaultConfig {
        applicationId = "com.example.rent_manager" 
        minSdk = 21
        targetSdk = 36 
        versionCode = 1
        versionName = "1.0.0"
    }

    buildTypes {
        getByName("release") {
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    implementation("org.jetbrains.kotlin:kotlin-stdlib-jdk7:1.8.22")
}
