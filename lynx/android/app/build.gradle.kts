plugins {
    id("com.android.application")
}

val lynxVersion = "4.1.0"
val primjsVersion = "4.1.1"

android {
    namespace = "com.mdnotes.lynx"
    compileSdk = 35

    defaultConfig {
        applicationId = "com.mdnotes.lynx"
        minSdk = 24
        targetSdk = 35
        versionCode = 1
        versionName = "1.0"
    }

    buildTypes {
        release {
            isMinifyEnabled = false
            proguardFiles(getDefaultProguardFile("proguard-android-optimize.txt"), "proguard-rules.pro")
            // No release keystore in the repo: sign with the debug key so the
            // release APK can be installed on emulators/devices directly.
            signingConfig = signingConfigs.getByName("debug")
        }
    }
    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }
}

// Embed the production Lynx bundle (built by `npm run build` in lynx/) as an asset.
val copyLynxBundle by tasks.registering(Copy::class) {
    val bundle = rootProject.file("../dist/main.lynx.bundle")
    doFirst {
        if (!bundle.exists()) throw GradleException("$bundle not found. Run 'npm run build' in lynx/ first.")
    }
    from(bundle)
    into(layout.projectDirectory.dir("src/main/assets"))
}
tasks.named("preBuild") { dependsOn(copyLynxBundle) }

dependencies {
    implementation("androidx.core:core:1.13.1")
    implementation("androidx.sqlite:sqlite-framework:2.4.0")
    // Lynx pulls androidx.vectordrawable 1.0.0 whose two artifacts share a
    // namespace, which AGP 9 rejects; newer versions fix that.
    implementation("androidx.vectordrawable:vectordrawable:1.2.0")
    implementation("androidx.vectordrawable:vectordrawable-animated:1.2.0")

    implementation("org.lynxsdk.lynx:lynx:$lynxVersion")
    implementation("org.lynxsdk.lynx:lynx-jssdk:$lynxVersion")
    implementation("org.lynxsdk.lynx:lynx-trace:$lynxVersion")
    implementation("org.lynxsdk.lynx:primjs:$primjsVersion")
    implementation("org.lynxsdk.lynx:lynx-service-log:$lynxVersion")
    // <input> / <textarea>
    implementation("org.lynxsdk.lynx:xelement:$lynxVersion")
    implementation("org.lynxsdk.lynx:xelement-input:$lynxVersion")
}
