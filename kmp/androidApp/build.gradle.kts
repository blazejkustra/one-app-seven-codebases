plugins {
    alias(libs.plugins.androidApplication)
}

android {
    namespace = "com.mdnotes.kmp.android"
    compileSdk = 37

    defaultConfig {
        applicationId = "com.mdnotes.kmp"
        minSdk = 26
        targetSdk = 36
        versionCode = 1
        versionName = "1.0"
    }

    buildTypes {
        release {
            isMinifyEnabled = false
            // No production keystore in the repo: sign with the local debug key so the
            // release APK is installable. Replace with a real signingConfig for store builds.
            signingConfig = signingConfigs.getByName("debug")
        }
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }
}

dependencies {
    implementation(projects.shared)
    implementation(libs.androidx.activity.compose)
}
