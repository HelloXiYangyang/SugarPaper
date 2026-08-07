/*
 * Copyright (C) 2026 HelloXiYangyang
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

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
    afterEvaluate {
        // Force Android library plugin modules to use the same compileSdk
        // as the app (some plugins default too low, e.g. flutter_webrtc
        // uses compileSdk 31 which cannot satisfy its androidx deps).
        extensions
            .findByType(com.android.build.gradle.BaseExtension::class.java)
            ?.apply {
                compileSdkVersion(36)
            }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
