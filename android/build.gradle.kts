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

// Certains plugins tiers (ex: receive_sharing_intent) ne déclarent ni cible
// Java ni cible Kotlin explicite : leur code Java compile alors en 1.8 par
// défaut tandis que leur code Kotlin compile avec le JDK utilisé par Gradle,
// ce qui produit une incohérence de cible JVM. On aligne tous les modules de
// plugins tiers sur la même cible que `android/app/build.gradle.kts`
// (Java 11). Le module :app garde sa propre configuration.
// Migration isar_community (voir DECISIONS.md) : le correctif de `namespace`
// manquant n'est plus nécessaire, `isar_community_flutter_libs` déclare le
// sien — vérifié empiriquement, patch retiré. Celui-ci reste requis
// uniquement à cause de `receive_sharing_intent`, sans lien avec Isar.
subprojects {
    pluginManager.withPlugin("com.android.library") {
        val androidExtension = extensions.getByName("android") as com.android.build.gradle.LibraryExtension
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
