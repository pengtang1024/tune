allprojects {
    repositories {
        google()
        mavenCentral()
    }

    subprojects {
        afterEvaluate {
            if (project.name == "on_audio_query_android") {
                project.extensions.configure<com.android.build.gradle.LibraryExtension> {
                    namespace = "com.lucasjosino.on_audio_query"

                    compileOptions {
                        sourceCompatibility = JavaVersion.VERSION_1_8
                        targetCompatibility = JavaVersion.VERSION_1_8
                    }
                }
            }
            
            // 添加flutter_app_badger的配置（如果存在）
            if (project.name == "flutter_app_badger") {
                project.extensions.configure<com.android.build.gradle.LibraryExtension> {
                    namespace = "fr.g123k.flutterappbadge.flutterappbadger"

                    compileOptions {
                        sourceCompatibility = JavaVersion.VERSION_1_8
                        targetCompatibility = JavaVersion.VERSION_1_8
                    }
                }
            }
        }
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

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}