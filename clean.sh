#!/bin/zsh
flutter clean
cd ios
cp Podfile backupPodfile
rm -rf Pods .symlinks Flutter/Flutter.framework Flutter/Flutter.podspec Podfile pubspec.lock Podfile.lock ~/Library/Developer/Xcode/DerivedData
pod init
pod install
flutter pub get
mv backupPodfile Podfile
pod install
cd ..
