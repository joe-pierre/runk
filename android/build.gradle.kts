allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

val newBuildDir: Directory = rootProject.layout.buildDirectory.dir("../../build").get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}
subprojects {
    project.evaluationDependsOn(":app")
}

// Certains plugins tiers (ex: isar_flutter_libs, non maintenu depuis Isar v3)
// ne déclarent pas de `namespace`, obligatoire depuis Android Gradle Plugin 8.
// On le déduit ici de leur AndroidManifest.xml plutôt que de patcher le
// paquet en cache (non versionné, écrasé à chaque réinstallation).
// `pluginManager.withPlugin` (plutôt que `afterEvaluate`) évite l'erreur
// "project already evaluated" liée à `evaluationDependsOn(":app")` ci-dessus.
// Voir DECISIONS.md.
// Certains plugins tiers (ex: receive_sharing_intent) ne déclarent ni cible
// Java ni cible Kotlin explicite : leur code Java compile alors en 1.8 par
// défaut tandis que leur code Kotlin compile avec le JDK utilisé par Gradle,
// ce qui produit une incohérence de cible JVM. On aligne tous les modules de
// plugins tiers sur la même cible que `android/app/build.gradle.kts`
// (Java 11) en passant par `android.compileOptions`, seule source que AGP
// respecte réellement pour la tâche `compileDebugJavaWithJavac`
// (configurer directement `tasks.withType<JavaCompile>` est écrasé par AGP).
// Le module :app garde sa propre configuration. Voir DECISIONS.md.
subprojects {
    pluginManager.withPlugin("com.android.library") {
        val androidExtension = extensions.getByName("android") as com.android.build.gradle.LibraryExtension

        if (androidExtension.namespace == null) {
            val manifestFile = file("src/main/AndroidManifest.xml")
            if (manifestFile.exists()) {
                val packageName = Regex("package=\"([^\"]+)\"")
                    .find(manifestFile.readText())
                    ?.groupValues
                    ?.get(1)
                if (packageName != null) {
                    androidExtension.namespace = packageName
                }
            }
        }

        androidExtension.compileOptions.sourceCompatibility = JavaVersion.VERSION_11
        androidExtension.compileOptions.targetCompatibility = JavaVersion.VERSION_11
    }

    if (project.name != "app") {
        tasks.withType<org.jetbrains.kotlin.gradle.tasks.KotlinCompile>().configureEach {
            compilerOptions {
                jvmTarget.set(org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_11)
            }
        }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
