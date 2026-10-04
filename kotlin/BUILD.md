# Markdown Notes — Kotlin / Jetpack Compose (Android)

Native Android app (`com.mdnotes.kotlin`), Gradle project in this directory.
Requirements: JDK 17 and the Android SDK (platform `android-37.0`, build-tools 36). Gradle itself
comes from the checked-in wrapper; all library versions are pinned in `gradle/libs.versions.toml`
and locked in `*.lockfile` (Gradle dependency locking).

All commands are run from the repository root.

## (a) Install dependencies

```sh
cd kotlin
export JAVA_HOME="$(/usr/libexec/java_home -v 17)"
export ANDROID_HOME="${ANDROID_HOME:-$HOME/Library/Android/sdk}"
echo "sdk.dir=$ANDROID_HOME" > local.properties
./gradlew --no-daemon --console=plain :app:dependencies --configuration releaseRuntimeClasspath > /dev/null
./gradlew --no-daemon --console=plain :app:compileReleaseKotlin -q
```

(The second command downloads the Android Gradle Plugin, Kotlin, KSP/Room compiler and every
library in the lockfiles; the first just resolves the runtime graph.)

## (b) Build the release APK and print its path

```sh
cd kotlin
export JAVA_HOME="$(/usr/libexec/java_home -v 17)"
export ANDROID_HOME="${ANDROID_HOME:-$HOME/Library/Android/sdk}"
./gradlew --no-daemon --console=plain :app:assembleRelease -q
ls "$PWD/app/build/outputs/apk/release/app-release.apk"
```

The release APK is minified (R8), signed with the local debug key, and fully self-contained. Install it with:

```sh
adb -s emulator-5554 install -r kotlin/app/build/outputs/apk/release/app-release.apk
adb -s emulator-5554 shell am start -n com.mdnotes.kotlin/.MainActivity
```

## Other tasks

```sh
./gradlew --no-daemon :app:testDebugUnitTest   # unit tests (title/snippet/date, markdown parsing)
./gradlew --no-daemon :app:lintRelease          # Android lint
# after changing a dependency version, refresh the lockfiles:
./gradlew --no-daemon assembleRelease assembleDebug testDebugUnitTest lintRelease --write-locks
```
