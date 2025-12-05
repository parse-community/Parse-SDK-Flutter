# [dart-v9.4.7](https://github.com/parse-community/Parse-SDK-Flutter/compare/dart-9.4.6...dart-9.4.7) (2025-12-05)


### Bug Fixes

* `ParseLiveList.getAt()` causes unnecessary requests to server ([#1099](https://github.com/parse-community/Parse-SDK-Flutter/issues/1099)) ([9114d4a](https://github.com/parse-community/Parse-SDK-Flutter/commit/9114d4ae98a5d34a301e04d0f62686cfaf99390c))

# [dart-v9.4.6](https://github.com/parse-community/Parse-SDK-Flutter/compare/dart-9.4.5...dart-9.4.6) (2025-12-04)


### Bug Fixes

* TypeError on `addRelation` function ([#1098](https://github.com/parse-community/Parse-SDK-Flutter/issues/1098)) ([f284944](https://github.com/parse-community/Parse-SDK-Flutter/commit/f2849442f71ebf311bf10d01e967a7612ba66fe4))

# [dart-v9.4.5](https://github.com/parse-community/Parse-SDK-Flutter/compare/dart-9.4.4...dart-9.4.5) (2025-12-04)


### Bug Fixes

* Incompatible `parseIsWeb` detection prevents WASM support ([#1096](https://github.com/parse-community/Parse-SDK-Flutter/issues/1096)) ([5b157b8](https://github.com/parse-community/Parse-SDK-Flutter/commit/5b157b897339634ecc2d0f66e3b3de612a243ea3))

# [dart-v9.4.4](https://github.com/parse-community/Parse-SDK-Flutter/compare/dart-9.4.3...dart-9.4.4) (2025-12-04)


### Bug Fixes

* `ParseBase.toJson()` failure when date fields are stored as Maps ([#1094](https://github.com/parse-community/Parse-SDK-Flutter/issues/1094)) ([04a8d5b](https://github.com/parse-community/Parse-SDK-Flutter/commit/04a8d5b6d3d811636ea1b54247e73871b25266d1))

# [dart-v9.4.3](https://github.com/parse-community/Parse-SDK-Flutter/compare/dart-9.4.2...dart-9.4.3) (2025-12-04)


### Bug Fixes

* Flutter Web build failure with ambiguous import from `sembast` and `idb_shim` ([#1093](https://github.com/parse-community/Parse-SDK-Flutter/issues/1093)) ([71aa5f2](https://github.com/parse-community/Parse-SDK-Flutter/commit/71aa5f20ab160a6113ac8167d66c540de11ff88f))

# [dart-v9.4.2](https://github.com/parse-community/Parse-SDK-Flutter/compare/dart-9.4.1...dart-9.4.2) (2025-12-02)


### Bug Fixes

* Ethernet not recognized as connectivity state ([#1090](https://github.com/parse-community/Parse-SDK-Flutter/issues/1090)) ([f76fde4](https://github.com/parse-community/Parse-SDK-Flutter/commit/f76fde4f348af5d3992663795d279d57658f4e87))

# [dart-v9.4.1](https://github.com/parse-community/Parse-SDK-Flutter/compare/dart-9.4.0...dart-9.4.1) (2025-11-30)


### Bug Fixes

* `ParseGeoPoint` longitude validation checks wrong variable ([#1089](https://github.com/parse-community/Parse-SDK-Flutter/issues/1089)) ([6b9ef6b](https://github.com/parse-community/Parse-SDK-Flutter/commit/6b9ef6b034741f6f829af3b7edf990f9915fb7fb))

# [9.4.0](https://github.com/parse-community/Parse-SDK-Flutter/compare/dart-9.3.0...dart-9.4.0) (2025-11-29)


### Features

* Bump lints from 4.0.0 to 6.0.0 in /packages/dart ([#1065](https://github.com/parse-community/Parse-SDK-Flutter/issues/1065)) ([3c58597](https://github.com/parse-community/Parse-SDK-Flutter/commit/3c58597d92fad8a25a1632c0bbd25ff48a2750f3))

# [9.3.0](https://github.com/parse-community/Parse-SDK-Flutter/compare/dart-9.2.0...dart-9.3.0) (2025-11-29)


### Features

* Bump mime from 1.0.6 to 2.0.0 in /packages/dart ([#1066](https://github.com/parse-community/Parse-SDK-Flutter/issues/1066)) ([2e143bf](https://github.com/parse-community/Parse-SDK-Flutter/commit/2e143bf08c71b768f922fbf33d1c6308e6667397))

# [9.2.0](https://github.com/parse-community/Parse-SDK-Flutter/compare/dart-9.1.0...dart-9.2.0) (2025-11-29)


### Features

* Bump web_socket_channel from 2.4.5 to 3.0.3 in /packages/dart ([#1064](https://github.com/parse-community/Parse-SDK-Flutter/issues/1064)) ([5b6aacf](https://github.com/parse-community/Parse-SDK-Flutter/commit/5b6aacf64457ccbf1c121a36204fcb51be6a6682))

# [9.1.0](https://github.com/parse-community/Parse-SDK-Flutter/compare/dart-9.0.0...dart-9.1.0) (2025-11-28)


### Features

* Bump timezone from 0.9.4 to 0.10.1 in /packages/dart ([#1063](https://github.com/parse-community/Parse-SDK-Flutter/issues/1063)) ([d3f2333](https://github.com/parse-community/Parse-SDK-Flutter/commit/d3f23338d5c8ca1e0239656814ac84818741f39d))

# [9.0.0](https://github.com/parse-community/Parse-SDK-Flutter/compare/dart-8.0.2...dart-9.0.0) (2025-11-28)


### Features

* Remove support for expired Dart and Flutter versions ([#1052](https://github.com/parse-community/Parse-SDK-Flutter/issues/1052)) ([dbeb5cb](https://github.com/parse-community/Parse-SDK-Flutter/commit/dbeb5cbdb7e14c6fac5cf51a90addb0872ca88f2))


### BREAKING CHANGES

* This release removes support for Dart 3.2 - 3.9 and Flutter 3.16 - 3.37. These versions exceeded their 6-month support window after the next significant version release. The minimum required versions are now Dart 3.10 and Flutter 3.38. ([dbeb5cb](dbeb5cb))

## [8.0.2](https://github.com/parse-community/Parse-SDK-Flutter/compare/dart-8.0.1...dart-8.0.2) (2025-11-28)

### Bug Fixes

* `ParseXFile` uploads file with content-type `application/octet-stream` if not explicitly set ([#1048](https://github.com/parse-community/Parse-SDK-Flutter/pull/1048))

## [8.0.1](https://github.com/parse-community/Parse-SDK-Flutter/compare/dart-8.0.0...dart-8.0.1) (2025-11-22)

### Bug Fixes

* Fix Http client exception not handled properly resulting in incorrectly formatted error ([#1021](https://github.com/parse-community/Parse-SDK-Flutter/pull/1021))

## [8.0.0](https://github.com/parse-community/Parse-SDK-Flutter/compare/dart-7.0.1...dart-8.0.0) (2024-12-20)

### BREAKING CHANGES

* This release removes support for Dart 3.0, 3.1 ([#1016](https://github.com/parse-community/Parse-SDK-Flutter/pull/1016))

### Features

* Add support for Dart 3.4, 3.5; remove support for Dart 3.0, 3.1 ([#1016](https://github.com/parse-community/Parse-SDK-Flutter/pull/1016))
* Add client access via `ParseDioClient.dioClient` and `ParseHTTPClient.httpClient` ([#1025](https://github.com/parse-community/Parse-SDK-Flutter/pull/1025))

## [7.0.1](https://github.com/parse-community/Parse-SDK-Flutter/compare/dart-7.0.0...dart-7.0.1) (2024-10-16)

### Bug Fixes

* Select input name instead of file in `ParseFile` ([#1012](https://github.com/parse-community/Parse-SDK-Flutter/pull/1012))

## [7.0.0](https://github.com/parse-community/Parse-SDK-Flutter/compare/dart-6.4.0...dart-7.0.0) (2024-04-12)

### BREAKING CHANGES

* This release removes support for Dart 2.19 ([#993](https://github.com/parse-community/Parse-SDK-Flutter/pull/993))

### Features

* Add support for Dart 3.1, 3.2, 3.3; remove support for Dart 2.19 ([#993](https://github.com/parse-community/Parse-SDK-Flutter/pull/993))

## [6.4.0](https://github.com/parse-community/Parse-SDK-Flutter/compare/dart-6.3.0...dart-6.4.0) (2024-03-30)

### Features

* Add `ParseXFile` for cross-platform `XFile` support ([#990](https://github.com/parse-community/Parse-SDK-Flutter/pull/990))

## [6.3.0](https://github.com/parse-community/Parse-SDK-Flutter/compare/dart-6.2.0...dart-6.3.0) (2023-11-11)

### Features

* Add `installationId` in LiveQuery `connect` ([#976](https://github.com/parse-community/Parse-SDK-Flutter/pull/976))

## [6.2.0](https://github.com/parse-community/Parse-SDK-Flutter/compare/dart-6.1.0...dart-6.2.0) (2023-10-18)

### Features

* Added `saveEventually` and `deleteEventually` in `ParseObject` ([#911](https://github.com/parse-community/Parse-SDK-Flutter/pull/911))

## [6.1.0](https://github.com/parse-community/Parse-SDK-Flutter/compare/dart-6.0.0...dart-6.1.0) (2023-10-17)

### Features

* Add `context` in `ParseObject` ([#970](https://github.com/parse-community/Parse-SDK-Flutter/pull/970))

## [6.0.0](https://github.com/parse-community/Parse-SDK-Flutter/compare/dart-5.1.3...dart-6.0.0) (2023-10-16)

### BREAKING CHANGES

* This release removes support for Dart 2.18 ([#969](https://github.com/parse-community/Parse-SDK-Flutter/pull/969))

### Features

* Add support for Dart 3.1, remove support for Dart 2.18 ([#969](https://github.com/parse-community/Parse-SDK-Flutter/pull/969))

## [5.1.3](https://github.com/parse-community/Parse-SDK-Flutter/compare/dart-5.1.2...dart-5.1.3) (2023-07-18)

### Bug Fixes

* Malformed JSON in `whereMatchesQuery` ([#955](https://github.com/parse-community/Parse-SDK-Flutter/pull/955))

## [5.1.2](https://github.com/parse-community/Parse-SDK-Flutter/compare/dart-5.1.1...dart-5.1.2) (2023-05-29)

### Bug Fixes

* Incorrect results when `ParseQuery` contains special characters ([#866](https://github.com/parse-community/Parse-SDK-Flutter/pull/866))

## [5.1.1](https://github.com/parse-community/Parse-SDK-Flutter/compare/dart-5.1.0...dart-5.1.1) (2023-05-20)

### Bug Fixes

* Query conditions `inQuery` and `notInQuery` not working properly ([#869](https://github.com/parse-community/Parse-SDK-Flutter/pull/869))

## [5.1.0](https://github.com/parse-community/Parse-SDK-Flutter/compare/dart-5.0.0...dart-5.1.0) (2023-05-14)

### Features

* Downgrade collection dependency to ^1.16.0 for compatibility with Flutter >=3.3 ([#880](https://github.com/parse-community/Parse-SDK-Flutter/pull/880))
  
## [5.0.0](https://github.com/parse-community/Parse-SDK-Flutter/compare/dart-4.0.2...dart-5.0.0) (2023-05-14)

### BREAKING CHANGES

* The minimum required Dart SDK version is 2.18.0. ([#867](https://github.com/parse-community/Parse-SDK-Flutter/pull/867))
* Performing an atomic update on a key of a Parse Object now returns the prospective value, instead of a map of the operation that will be sent to the server; for example for a Parse Object `obj` with a key `count`, the atomic update `obj.setIncrement('count', 1);` previously returned the value `{__op: Increment, amount: 1}` but now returns the prospective result of the operation, which would be `1` if the key's previous value was `0`. ([#860](https://github.com/parse-community/Parse-SDK-Flutter/pull/860))

### Bug Fixes

* Incorrect Dart and Flutter SDKs compatibility range ([#867](https://github.com/parse-community/Parse-SDK-Flutter/pull/867))
* Setting atomic operation on Parse Object returns operation instead of prospective value ([#860](https://github.com/parse-community/Parse-SDK-Flutter/pull/860))

## [4.0.2](https://github.com/parse-community/Parse-SDK-Flutter/compare/dart-4.0.1...dart-4.0.2) (2023-03-23)

### Bug Fixes

* Attempt to save `ParseObject` even if its nested `ParseObject` failed to save ([#859](https://github.com/parse-community/Parse-SDK-Flutter/pull/859))

## [4.0.1](https://github.com/parse-community/Parse-SDK-Flutter/compare/dart-4.0.0...dart-4.0.1) (2023-03-20)

### Bug Fixes

* Unhandled exception when saving a `ParseObject` but its nested object fails to save ([#858](https://github.com/parse-community/Parse-SDK-Flutter/pull/858))

## [4.0.0](https://github.com/parse-community/Parse-SDK-Flutter/compare/dart-3.1.14...dart-4.0.0) (2023-03-07)

### BREAKING CHANGES

* Upgrades to dio 5.x ([#824](https://github.com/parse-community/Parse-SDK-Flutter/pull/824))

### Feature

* Upgrade various dependencies and fix warnings ([#824](https://github.com/parse-community/Parse-SDK-Flutter/pull/824))

## [3.1.15](https://github.com/parse-community/Parse-SDK-Flutter/compare/dart-3.1.14...dart-3.1.15) (2023-02-28)

### Bug Fixes

* Updating and deleting a ParseObject sends requests even if object ID is null ([#829](https://github.com/parse-community/Parse-SDK-Flutter/pull/829))

## [3.1.14](https://github.com/parse-community/Parse-SDK-Flutter/compare/dart-3.1.13...dart-3.1.14) (2023-02-26)

### Bug Fixes

* Dio error object holds a reference to null values ([#774](https://github.com/parse-community/Parse-SDK-Flutter/issues/774))

## [3.1.13](https://github.com/parse-community/Parse-SDK-Flutter/compare/dart-3.1.12...dart-3.1.13) (2023-02-15)

### Bug Fixes

* `ParseUser.save` fails when user is logged in ([#819](https://github.com/parse-community/Parse-SDK-Flutter/issues/819))

## [3.1.12](https://github.com/parse-community/Parse-SDK-Flutter/compare/dart-3.1.11...dart-3.1.12) (2023-02-01)

### Bug Fixes

* `ParseObject.fromJson` does not send proper payload to server ([#688](https://github.com/parse-community/Parse-SDK-Flutter/issues/688))

## [3.1.11](https://github.com/parse-community/Parse-SDK-Flutter/compare/dart-3.1.10...dart-3.1.11) (2023-01-21)

### Features

* Add query constraint `wherePolygonContains` to determine whether a point in within a polygon ([#777](https://github.com/parse-community/Parse-SDK-Flutter/issues/777))

## [3.1.10](https://github.com/parse-community/Parse-SDK-Flutter/compare/dart-3.1.9...dart-3.1.10) (2023-01-16)

### Bug Fixes

* Time zone data not set in `ParseInstallation` ([#96](https://github.com/parse-community/Parse-SDK-Flutter/issues/96))

## [3.1.9](https://github.com/parse-community/Parse-SDK-Flutter/compare/dart-3.1.8...dart-3.1.9) (2022-12-25)

### Bug Fixes

* Include option in `getObject` feature is not working ([#813](https://github.com/parse-community/Parse-SDK-Flutter/issues/813))

## [3.1.8](https://github.com/parse-community/Parse-SDK-Flutter/compare/dart-3.1.7...dart-3.1.8) (2022-12-23)

### Features

* Add `ParseObject.toJson()` to create a JSON representation ([#616](https://github.com/parse-community/Parse-SDK-Flutter/issues/616))

## [3.1.7](https://github.com/parse-community/Parse-SDK-Flutter/compare/dart-3.1.6...dart-3.1.7) (2022-12-22)

### Features

* Add `include` option to `getObject` and `fetch` ([#798](https://github.com/parse-community/Parse-SDK-Flutter/issues/798))

## [3.1.6](https://github.com/parse-community/Parse-SDK-Flutter/compare/dart-3.1.5...dart-3.1.6) (2022-12-21)

### Bug Fixes

* Add `and`, `nor` operators in QueryBuilder ([#795](https://github.com/parse-community/Parse-SDK-Flutter/issues/795))

## [3.1.5](https://github.com/parse-community/Parse-SDK-Flutter/compare/dart-3.1.4...dart-3.1.5) (2022-12-16)

### Bug Fixes

* Add upload / download cancel and progress callback for ParseFile ([#807](https://github.com/parse-community/Parse-SDK-Flutter/issues/807))

## [3.1.4](https://github.com/parse-community/Parse-SDK-Flutter/compare/dart-3.1.3...dart-3.1.4) (2022-12-14)

### Bug Fixes

* SDK crashes due to missing error code property in `ParseNetworkResponse.data` ([#799](https://github.com/parse-community/Parse-SDK-Flutter/issues/799))

## [3.1.3](https://github.com/parse-community/Parse-SDK-Flutter/compare/dart-3.1.2...dart-3.1.3) (2022-11-15)

### Bug Fixes

* Custom JSON encoder for List and Map doesn't work correctly in `full` mode ([#788](https://github.com/parse-community/Parse-SDK-Flutter/issues/788))

## [3.1.2](https://github.com/parse-community/Parse-SDK-Flutter/compare/dart-3.1.1...dart-3.1.2) (2022-07-09)

### Bug Fixes

* unhandled exception in `ParseRelation`, type `ParseObject` is not a subtype of type ([#696](https://github.com/parse-community/Parse-SDK-Flutter/issues/696))
* error in progress callback ([#679](https://github.com/parse-community/Parse-SDK-Flutter/issues/679))
* incorrect return type when calling `first()` ([#661](https://github.com/parse-community/Parse-SDK-Flutter/issues/661))
* error in `ParseLiveListWidget` when enabling `lazyloading` ([#653](https://github.com/parse-community/Parse-SDK-Flutter/issues/653))
* unexpected null value after call `user.logout()` ([#770](https://github.com/parse-community/Parse-SDK-Flutter/issues/770))

## [3.1.1](https://github.com/parse-community/Parse-SDK-Flutter/compare/V3.1.0...dart-3.1.1) (2022-05-30)

### Refactors

* fix analyzer code style warnings ([#733](https://github.com/parse-community/Parse-SDK-Flutter/issues/733))

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

### BREAKING CHANGES

* From this release onwards the previous repository has been separated into a pure dart (parse_server_sdk) and a flutter package (parse_server_sdk_flutter). This was done in order to provide a dart package for the parse-server, while keeping maintenance simple. You can find both packages in the package directory. If you are using flutter you should migrate using [this guide](https://github.com/parse-community/Parse-SDK-Flutter/blob/release/2.0.0/docs/migrate-2-0-0.md).

### Features

* Added full web support
* Moved ParseHTTPClient to Dio [#459](https://github.com/parse-community/Parse-SDK-Flutter/pull/459)

### Bug Fixes

* General improvements

## 1.0.28

1.0.28 was renamed to 2.0.0

## 1.0.27

User login / signUp / loginAnonymous delete SessionId stored in device before calling server

## 1.0.26

LiveList
Bug fixes
Sembast update

## 1.0.25

Update dependencies

## 1.0.24

Fixed lint

## 1.0.23

Fixed LiveQuery
Bug fixes

## 1.0.22

Added dirty children
Added option of sembast or share_preferences 

## 1.0.21

LiveQuery fix
Logout fix

## 1.0.20

ACL now working
emailVerified

## 1.0.19

Bug fix

## 1.0.18

Bug fix

## 1.0.17

LiveQuery fix 
Bug fixes

## 1.0.16

Bug fixes
Fixed object delete
Added port support

## 1.0.15

Fixed 'full' bool issue

## 1.0.14

Corrected delete & path issue
Added Geo queries
Added ability to add login oAuth data

## 1.0.13

Added full bool to convert objects to JSON correctly

## 1.0.12

Fixed logout

## 1.0.11

ParseFile fixed
Anonymous login
SecurityContext
CloudFunctions with objects

## 1.0.10

Add ParseConfig.
Fixed whereEqualsTo('', PARSEOBJECT) and other queries

## 1.0.9

Fixed Health Check issue

## 1.0.8

Fixed some queries

## 1.0.7

Some items now return a response rather than a ParseObject

## 1.0.6

BREAK FIX - Fixed ParseUser return type so now returns ParseResponse
BREAK FIX - Changed query names to make more human readable
Fixed pinning and unpinning

## 1.0.5

Corrected save. Now formatted items correctly for saving on server

## 1.0.4

Bug fix for get all items
Can now pin/unpin/fromPin for all ParseObjects
Now supports generics
Cody tidy around extending

## 1.0.3

Added persistent storage. When a logged in user closes the app, then reopens, the data
will now be persistent. Best practice would be to Parse.init, then Parse.currentUser. This
will return the current user session and allow auto login. Can also pin data in storage.

## 1.0.2

Fixed login

## 1.0.1

Added documentation and GeoPoints

## 1.0.0

First full release!

## 0.0.4

Added description

## 0.0.3

Added more cloud functions
