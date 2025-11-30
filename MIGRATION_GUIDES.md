# Migration Guides <!-- omit in toc -->

This document provides guidance for handling version conflicts, upgrading between Parse SDK versions, and resolving common dependency issues.

## Table of Contents <!-- omit in toc -->

- [Handling Version Conflicts](#handling-version-conflicts)
- [Common Scenarios](#common-scenarios)
  - [CI/CD Pipeline Fails After Parse SDK Update](#cicd-pipeline-fails-after-parse-sdk-update)
  - [Using Flutter Web and Version Conflicts](#using-flutter-web-and-version-conflicts)
  - [Support Older Devices](#support-older-devices)
- [Additional Resources](#additional-resources)

## Handling Version Conflicts

Version conflicts occur when multiple packages in your project have incompatible requirements. Here's how to resolve them.

### Scenario 1: Parse SDK Blocks Newer Package <!-- omit in toc -->

**Problem:**
```
Because your_app depends on parse_server_sdk ^8.0.0 which depends on dio ^5.0.0,
  and your_app depends on another_package ^2.0.0 which depends on dio ^6.0.0,
  version solving failed.
```

**Solutions (in order of preference):**

#### 1. Update Parse SDK (Recommended) <!-- omit in toc -->
Check if a newer version of Parse SDK supports the required dependency version:

```bash
# Check for Parse SDK updates
cd packages/dart
dart pub outdated

# Or for Flutter package
cd packages/flutter
flutter pub outdated
```

Update your `pubspec.yaml`:
```yaml
dependencies:
  parse_server_sdk: ^9.0.0  # Newer version may support dio ^6.0.0
```

#### 2. Request Parse SDK Upgrade <!-- omit in toc -->
If Parse SDK doesn't support the required version, create a GitHub issue:

1. Go to https://github.com/parse-community/Parse-SDK-Flutter/issues
2. Title: "Support for [dependency] ^X.0.0"
3. Include:
   - Current Parse SDK version you're using
   - Dependency version you need
   - Why you need the newer version
   - Any relevant error messages

#### 3. Use dependency_overrides (Temporary) <!-- omit in toc -->
**Warning:** Only for development/testing, not for production!

```yaml
dependency_overrides:
  dio: ^6.0.0  # Override to resolve conflict temporarily
```

**Risks:**
- May cause runtime errors if Parse SDK uses deprecated APIs
- Not guaranteed to work
- Should never be published to pub.dev
- Must test thoroughly

#### 4. Fork Parse SDK (Last Resort) <!-- omit in toc -->
See [When to Fork](#when-to-fork) section below.

### Scenario 2: Parse SDK Requires Newer Dart/Flutter <!-- omit in toc -->

**Problem:**
```
Because parse_server_sdk >=8.0.0 requires SDK version >=3.2.6 <4.0.0,
  and your project has SDK version 2.19.0, version solving failed.
```

**Solutions (in order of preference):**

#### 1. Upgrade Dart/Flutter (Recommended) <!-- omit in toc -->

**For Dart projects:**
```bash
# Check current Dart version
dart --version

# Upgrade Dart (via brew on macOS)
brew upgrade dart

# Or download from https://dart.dev/get-dart
```

**For Flutter projects:**
```bash
# Check current Flutter version
flutter --version

# Upgrade Flutter
flutter upgrade

# Or upgrade to specific channel
flutter channel stable
flutter upgrade
```

**Migration guides:**
- Dart migration: https://dart.dev/guides/language/evolution
- Flutter migration: https://docs.flutter.dev/release/breaking-changes

#### 2. Use Older Parse SDK Version <!-- omit in toc -->

Check compatibility table in the Dart or Flutter package README and use an older Parse SDK version:

```yaml
dependencies:
  parse_server_sdk: ^7.0.0  # Supports older Dart versions
```

**Note:** Older versions:
- May lack newer features
- May have unfixed bugs
- May have security vulnerabilities
- Consider upgrading your Dart/Flutter instead

#### 3. Review Breaking Changes <!-- omit in toc -->

When upgrading Dart/Flutter, review breaking changes:

**Dart 3.x breaking changes:**
- Null safety enforced (no longer opt-in)
- Some deprecated APIs removed
- Enhanced enums with members
- Records and patterns introduced

**Flutter 3.x breaking changes:**
- Material 3 as default
- Deprecated APIs removed
- iOS minimum version increased
- Android minimum SDK version updated

**Resources:**
- [Dart changelog](https://github.com/dart-lang/sdk/blob/main/CHANGELOG.md)
- [Flutter release notes](https://docs.flutter.dev/release/release-notes)

### Scenario 3: Multiple Packages Have Conflicts <!-- omit in toc -->

**Problem:**
```
Because package_a depends on http ^0.13.0 and package_b depends on http ^1.0.0,
  and both are required by your app, version solving failed.
```

**Solutions:**

#### 1. Update All Packages <!-- omit in toc -->
```bash
# Update all dependencies to latest compatible versions
dart pub upgrade

# Or for Flutter
flutter pub upgrade
```

#### 2. Check for Parse SDK Update <!-- omit in toc -->
The Parse SDK update might have newer dependency constraints that resolve the conflict.

#### 3. Report Issue with Full Context <!-- omit in toc -->
Create a GitHub issue with your complete dependency tree:

```bash
# Generate dependency tree
dart pub deps

# Or for Flutter
flutter pub deps
```

Include the output in your GitHub issue.

## Common Scenarios

#### I Need Dart 3+ Features But Parse SDK Doesn't Support Them Yet <!-- omit in toc -->

**Solution:**
1. Check if newest Parse SDK supports Dart 3+
2. If not, check GitHub issues for timeline
3. Consider contributing the update yourself
4. Temporarily use Dart 2.x compatible patterns

### CI/CD Pipeline Fails After Parse SDK Update

**Troubleshooting:**

1. **Check Dart/Flutter version in CI:**
   ```yaml
   # Example for GitHub Actions
   - uses: dart-lang/setup-dart@v1
     with:
       sdk: 3.2.6  # Ensure matches Parse SDK requirements
   ```

2. **Update cache keys:**
   ```yaml
   - uses: actions/cache@v3
     with:
       path: ~/.pub-cache
       key: ${{ runner.os }}-pub-${{ hashFiles('**/pubspec.lock') }}
   ```

3. **Clear cached dependencies:**
   ```bash
   dart pub cache repair
   ```

### Using Flutter Web and Version Conflicts

**Common issue:** `sembast_web` version conflicts

**Solution:**
```yaml
dependencies:
  parse_server_sdk_flutter: ^9.0.0
  sembast_web: ^2.2.0  # Match version used by Parse SDK

# Check Parse SDK's pubspec.yaml for exact versions
```

### Support Older Devices

If newer Parse SDK requires newer Flutter/Dart that doesn't support your target devices:

1. **Check minimum requirements:**
   - iOS: Check Flutter's minimum iOS version
   - Android: Check Flutter's minimum SDK version
   - Web: Check browser compatibility

2. **Options:**
   - Upgrade device requirements
   - Use older Parse SDK version
   - Fork and maintain custom version

## Additional Resources

- [VERSIONING_POLICY.md](VERSIONING_POLICY.md) - Full versioning policy
- [Dart Packages](https://dart.dev/guides/packages) - Official Dart package guide
- [Using Packages](https://docs.flutter.dev/packages-and-plugins/using-packages) - Flutter package guide
- [Pub Versioning](https://dart.dev/tools/pub/versioning) - How Dart versions work
- [Semantic Versioning](https://semver.org) - Version numbering explained
