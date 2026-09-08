allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

subprojects {
    project.evaluationDependsOn(":app")
    
    plugins.withId("com.android.application") {
        configure<com.android.build.api.dsl.ApplicationExtension> {
            compileSdk = 34
            defaultConfig {
            }
        }
    }
    plugins.withId("com.android.library") {
        configure<com.android.build.api.dsl.LibraryExtension> {
            compileSdk = 34
            defaultConfig {
            }
        }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
