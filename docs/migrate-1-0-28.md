# Migrate your Flutter application to version 1.0.28

Strating with version 1.0.28, this repository is now seperated in a pure dart (parse_server_sdk) and a flutter package (parse_server_sdk_flutter).
This was done in order to provide a dart package for the parse-server, while keeping maintainance simple.
You can find both packages in the package directory.

### 1. pubspec.yaml
In your projects pubspec.yaml at the dependencies section, you have to change
```
dependencies:
    parse_server_sdk: ^1.0.27
```
to
```
dependencies:
    parse_server_sdk_flutter: ^1.0.28
```
This is the current released version of the parse_server_sdk_flutter: [![pub package](https://img.shields.io/pub/v/parse_server_sdk_flutter.svg)](https://pub.dev/packages/parse_server_sdk_flutter)

### 2. imports
As the package name changed, you have to change
```
import 'package:parse_server_sdk/parse_server_sdk.dart';
```
 to  
```
import 'package:parse_server_sdk_flutter/parse_server_sdk.dart';
```
in every file.

It is recommended to do so by the replacement feature of your IDE.

### optional: provide app informations on web
As flutter web is now in beta, this SDK aims to be web compadible.
But there are some parts completly different on web. For example the wep-app cant determine it's name, version or packagename.
That's why you should provide this informations on web.
```dart
Parse().initialize(
    ...
    appName: kIsWeb ? "MyApplication" : null,
    appVersion: kIsWeb ? "Version 1" : null,
    appPackageName: kIsWeb ? "com.example.myapplication" : null,
);
``
