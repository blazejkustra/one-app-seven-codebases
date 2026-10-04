#!/bin/bash
# usage: measure.sh <app> <bundle>
R="$(cd "$(dirname "$0")/../../.." && pwd)"
S="${TMPDIR:-/tmp}/mdnotes-device"
D="${DEVICE_ID:?set DEVICE_ID to the phone UDID from xcrun devicectl list devices}"
a=$1; b=$2; out=$R/results/device/$a; mkdir -p $out
xcrun devicectl device uninstall app --device $D $b > /dev/null 2>&1
ipa=$(ls $S/arch/$a-export/*.ipa)
xcrun devicectl device install app --device $D "$ipa" > $out/install.log 2>&1 || { echo "$a install failed"; exit 1; }
cd $S
for t in DeviceLaunch/testTimeToContent LaunchPerf/testLaunchMetric LaunchPerf/testLaunchToResponsive; do
  n=$(basename $t)
  sleep 10   # let the phone go idle
  TEST_RUNNER_TARGET_BUNDLE=$b TEST_RUNNER_RUNS=10 xcodebuild test-without-building -xctestrun $S/dd-harness/Build/Products/HarnessUITests_iphoneos26.5-arm64.xctestrun \
    -destination "id=$D" -only-testing:HarnessUITests/$t -resultBundlePath $S/xcresult/$a-$n.xcresult > $out/$n.log 2>&1
  echo "$a $n rc=$? $(grep -hE 'TTC_SUMMARY|measured \[' $out/$n.log | head -2)"
done
