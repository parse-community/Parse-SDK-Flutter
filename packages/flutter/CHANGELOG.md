# [flutter-v10.3.0](https://github.com/parse-community/Parse-SDK-Flutter/compare/flutter-10.2.0...flutter-10.3.0) (2025-11-30)


### Features

* Bump package_info_plus from 5.0.1 to 9.0.0 in /packages/flutter ([#1060](https://github.com/parse-community/Parse-SDK-Flutter/issues/1060)) ([2b3e63c](https://github.com/parse-community/Parse-SDK-Flutter/commit/2b3e63cdb5ddb3b5de5dfb830db8c72ccfffdb84))

# [10.3.0](https://github.com/parse-community/Parse-SDK-Flutter/compare/flutter-10.2.0...flutter-10.3.0) (2025-11-30)


### Features

* Bump package_info_plus from 5.0.1 to 9.0.0 in /packages/flutter ([#1060](https://github.com/parse-community/Parse-SDK-Flutter/issues/1060)) ([2b3e63c](https://github.com/parse-community/Parse-SDK-Flutter/commit/2b3e63cdb5ddb3b5de5dfb830db8c72ccfffdb84))


# [10.2.0](https://github.com/parse-community/Parse-SDK-Flutter/compare/flutter-10.1.0...flutter-10.2.0) (2025-11-29)


### Features

* Bump web_socket_channel from 2.4.5 to 3.0.3 in /packages/dart ([#1064](https://github.com/parse-community/Parse-SDK-Flutter/issues/1064)) ([5b6aacf](https://github.com/parse-community/Parse-SDK-Flutter/commit/5b6aacf64457ccbf1c121a36204fcb51be6a6682))

# [10.1.0](https://github.com/parse-community/Parse-SDK-Flutter/compare/flutter-10.0.0...flutter-10.1.0) (2025-11-28)


### Features

* Bump timezone from 0.9.4 to 0.10.1 in /packages/dart ([#1063](https://github.com/parse-community/Parse-SDK-Flutter/issues/1063)) ([d3f2333](https://github.com/parse-community/Parse-SDK-Flutter/commit/d3f23338d5c8ca1e0239656814ac84818741f39d))

# [10.0.0](https://github.com/parse-community/Parse-SDK-Flutter/compare/flutter-9.0.0...flutter-10.0.0) (2025-11-28)


### Bug Fixes

* `ParseXFile` uploads file with content-type `application/octet-stream` if not explicitly set ([#1048](https://github.com/parse-community/Parse-SDK-Flutter/issues/1048)) ([a47f2a0](https://github.com/parse-community/Parse-SDK-Flutter/commit/a47f2a051fae92c44b974e1fd2f92b593a0139c6))
* Add support for Dart 3.4, 3.5; remove support for Dart 3.0, 3.1 ([#1016](https://github.com/parse-community/Parse-SDK-Flutter/issues/1016)) ([a3449f4](https://github.com/parse-community/Parse-SDK-Flutter/commit/a3449f4a1c4060f6afea71f50b204cb5e5a37bd2))
* HTTP client exception not handled properly resulting in incorrectly formatted error ([#1021](https://github.com/parse-community/Parse-SDK-Flutter/issues/1021)) ([4f20640](https://github.com/parse-community/Parse-SDK-Flutter/commit/4f2064096eb623a0af45a5aee60d8bfc0d882604))

### Features

* Add client access via `ParseDioClient.client` and `ParseHTTPClient.client` ([#1025](https://github.com/parse-community/Parse-SDK-Flutter/issues/1025)) ([af14388](https://github.com/parse-community/Parse-SDK-Flutter/commit/af1438820999af9740c1fe4b0a2e8a506e6222cf))
* Remove support for expired Dart and Flutter versions ([#1052](https://github.com/parse-community/Parse-SDK-Flutter/issues/1052)) ([dbeb5cb](https://github.com/parse-community/Parse-SDK-Flutter/commit/dbeb5cbdb7e14c6fac5cf51a90addb0872ca88f2))


### BREAKING CHANGES

* This release removes support for Dart 3.2 - 3.9 and Flutter 3.16 - 3.37. These versions exceeded their 6-month support window after the next significant version release. The minimum required versions are now Dart 3.10 and Flutter 3.38. ([dbeb5cb](dbeb5cb))

## [9.0.0](https://github.com/parse-community/Parse-SDK-Flutter/compare/flutter-8.0.0...flutter-9.0.0) (2024-10-16)

### BREAKING CHANGES

* This release removes support for Flutter 3.10, 3.13 ([#1014](https://github.com/parse-community/Parse-SDK-Flutter/pull/1014))

### Features

* Add support for Flutter 3.22, 3.24; remove support for Flutter 3.10, 3.13 ([#1014](https://github.com/parse-community/Parse-SDK-Flutter/pull/1014))

## [8.0.0](https://github.com/parse-community/Parse-SDK-Flutter/compare/flutter-7.0.0...flutter-8.0.0) (2024-05-15)

### BREAKING CHANGES

* This release removes support for Flutter 3.3, 3.7 ([#994](https://github.com/parse-community/Parse-SDK-Flutter/pull/994))

### Features

* Add support for Flutter 3.13, 3.16, 3.19; remove support for Flutter 3.3, 3.7 ([#994](https://github.com/parse-community/Parse-SDK-Flutter/pull/994))

## [7.0.1](https://github.com/parse-community/Parse-SDK-Flutter/compare/flutter-7.0.0...flutter-7.0.1) (2024-02-03)

### Bug Fixes

* Conflict with new version of `connectivity_plus` dependency ([#987](https://github.com/parse-community/Parse-SDK-Flutter/pull/987))

## [7.0.0](https://github.com/parse-community/Parse-SDK-Flutter/compare/flutter-6.0.0...flutter-7.0.0) (2023-10-16)

### BREAKING CHANGES

* This release removes support for Flutter 3.0 ([#971](https://github.com/parse-community/Parse-SDK-Flutter/pull/971))

### Features

* Add support for Flutter 3.10 and 3.13, remove support for Flutter 3.0 ([#971](https://github.com/parse-community/Parse-SDK-Flutter/pull/971))

## [6.0.0](https://github.com/parse-community/Parse-SDK-Flutter/compare/flutter-5.1.2...flutter-6.0.0) (2023-08-06)

### BREAKING CHANGES

* The push notification library flutter_local_notifications is replaced with the new push notification interface `ParseNotification` ([#949](https://github.com/parse-community/Parse-SDK-Flutter/pull/949))

### Features

* Add new new push notification interface `ParseNotification` for managing push notifications ([#949](https://github.com/parse-community/Parse-SDK-Flutter/pull/949))

## [5.1.2](https://github.com/parse-community/Parse-SDK-Flutter/compare/flutter-5.1.1...flutter-5.1.2) (2023-07-11)

### Bug Fixes

* Building web app fails because `dbDirectory` does not exist in `core_store_directory_web` ([#948](https://github.com/parse-community/Parse-SDK-Flutter/pull/948))

## [5.1.1](https://github.com/parse-community/Parse-SDK-Flutter/compare/flutter-5.1.0...flutter-5.1.1) (2023-06-28)

### Bug Fixes

* Push notifications in iOS not working; this changes the dependency in `ParseNotification` from `awesome_notifications` to `flutter_local_notifications` ([#940](https://github.com/parse-community/Parse-SDK-Flutter/pull/940))

## [5.1.0](https://github.com/parse-community/Parse-SDK-Flutter/compare/flutter-5.0.1...flutter-5.1.0) (2023-05-22)

### Features

* Add support for push notifications via `ParsePush`, `ParseNotification` ([#914](https://github.com/parse-community/Parse-SDK-Flutter/pull/914))

## [5.0.1](https://github.com/parse-community/Parse-SDK-Flutter/compare/flutter-5.0.0...flutter-5.0.1) (2023-05-20)

### Bug Fixes

* Attributes `reverse`, `padding`, `physics`, `controller`, `scrollDirection`, `shrinkWrap` not implemented in `ParseLiveGridWidget` ([#761](https://github.com/parse-community/Parse-SDK-Flutter/pull/761))

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
