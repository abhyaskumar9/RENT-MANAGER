allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

val rootProjectBuildDir = "../build"
rootProject.layout.buildDirectory.set(file(rootProjectBuildDir))

subprojects {
    val newBuildDir = "$rootProjectBuildDir/${project.name}"
    project.layout.buildDirectory.set(file(newBuildDir))
}

subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}

// Yeh block Kotlin syntax me saare plugins ko SDK 36 par compile hone ke liye force karega
subprojects {
    afterEvaluate {
        if (project.hasProperty("android")) {
            val android = project.extensions.findByName("android") as? com.android.build.gradle.BaseExtension
            android?.apply {
                compileSdkVersion(36)
                targetSdkVersion(36)
            }
        }
    }
}
