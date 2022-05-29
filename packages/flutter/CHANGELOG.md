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
