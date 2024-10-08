#!/bin/bash

set -e

echo "y" | "${ANDROID_HOME}/cmdline-tools/latest/bin/sdkmanager" --install 'system-images;android-29;google_apis;x86_64' --channel=3
echo "no" | "${ANDROID_HOME}/cmdline-tools/latest/bin/avdmanager" create avd -n test_android_emulator -k 'system-images;android-29;google_apis;x86_64' --force
ls "${ANDROID_HOME}/cmdline-tools/latest/bin/"

nohup "${ANDROID_HOME}/emulator/emulator" -partition-size 1024 -avd test_android_emulator -no-snapshot > /dev/null 2>&1 & {
    # shellcheck disable=SC2016
    "${ANDROID_HOME}/platform-tools/adb" wait-for-device shell 'while [[ -z $(getprop sys.boot_completed | tr -d '\''\r'\'') ]]; do sleep 1; done; input keyevent 82'
}
