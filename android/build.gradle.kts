allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

rootProject.buildDir = '../build'
subprojects {
    project.buildDir = "${rootProject.buildDir}/${project.name}"
}
subprojects {
    project.evaluationDependsOn(':app')
}

// OFFICIAL FORCED SDK OVERRIDE (Bina kisi syntax error ke sabhi plugins ko patch karne ka standard tarika)
subprojects {
    afterEvaluate { project ->
        if (project.hasProperty('android')) {
            project.android {
                if (namespace == null) {
                    // Agar koi purana plugin bina namespace ke ho
                }
                compileSdkVersion 36
                defaultConfig {
                    targetSdkVersion 36
                }
            }
        }
    }
}

tasks.register("clean", Delete) {
    delete rootProject.buildDir
}
