pluginManagement {
    val flutterSdkPath =
        run {
            val properties = java.util.Properties()
            val localPropertiesFile = file("../local.properties")
            if (localPropertiesFile.exists()) {
                localPropertiesFile.inputStream().use { properties.load(it) }
            }
            // अगर फाइल नहीं है, तो यह GitHub के डिफॉल्ट एनवायरनमेंट से रास्ता उठा लेगा
            properties.getProperty("flutter.sdk") ?: System.getenv("FLUTTER_ROOT") ?: ""
        }

    if (flutterSdkPath.isNotEmpty()) {
        includeBuild("$flutterSdkPath/packages/flutter_tools/gradle")
    }

    repositories {
        google()
        mavenCentral()
        gradlePluginPortal()
    }
}

plugins {
    id("dev.flutter.flutter-plugin-loader") version "1.0.0"
    id("com.android.application") version "8.2.2" apply false
    id("org.jetbrains.kotlin.android") version "1.9.22" apply false
}

include(":app")
