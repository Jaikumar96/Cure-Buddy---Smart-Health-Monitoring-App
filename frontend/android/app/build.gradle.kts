import java.util.Properties
import java.io.FileInputStream
import java.io.File // Make sure File is imported if not already implicitly

// --- Start of Debugging Block ---
println("--- Gradle Script: build.gradle.kts in app module ---")
println("Root project dir (rootProject.projectDir): ${rootProject.projectDir.absolutePath}")
println("Current project (app module) dir (project.projectDir): ${project.projectDir.absolutePath}")
val parentOfAppModuleDir: File? = project.projectDir.parentFile // This should be the 'android' directory
println("Parent of app module (project.projectDir.parentFile): ${parentOfAppModuleDir?.absolutePath ?: "N/A"}")
// --- End of Debugging Block ---

val localProperties = Properties()

// Correct way to find local.properties in the 'android' directory
// when this script ('build.gradle.kts') is in 'android/app/'
val targetLocalPropertiesFile: File? = project.projectDir.parentFile?.resolve("local.properties")

println("Attempting to load properties from: ${targetLocalPropertiesFile?.absolutePath ?: "targetLocalPropertiesFile is null or path could not be resolved"}")

if (targetLocalPropertiesFile != null && targetLocalPropertiesFile.exists()) {
    try {
        FileInputStream(targetLocalPropertiesFile).use { fis ->
            localProperties.load(fis)
            println("Successfully loaded properties from: ${targetLocalPropertiesFile.absolutePath}")
        }
    } catch (e: Exception) {
        println("ERROR loading properties from ${targetLocalPropertiesFile.absolutePath}: ${e.message}")
    }
} else {
    // If targetLocalPropertiesFile is null or doesn't exist, let's try the old rootProject path as a last resort, just for logging
    val fallbackPath = rootProject.projectDir.resolve("local.properties") // This assumes rootProject.projectDir is 'android'
    println("WARNING: Target properties file does not exist or path was problematic: ${targetLocalPropertiesFile?.absolutePath ?: "Path was null"}")
    println("Fallback check for ${fallbackPath.absolutePath}: Exists? ${fallbackPath.exists()}")
}

val googleMapsApiKey: String = localProperties.getProperty("GOOGLE_MAPS_API_KEY_ANDROID") ?: run {
    println("WARNING: Property 'GOOGLE_MAPS_API_KEY_ANDROID' not found in loaded properties. Current loaded properties: ${localProperties.stringPropertyNames()}")
    "MISSING_API_KEY_IN_PROPERTIES_OBJECT"
}



plugins {
    id("com.android.application")
    id("org.jetbrains.kotlin.android")
    id("dev.flutter.flutter-gradle-plugin")
}

// ... (rest of your build.gradle.kts file remains the same) ...
android {
    namespace = "com.example.cure_buddy"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = "27.0.12077973"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_1_8
        targetCompatibility = JavaVersion.VERSION_1_8
    }

    kotlinOptions {
        jvmTarget = "1.8"
    }

    defaultConfig {
        applicationId = "com.example.cure_buddy"
        minSdk = 21
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        manifestPlaceholders["GOOGLE_MAPS_API_KEY_ANDROID"] = googleMapsApiKey
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    // ...
}