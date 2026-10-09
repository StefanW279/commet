PROJECT_PATH="$(git rev-parse --show-toplevel)/commet/"
PATH="$PROJECT_PATH/../.fvm/flutter_sdk/bin/:$PATH"

export ANDROID_HOME=$HOME/Android/Sdk
export ANDROID_SDK_ROOT=$HOME/Android/Sdk

cd $PROJECT_PATH
git apply scripts/apply_google_services.patch

cd $PROJECT_PATH
dart run scripts/codegen.dart

cd $PROJECT_PATH
dart run scripts/build_release.dart --platform android --version_tag 'v0.0.0-artifact' --enable_google_services true --build_detail google_services ## this requires a signing key, located at commet/android/key.jks, as well as a key.properties, which can be made using the included key.properties.example

cd $PROJECT_PATH
git apply -R scripts/apply_google_services.patch
git checkout ../pubspec.lock windows/flutter/generated_plugin_registrant.cc windows/flutter/generated_plugins.cmake macos/Flutter/GeneratedPluginRegistrant.swift

cd $PROJECT_PATH
mkdir -p $PROJECT_PATH/build/output
cp $PROJECT_PATH/build/app/outputs/flutter-apk/app-release.apk $PROJECT_PATH/build/output/commet-android-google-services.apk
cd $PROJECT_PATH/build/output/
echo "Output file is present in now ${PROJECT_PATH}build/output directory"
ls
