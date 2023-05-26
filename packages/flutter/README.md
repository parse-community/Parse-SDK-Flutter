![parse-repository-header-sdk-flutter](https://user-images.githubusercontent.com/5673677/166121333-2a144ce3-95bc-45d6-8840-d5b2885f2046.png)

---

[![Build Status](https://github.com/parse-community/Parse-SDK-Flutter/workflows/ci/badge.svg?branch=master)](https://github.com/parse-community/Parse-SDK-Flutter/actions?query=workflow%3Aci+branch%3Amaster)
[![Coverage](https://img.shields.io/codecov/c/github/parse-community/Parse-SDK-Flutter/master)](https://app.codecov.io/gh/parse-community/Parse-SDK-Flutter/branch/master)
[![auto-release](https://img.shields.io/badge/%F0%9F%9A%80-auto--release-9e34eb.svg)](https://github.com/parse-community/Parse-SDK-Flutter/releases)

[![Backers on Open Collective](https://opencollective.com/parse-server/backers/badge.svg)][open-collective-link]
[![Sponsors on Open Collective](https://opencollective.com/parse-server/sponsors/badge.svg)][open-collective-link]
[![License](https://img.shields.io/badge/license-Apache%202.0-lightgrey.svg)](https://github.com/parse-community/Parse-SDK-Flutter/blob/master/LICENSE)
[![Forum](https://img.shields.io/discourse/https/community.parseplatform.org/topics.svg)](https://community.parseplatform.org/c/parse-server)
[![Twitter Follow](https://img.shields.io/twitter/follow/ParsePlatform.svg?label=Follow%20us&style=social)](https://twitter.com/intent/follow?screen_name=ParsePlatform)
[![Chat](https://img.shields.io/badge/Chat-Join!-%23fff?style=social&logo=slack)](https://chat.parseplatform.org)

---

This library gives you access to the powerful Parse Server backend from your Dart app. For more information on Parse Platform and its features, visit [parseplatform.org](https://parseplatform.org).

---

- [Compatibility](#compatibility)
- [Getting Started](#getting-started)

---

## Compatibility

The Parse Flutter SDK is continuously tested with the most recent release of the Flutter framework to ensure compatibility. To give developers time to upgrade their app to the newest Flutter framework, previous Flutter framework releases are supported for at least 1 year after their [release date](https://docs.flutter.dev/release/archive?tab=linux). The Parse Flutter SDK depends on the Parse Dart SDK which may require a higher Dart framework version than the Flutter framework version, in which case the Flutter framework version cannot be supported even though its release date may have been less than a year ago.

| Version      | End of Support | Compatible                                   |
|--------------|----------------|----------------------------------------------|
| Flutter 3.10 | May 2024       | ❌ No                                         |
| Flutter 3.7  | Apr 2024       | ✅ Yes                                        |
| Flutter 3.3  | Jan 2024       | ✅ Yes                                         |
| Flutter 3.0  | Jul 2023       | ❌ No (Parse Flutter SDK requires Flutter >=3.3.0) |

## Getting Started

To install, either add [dependency in your pubspec.yaml file](https://pub.dev/packages/parse_server_sdk_flutter/install).

See the SDK Usage [guide][guide].

# Contributing

We want to make contributing to this project as easy and transparent as possible. Please refer to the [Contribution Guidelines](../../CONTRIBUTING.md).

---

[guide]: https://docs.parseplatform.org/flutter/guide/
[open-collective-link]: https://opencollective.com/parse-server
