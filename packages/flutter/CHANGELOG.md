## [5.0.0](https://github.com/parse-community/Parse-SDK-Flutter/compare/flutter-4.0.0...flutter-5.0.0) (2023-05-14)

### BREAKING CHANGES

* The minimum required Dart SDK version is 2.18.0. ([#867](https://github.com/parse-community/Parse-SDK-Flutter/pull/867))
* Upgrades the dependency `parse_server_sdk` to `5.x.x`. ([#868](https://github.com/parse-community/Parse-SDK-Flutter/pull/868))
* The deprecated parameter `vsync` from `AnimatedSize` is removed. ([#864](https://github.com/parse-community/Parse-SDK-Flutter/pull/864))

### Features

* Upgrade `parse_server_sdk` to `5.x.x` ([#868](https://github.com/parse-community/Parse-SDK-Flutter/pull/868))

### Bug Fixes

* Incorrect Dart and Flutter SDKs compatibility range ([#867](https://github.com/parse-community/Parse-SDK-Flutter/pull/867))
* Remove deprecated parameter `vsync` from `AnimatedSize` ([#864](https://github.com/parse-community/Parse-SDK-Flutter/pull/864))

## [4.0.0](https://github.com/parse-community/Parse-SDK-Flutter/compare/flutter-3.1.4...flutter-4.0.0) (2023-03-19)

### BREAKING CHANGES

* The source file name of the Flutter package has changed; to import the Flutter package use `parse_server_sdk_flutter.dart` instead of `parse_server_sdk.dart` ([#846](https://github.com/parse-community/Parse-SDK-Flutter/pull/846))
* Dependencies are upgraded to `parse_server_sdk` 4.x, `dio` 5.x, `connectivity_plus` 3.x and `package_info_plus` 3.x ([#844](https://github.com/parse-community/Parse-SDK-Flutter/pull/844))

### Features

* Rename Flutter package source file to `parse_server_sdk_flutter.dart` ([#846](https://github.com/parse-community/Parse-SDK-Flutter/pull/846))
* Upgrade various dependencies and fix warnings in Flutter package ([#844](https://github.com/parse-community/Parse-SDK-Flutter/pull/844))

## [3.1.4](https://github.com/parse-community/Parse-SDK-Flutter/compare/flutter-3.1.3...flutter-3.1.4) (2023-03-01)

### Bug Fixes

* Parse SDK internal database file `parse.db` is accessible for app user on iOS and may be accidentally deleted ([#826](https://github.com/parse-community/Parse-SDK-Flutter/pull/826))

## [3.1.3](https://github.com/parse-community/Parse-SDK-Flutter/compare/flutter-3.1.2...flutter-3.1.3) (2022-07-09)

### Bug Fixes

* old version of `connectivity_plus package` ([#717](https://github.com/parse-community/Parse-SDK-Flutter/issues/717))
* dependency `package_info_plus` does not work in web ([#714](https://github.com/parse-community/Parse-SDK-Flutter/issues/714))
* missing plugin exception, no implementation found for method `getAll` ([#712](https://github.com/parse-community/Parse-SDK-Flutter/issues/712))

## [3.1.2](https://github.com/parse-community/Parse-SDK-Flutter/compare/flutter-3.1.1...flutter-3.1.2) (2022-05-30)

### Refactors

* fix analyzer code style warnings ([#733](https://github.com/parse-community/Parse-SDK-Flutter/issues/733))

## [3.1.1](https://github.com/parse-community/Parse-SDK-Flutter/compare/V3.1.0...flutter-3.1.1) (2022-05-29)

### Bug Fixes

* update example app to use Android embedding v2 ([#722](https://github.com/parse-community/Parse-SDK-Flutter/issues/722)) ([e092189](https://github.com/parse-community/Parse-SDK-Flutter/commit/e092189cb666c25b3e2c9dbbf95316e9cfa88e72))

# [3.1.0](https://github.com/parse-community/Parse-SDK-Flutter/compare/V3.0.0...V3.1.0) (2021-06-28)

### Bug Fixes

* General improvements
* Updated dependencies

# [3.0.0](https://github.com/parse-community/Parse-SDK-Flutter/compare/2.1.0...V3.0.0) (2021-04-14)

### Bug Fixes

* Stable null safety release

# [2.1.0](https://github.com/parse-community/Parse-SDK-Flutter/compare/2.0.1...2.1.0) (2021-02-18)

### BREAKING CHANGES

* Changed to HTTP method POST for login
* Change in progress callback for file upload

### Features

* Option to use `ParseHTTPClient` (default) or `ParseDioClient` (slow on Flutter Web)
* Added method excludeKeys to exclude specific fields from the returned query

### Bug Fixes

* General improvements
* Updated dependencies

## [2.0.1](https://github.com/parse-community/Parse-SDK-Flutter/compare/2.0.0...2.0.1) (2020-10-24)

### Bug Fixes

* Fixed network exceptions ([#482](https://github.com/parse-community/Parse-SDK-Flutter/pull/482))

## [2.0.0](https://github.com/parse-community/Parse-SDK-Flutter/compare/1.0.28...2.0.0) (2020-10-13)

First official release. From this release onwards the previous repository has been separated into a pure dart (parse_server_sdk) and a flutter package (parse_server_sdk_flutter). This was done in order to provide a dart package for the parse-server, while keeping maintenance simple. You can find both packages in the package directory.
