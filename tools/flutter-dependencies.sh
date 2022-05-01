#!/bin/sh
# This scrip installs the dependencies of the flutter package.
# parse_server_sdk is set to the relative path.

cd packages/dart
flutter pub get
cd ../..
cd packages/flutter
flutter pub remove parse_server_sdk
flutter pub add parse_server_sdk --path ../dart
flutter pub get
