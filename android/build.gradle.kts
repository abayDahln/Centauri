allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

val newBuildDir: Directory =
    rootProject.layout.buildDirectory
        .dir("../../build")
        .get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}
subprojects {
    project.evaluationDependsOn(":app")
}

// Plugin lama (mis. irondash_engine_context) mengunci compileSdk 31 sementara
// dependensi androidx-nya menuntut >= 34; samakan semua subprojek ke 36.
subprojects {
    if (name == "app") return@subprojects
    afterEvaluate {
        extensions.findByName("android")?.let { android ->
            val setter =
                android.javaClass.methods.firstOrNull {
                    it.name == "setCompileSdk" && it.parameterTypes.size == 1
                }
            setter?.invoke(android, 36)
        }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
