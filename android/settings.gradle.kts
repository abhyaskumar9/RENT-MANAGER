pluginManagement {
    val flutterSdkPath = run {
        val properties = java.util.Properties()
        val flutterPropertiesFile = settingsDir.resolve("local.properties")
        if (flutterPropertiesFile.exists()) {
            flutterPropertiesFile.inputStream().use { properties.load(it) }
        }
        properties.getProperty("flutter.sdk") ?: throw java.io.FileNotFoundException("flutter.sdk not set in local.properties")
    }

    includeBuild("$flutterSdkPath/packages/flutter_tools/gradle")

    repositories {
        google()
        mavenCentral()
        gradlePluginPortal()
    }
}

plugins {
    id("dev.flutter.flutter-gradle-plugin") version "1.0.0" apply false
    id("com.android.application") version "7.4.2" apply false
    id("org.jetbrains.kotlin.android") version "1.8.22" apply false
}

include(":app")

// Yeh block gradle evaluation ke baad saare internal plugins aur subprojects ko forcefully 1.8 par lock kar dega
gradle.projectsEvaluated {
    allprojects {
        tasks.withType(org.jetbrains.kotlin.gradle.tasks.KotlinCompile::class.java).configureEach {
            kotlinOptions {
                jvmTarget = "1.8"
                languageVersion = "1.8"
            }
        }
    }
}
