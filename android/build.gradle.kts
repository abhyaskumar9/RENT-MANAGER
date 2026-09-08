allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

subprojects {
    project.evaluationDependsOn(":app")
}

// OFFICIAL PLUGINS VERSION CONFIGURATION: 
// Yeh block bina kisi crash ke aapke sabhi host packages ko strict API 36 allocation provide karega
subprojects {
    afterEvaluate {
        if (project.hasProperty("android")) {
            project.extensions.configure<com.android.build.api.dsl.LibraryExtension> {
                compileSdk = 36
                defaultConfig {
                    minSdk = 21
                }
            }
        }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
