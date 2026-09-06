allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

val flutterProjectRoot = rootProject.projectDir.parentFile
val pluginsFile = java.io.File(flutterProjectRoot, ".flutter-plugins-dependencies")
if (pluginsFile.exists()) {
    apply(from = "$flutterProjectRoot/.flutter-plugins-dependencies")
}

subprojects {
    project.evaluationDependsOn(":app")
    rootProject.subprojects.forEach { it.setBuildDir(null) }
    
    // Yeh tarika Gradle ke naye versions me 100% crash-free chalta hai
    plugins.withId("com.android.application") {
        configure<com.android.build.api.dsl.ApplicationExtension> {
            compileSdk = 34
            defaultConfig {
                targetSdk = 34
            }
        }
    }
    plugins.withId("com.android.library") {
        configure<com.android.build.api.dsl.LibraryExtension> {
            compileSdk = 34
            defaultConfig {
                targetSdk = 34
            }
        }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
