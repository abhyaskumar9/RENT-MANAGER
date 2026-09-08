allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

subprojects {
    project.evaluationDependsOn(":app")
}

// OFFICIAL SYNTAX OVERRIDE: Yeh tarika bina kisi afterEvaluate error ke sabhi plugins ko direct control karta hai
subprojects {
    afterEvaluate {
        if (project.hasProperty("android")) {
            val android = project.extensions.findByName("android")
            if (android is com.android.build.api.dsl.LibraryExtension) {
                android.compileSdk = 36
                android.defaultConfig.targetSdk = 36
            }
        }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
