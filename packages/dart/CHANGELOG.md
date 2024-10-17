## [8.0.0](https://github.com/parse-community/Parse-SDK-Flutter/compare/dart-7.0.1...dart-8.0.0) (2024-10-17)

### BREAKING CHANGES

* This release removes support for Dart 3.0, 3.1 ([#1016](https://github.com/parse-community/Parse-SDK-Flutter/pull/1016))

### Features

* Add support for Dart 3.4, 3.5; remove support for Dart 3.0, 3.1 ([#1016](https://github.com/parse-community/Parse-SDK-Flutter/pull/1016))

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
