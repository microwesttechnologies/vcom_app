allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

val externalBuildRoot = File(
    System.getenv("LOCALAPPDATA") ?: System.getProperty("java.io.tmpdir"),
    "vcom_app_build",
)
rootProject.layout.buildDirectory.set(externalBuildRoot)

subprojects {
    project.layout.buildDirectory.set(File(externalBuildRoot, project.name))
}
subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(externalBuildRoot)
}
