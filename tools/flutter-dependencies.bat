call flutter config --no-analytics
cd packages/dart
call flutter pub get
cd ../..
cd packages/flutter
call flutter pub remove parse_server_sdk
call flutter pub add parse_server_sdk --path ../dart
call flutter pub get