// Top-level build file where you can add configuration options common to all sub-projects/modules.

plugins {
    id("com.android.application") version "8.7.0" apply false
    id("com.google.gms.google-services") version "4.3.15" apply false
}

buildscript {
    repositories {
        google()
        mavenCentral()
        maven { url = uri("https://maven.google.com") }
        maven { url = uri("https://jitpack.io") } // Optional, only if you use JitPack
    }

    dependencies {
        classpath("com.android.tools.build:gradle:8.3.0")
        classpath("com.google.gms:google-services:4.3.15")
        classpath("com.google.firebase:perf-plugin:1.4.2") // Latest version
        classpath("com.google.firebase:perf-plugin:1.4.2")
    }
}

// Optional: Set a custom global build directory
val newBuildDir = rootProject.layout.buildDirectory.dir("../../build").get()
rootProject.layout.buildDirectory.set(newBuildDir)

// Set build dir for all subprojects
subprojects {
    project.evaluationDependsOn(":app")

    val subprojectBuildDir = newBuildDir.dir(project.name)
    project.layout.buildDirectory.set(subprojectBuildDir)
}

// Define clean task to remove build directory
tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
