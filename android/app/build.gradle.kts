plugins {
    id("com.android.application")
    id("kotlin-android")
    // Flutter standard plugin loader
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    // Yahan humne compileSdk ko 36 kar diya hai taaki file_picker build ho sake
    compileSdk = 36

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = "17"
    }

    sourceSets {
        getByName("main").java.srcDirs("src/main/kotlin")
    }

    defaultConfig {
        // Apne app ka sahi application id (package name) yahan daal sakte hain
        applicationId = "com.example.rent_manager" 
        
        // Minimum Android version jo app support karega (Android 5.0)
        minSdk = 21
        
        // targetSdk ko bhi 36 par enforce kiya gaya hai
        targetSdk = 36
        
        versionCode = 1
        versionName = "1.0.0"
    }

    buildTypes {
        getByName("release") {
            // Release build ke liye signing config yahan aayegi
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
