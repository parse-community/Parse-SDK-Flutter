# Migrate your Flutter application to version 2.0.0

Starting with version 2.0.0, this repository is now separated in a pure dart (parse_server_sdk) and a flutter package (parse_server_sdk_flutter).
This was done in order to provide a dart package for the parse-server, while keeping maintenance simple.
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
    parse_server_sdk_flutter: ^2.0.0
```
This is the current released version of the parse_server_sdk_flutter package: [![pub package](https://img.shields.io/pub/v/parse_server_sdk_flutter.svg)](https://pub.dev/packages/parse_server_sdk_flutter)

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

### optional: provide app information on web
As flutter web is now in beta, this SDK aims to be web compatible.
But there are some parts completely different on web. For example, the wep-app cant determine it's name, version or packagename.
That's why you should provide this information on web.
```dart
Parse().initialize(
    ...
    appName: kIsWeb ? "MyApplication" : null,
    appVersion: kIsWeb ? "Version 1" : null,
    appPackageName: kIsWeb ? "com.example.myapplication" : null,
);
```

### optional: adjust your tests
You tests might fail if the package tries to automatically discover facts like you applications name, version, package name or the default file directory.
You can avoid this automatic discovery by providing values for `appName`, `appVersion`, `appPackageName` as well as `fileDirectory` at you `Parse().initialize()` call.

### changed network library
In order to provide a `ProgressCallback` for heavy file operations,
the network library was switched from [http](https://pub.dev/packages/http) to [dio](https://pub.dev/packages/dio).
There should be no breaking changes regarding this change, except if you are overriding the `ParseHTTPClient`.