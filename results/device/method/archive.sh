#!/bin/bash
# usage: archive.sh <app>
set -o pipefail
R="$(cd "$(dirname "$0")/../../.." && pwd)"
S="${TMPDIR:-/tmp}/mdnotes-device"
a=$1; out=$R/results/device/$a; mkdir -p $out
SIGN=(DEVELOPMENT_TEAM=${TEAM_ID:?set TEAM_ID to your Apple team id} CODE_SIGN_STYLE=Automatic CODE_SIGN_IDENTITY="Apple Development" -allowProvisioningUpdates)
case $a in
 swift) cd $R/swift; SRC=(-project MarkdownNotes.xcodeproj -scheme MarkdownNotes -disableAutomaticPackageResolution);;
 react-native) cd $R/react-native; SRC=(-workspace ios/MarkdownNotes.xcworkspace -scheme MarkdownNotes);;
 flutter) cd $R/flutter; flutter build ios --release --no-codesign > $out/flutter-build.log 2>&1 || exit 1; SRC=(-workspace ios/Runner.xcworkspace -scheme Runner);;
 kmp) cd $R/kmp; export JAVA_HOME="$(/usr/libexec/java_home -v 17)"; SRC=(-project iosApp/iosApp.xcodeproj -scheme iosApp);;
 angular-native) cd $R/angular-native; SRC=(-workspace ios/MarkdownNotes.xcworkspace -scheme MarkdownNotes);;
 lynx) cd $R/lynx; npm run build > $out/lynx-bundle.log 2>&1 || exit 1; SRC=(-workspace ios/MarkdownNotes.xcworkspace -scheme MarkdownNotes);;
esac
rm -rf $S/$a.xcarchive $S/$a-export
xcodebuild archive "${SRC[@]}" -configuration Release -destination 'generic/platform=iOS' \
  -derivedDataPath $S/dd-$a -archivePath $S/$a.xcarchive "${SIGN[@]}" > $out/archive.log 2>&1 || { echo "$a archive FAILED"; tail -30 $out/archive.log | grep -E 'error|FAIL'; exit 1; }
cat > $S/export.plist <<P
<?xml version="1.0" encoding="UTF-8"?><!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict><key>method</key><string>debugging</string><key>teamID</key><string>${TEAM_ID:?set TEAM_ID to your Apple team id}</string>
<key>signingStyle</key><string>automatic</string><key>thinning</key><string>iPhone17,3</string>
<key>compileBitcode</key><false/><key>stripSwiftSymbols</key><true/></dict></plist>
P
xcodebuild -exportArchive -archivePath $S/$a.xcarchive -exportPath $S/$a-export -exportOptionsPlist $S/export.plist -allowProvisioningUpdates > $out/export.log 2>&1 || { echo "$a export FAILED"; tail -20 $out/export.log; exit 1; }
cp "$S/$a-export/App Thinning Size Report.txt" $out/ 2>/dev/null
echo "$a OK"; ls $S/$a-export
