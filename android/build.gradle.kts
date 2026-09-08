allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

// Subprojects build directories configuration
val rootBuildDir = rootProject.layout.buildDirectory.dir("../build")
subprojects {
    project.layout.buildDirectory.set(rootBuildDir.map { it.dir(project.name) })
}

subprojects {
    project.evaluationDependsOn(":app")
}

// FIXED KOTLIN OVERRIDE: Sabhi plugins ko bina kisi error ke strict SDK 36 par build karne ka sahi tarika
subprojects {
    afterEvaluate {
        if (project.hasProperty("android")) {
            val androidExt = project.extensions.findByName("android")
            if (androidExt != null) {
                try {
                    // Reflection use karke properties ko safely inject karna
                    val setCompileSdkVersion = androidExt.javaClass.getMethod("setCompileSdkVersion", Int::class.javaPrimitiveType)
                    setCompileSdkVersion.invoke(androidExt, 36)
                    
                    val getDefaultConfig = androidExt.javaClass.getMethod("getDefaultConfig")
                    val defaultConfig = getDefaultConfig.invoke(androidExt)
                    val setTargetSdkVersion = defaultConfig.javaClass.getMethod("setTargetSdkVersion", Int::class.javaPrimitiveType)
                    setTargetSdkVersion.invoke(defaultConfig, 36)
                } catch (e: Exception) {
                    // Kisi bhi hierarchy failure ko safe catch karna
                }
            }
        }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
