import org.gradle.api.JavaVersion
import java.util.Properties
import java.io.FileInputStream

// Load local.properties (Flutter paths) and key.properties (signing) if present
val localProperties = Properties().apply {
    val f = rootProject.file("android/local.properties")
    if (f.exists()) load(FileInputStream(f))
}

val keystoreProps = Properties().apply {
    val f = rootProject.file("android/key.properties")
    if (f.exists()) load(FileInputStream(f))
}

plugins {
    id("com.android.application")
    id("org.jetbrains.kotlin.android")
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services")
}

android {
    namespace = "com.mywishstash.app"
    compileSdk = 36
    ndkVersion = "27.0.12077973"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
        isCoreLibraryDesugaringEnabled = true
    }

    kotlinOptions {
        jvmTarget = "17"
    }

    defaultConfig {
    applicationId = "com.mywishstash.app"
        minSdkVersion(24)
        targetSdk = 36
    // versionName / versionCode: derive from pubspec.yaml (e.g. 0.1.2+3)
    // This ensures the generated APK manifest contains a versionCode and versionName.
    val pubspecFile = rootProject.file("../pubspec.yaml")
    if (pubspecFile.exists()) {
        val pubspecText = pubspecFile.readText()
        // match lines like: version: 0.1.2+3
        val versionRegex = Regex("version\\s*:\\s*([0-9]+(?:\\.[0-9]+)*(?:\\+[0-9]+)?)")
        val match = versionRegex.find(pubspecText)
        if (match != null) {
            val versionFull = match.groupValues[1]
            val parts = versionFull.split('+')
            versionName = parts[0]
            versionCode = parts.getOrNull(1)?.toIntOrNull() ?: 1
        } else {
            versionName = "0.0.0"
            versionCode = 1
        }
    } else {
        versionName = "0.0.0"
        versionCode = 1
    }
    }

    signingConfigs {
        // Release signing will be configured via android/key.properties (NOT committed)
        create("release") {
            if (keystoreProps.isNotEmpty()) {
                storeFile = keystoreProps["storeFile"]?.let { file(it as String) }
                storePassword = keystoreProps["storePassword"] as String?
                keyAlias = keystoreProps["keyAlias"] as String?
                keyPassword = keystoreProps["keyPassword"] as String?
            }
        }
    }

    buildTypes {
        release {
            // Quando keystore existir, assinar com release; fallback para debug se vazio (evita quebra CI local)
            signingConfig = if (keystoreProps.isNotEmpty()) signingConfigs.getByName("release") else signingConfigs.getByName("debug")
            // Habilitar otimizações gradualmente: primeiro só minify sem shrink para validar crash-free
            isMinifyEnabled = false // (ajustar para true depois de validar)
            isShrinkResources = false // (ativar após minify funcionar)
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
        }
        debug {
            // Garantir identicação clara em logs se necessário (placeholder para possivel applicationIdSuffix)
        }
    }
}

flutter {
    source = "../.."
}

// Adicione este bloco para garantir o toolchain Kotlin correto (JVM 17)
kotlin {
    jvmToolchain(17)
}

dependencies {
    // Bumped to >=2.1.4 to satisfy flutter_local_notifications AAR metadata requirement
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
    // Firebase BoM para controlar versões
    implementation(platform("com.google.firebase:firebase-bom:34.0.0"))
    implementation("com.google.firebase:firebase-analytics")
    // Adicione outras dependências Firebase conforme preciso
}

repositories {
    google()
    mavenCentral()
}