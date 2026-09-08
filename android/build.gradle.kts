allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

subprojects {
    project.evaluationDependsOn(":app")
}

// Dynamic injection block jo bina type error ke plugins ko host version par configuration link karega
subprojects {
    afterEvaluate {
        if (project.hasProperty("android")) {
            val androidExt = project.extensions.getByName("android")
            // Reflection ke through safely variables push karna, bina interface loading error ke
            try {
                androidExt.javaClass.getMethod("setCompileSdkVersion", Int::class.javaPrimitiveType).invoke(androidExt, 36)
            } catch (e: Exception) {
                // Application/Library Extension specific checks override
                try {
                    val target = androidExt.javaClass.getMethod("getDefaultConfig").invoke(androidExt)
                    target.javaClass.getMethod("setTargetSdkVersion", Int::class.javaPrimitiveType).invoke(target, 36)
                } catch (ex: Exception) {}
            }
        }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
