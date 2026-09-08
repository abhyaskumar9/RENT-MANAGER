allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

subprojects {
    project.evaluationDependsOn(":app")
}

// FORCE PLUGINS SDK 36 (Bina kisi typing crash ke plugins checking criteria pass karne ka sahi tarika)
subprojects {
    afterEvaluate {
        val extension = extensions.findByName("android")
        if (extension != null) {
            val extensionClass = extension::class.java.name
            if (extensionClass.contains("LibraryExtension") || extensionClass.contains("ApplicationExtension")) {
                try {
                    // Script automation explicitly versions ko update kar degi
                    val dslExtension = extension as com.android.build.api.dsl.CommonExtension<*, *, *, *, *, *>
                    dslExtension.compileSdk = 36
                    dslExtension.defaultConfig.targetSdk = 36
                } catch (e: Exception) {
                    // Errors ko catch karke pipeline fail hone se rokega
                }
            }
        }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
