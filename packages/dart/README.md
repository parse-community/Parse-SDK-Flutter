<img src="https://user-images.githubusercontent.com/5673677/166120960-ea1f58e3-a62b-4770-b541-f64186859339.png" alt="parse-repository-header-sdk-dart" style="max-width: 100%;">

---

[![Build Status](https://github.com/parse-community/Parse-SDK-Flutter/workflows/ci/badge.svg?branch=master)](https://github.com/parse-community/Parse-SDK-Flutter/actions?query=workflow%3Aci+branch%3Amaster)
[![Coverage](https://img.shields.io/codecov/c/github/parse-community/Parse-SDK-Flutter/master)](https://app.codecov.io/gh/parse-community/Parse-SDK-Flutter/branch/master)

[![pub package](https://img.shields.io/pub/v/parse_server_sdk.svg)](https://pub.dev/packages/parse_server_sdk)

[![Forum](https://img.shields.io/discourse/https/community.parseplatform.org/topics.svg)](https://community.parseplatform.org/c/parse-server)
[![Backers on Open Collective](https://opencollective.com/parse-server/backers/badge.svg)][open-collective-link]
[![Sponsors on Open Collective](https://opencollective.com/parse-server/sponsors/badge.svg)][open-collective-link]
[![Twitter Follow](https://img.shields.io/twitter/follow/ParsePlatform.svg?label=Follow%20us&style=social)](https://twitter.com/intent/follow?screen_name=ParsePlatform)
[![Chat](https://img.shields.io/badge/Chat-Join!-%23fff?style=social&logo=slack)](https://chat.parseplatform.org)

---

This library gives you access to the powerful Parse Server backend from your Dart app. For more information on Parse Platform and its features, visit [parseplatform.org](https://parseplatform.org).

---

- [Compatibility](#compatibility)
  - [Handling Version Conflicts](#handling-version-conflicts)
- [Getting Started](#getting-started)
- [Documentation](#documentation)
- [Contributing](#contributing)

---

## Compatibility

The Parse Dart SDK is continuously tested with the most recent release of the Dart framework to ensure compatibility. Previous Dart framework releases are supported for **6 months** after the [release date](https://dart.dev/get-dart/archive) of the next higher significant version (major or minor).

> [!Note]
> Support windows are calculated from official Dart release dates. When a version's support period expires, it will be dropped in the next Parse SDK major release without advance notice. For full details, see [VERSIONING_POLICY.md](../../VERSIONING_POLICY.md).

### Handling Version Conflicts

If you encounter version conflicts with the Parse SDK:

1. Check if a newer Parse Dart SDK version resolves your conflict.
2. Review your dependencies by running `dart pub outdated` to see available updates.
3. Check [Parse Dart SDK compatibility](../dart/README.md#compatibility).
4. Check [Migration Guides](../../MIGRATION_GUIDES.md) for common scenarios.
5. [Create an issue](https://github.com/parse-community/Parse-SDK-Flutter/issues) with your full dependency tree.

For detailed troubleshooting, see our [Version Conflict Guide](../../MIGRATION_GUIDES.md#handling-version-conflicts).

## Getting Started

To install, add the Parse Dart SDK as a [dependency](https://pub.dev/packages/parse_server_sdk/install) in your `pubspec.yaml` file.

## Documentation

Find the full documentation in the [Parse Dart SDK guide][guide].

## Contributing

We want to make contributing to this project as easy and transparent as possible. Please refer to the [Contribution Guidelines](https://github.com/parse-community/Parse-SDK-Flutter/blob/master/CONTRIBUTING.md).

[guide]: https://docs.parseplatform.org/dart/guide/
[open-collective-link]: https://opencollective.com/parse-server

