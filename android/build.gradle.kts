allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

val newBuildDir = rootProject.buildDir.resolve("../../build")

subprojects {
    buildDir = newBuildDir.resolve(project.name)
}

subprojects {
    evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.buildDir)
}
