allprojects {
    repositories {
        google()
        maven("https://cache-redirector.jetbrains.com/maven-central")
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

subprojects {
    tasks.matching { it.name.contains("Kotlin") }.configureEach {
        try {
            val options = property("kotlinOptions")
            val getArgs = options?.javaClass?.getMethod("getFreeCompilerArgs")
            val setArgs = options?.javaClass?.getMethod("setFreeCompilerArgs", List::class.java)
            if (options != null && getArgs != null && setArgs != null) {
                @Suppress("UNCHECKED_CAST")
                val current = (getArgs.invoke(options) as? List<String>) ?: emptyList()
                setArgs.invoke(options, current + "-Xskip-metadata-version-check")
            }
        } catch (_: Exception) {}
    }
}
tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
