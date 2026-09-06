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
    
    plugins.withType<com.android.build.gradle.api.AndroidBasePlugin> {
        project.extensions.configure<com.android.build.BaseExtension> {
            compileSdkVersion(34)
            defaultConfig {
                targetSdkVersion(34)
            }
        }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
