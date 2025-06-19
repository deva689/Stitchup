import java.util.Properties
import java.io.FileInputStream

plugins {
    id("com.android.application")
    id("kotlin-android")
    id("com.google.gms.google-services") // Firebase
    id("dev.flutter.flutter-gradle-plugin") // Flutter
}

// ✅ Load keystore for signing
val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

android {
    // ❌ Remove duplicate 'namespace' - only keep one!
    namespace = "com.stitchup.dartnew" // ✅ your real package

    compileSdk = 35
    ndkVersion = "27.0.12077973"

    defaultConfig {
        applicationId = "com.stitchup.dartnew"
        minSdk = 24
        targetSdk = 34 // ✅ use stable target (or flutter.targetSdkVersion if dynamic)
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        multiDexEnabled = true
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
        isCoreLibraryDesugaringEnabled = true
    }

    kotlinOptions {
        jvmTarget = "11"
    }

    // ✅ Split APKs per ABI (works now)
   

    signingConfigs {
    create("release") {
        storeFile = file(keystoreProperties["storeFile"] as String)
        storePassword = keystoreProperties["storePassword"] as String
        keyAlias = keystoreProperties["keyAlias"] as String
        keyPassword = keystoreProperties["keyPassword"] as String
    }
}


    buildTypes {
        getByName("release") {
            signingConfig = signingConfigs.getByName("release")
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
        }
    }
}

dependencies {
    // ✅ Firebase (only necessary modules)
    implementation(platform("com.google.firebase:firebase-bom:33.12.0"))
    implementation("com.google.firebase:firebase-auth-ktx")
    implementation("com.google.firebase:firebase-firestore-ktx")
    implementation("com.google.firebase:firebase-storage-ktx")

    // ✅ Multidex support
    implementation("androidx.multidex:multidex:2.0.1")

    // ✅ Required for Java 8+ features
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}
