#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
flutter create --org lt.cloudgames --project-name cloudgames_control --platforms android,ios . >/dev/null
rm -rf test
M=android/app/src/main/AndroidManifest.xml
grep -q 'android.permission.INTERNET' "$M" || sed -i 's#<application#<uses-permission android:name="android.permission.INTERNET"/>\n    <uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>\n    <application#' "$M"
sed -i -E 's#android:label="[^"]*"#android:label="CG Control"#' "$M"
G=android/app/build.gradle.kts; [ -f "$G" ] || G=android/app/build.gradle
grep -q 'lt.cloudgames.cloudgames_control' "$G" || { echo "KLAIDA: netikėtas Android applicationId (turi būti lt.cloudgames.cloudgames_control, kaip Firebase)"; exit 1; }
sed -i -E 's/minSdk = flutter\.minSdkVersion/minSdk = maxOf(flutter.minSdkVersion, 23)/; s/minSdkVersion flutter\.minSdkVersion/minSdkVersion Math.max(flutter.minSdkVersion, 23)/' "$G"
if [ -f ios/Runner.xcodeproj/project.pbxproj ]; then
  sed -i -E '/RunnerTests;/s/PRODUCT_BUNDLE_IDENTIFIER = [^;]*;/PRODUCT_BUNDLE_IDENTIFIER = lt.cloudgames.control.RunnerTests;/; /RunnerTests;/!s/PRODUCT_BUNDLE_IDENTIFIER = [^;]*;/PRODUCT_BUNDLE_IDENTIFIER = lt.cloudgames.control;/' ios/Runner.xcodeproj/project.pbxproj
fi
if [ -n "${LOW_MEM:-}" ]; then
  P=android/gradle.properties
  sed -i '/org.gradle.jvmargs/d;/org.gradle.workers.max/d;/kotlin.daemon.jvmargs/d' "$P"
  printf '\norg.gradle.jvmargs=-Xmx1600m -XX:MaxMetaspaceSize=512m\norg.gradle.workers.max=1\nkotlin.daemon.jvmargs=-Xmx700m\n' >> "$P"
fi
flutter pub get
dart run flutter_launcher_icons >/dev/null 2>&1 || echo "Ikonėlė nesugeneruota – bus standartinė"
