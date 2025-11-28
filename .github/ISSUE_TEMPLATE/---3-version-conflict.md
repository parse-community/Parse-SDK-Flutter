---
name: "\U0001F4E6 Version Conflict"
about: Report a version conflict with Parse SDK dependencies
title: '[Version Conflict] '
labels: 'dependencies, version-conflict'
assignees: ''
---

## Version Conflict Description

<!-- Describe the version conflict you're experiencing -->

## Environment

**Parse SDK Version:**
- Dart SDK: [e.g., 8.0.2]
- Flutter SDK (if applicable): [e.g., 9.0.0]

**Framework Version:**
- Dart: [e.g., 3.2.6]
- Flutter (if applicable): [e.g., 3.16.9]

**Platform:**
- [ ] Dart
- [ ] Flutter (Web)
- [ ] Flutter (Mobile - iOS)
- [ ] Flutter (Mobile - Android)
- [ ] Flutter (Desktop - macOS)
- [ ] Flutter (Desktop - Windows)
- [ ] Flutter (Desktop - Linux)

## Conflict Details

**Conflicting Package:**
[e.g., dio, http, sembast]

**Required Version:**
[e.g., Package X requires dio ^6.0.0 but Parse SDK requires ^5.0.0]

**Error Message:**
```
Paste the full error message from `dart pub get` or `flutter pub get`
```

## Your pubspec.yaml

```yaml
# Paste relevant sections of your pubspec.yaml
dependencies:
  parse_server_sdk: ^8.0.0
  # ... other dependencies
```

## Dependency Tree

```bash
# Run: dart pub deps or flutter pub deps
# Paste the output here
```

## Steps Tried

<!-- Check all that apply -->

- [ ] Updated to latest Parse SDK version
- [ ] Ran `dart pub outdated` / `flutter pub outdated`
- [ ] Checked [MIGRATION_GUIDES.md](https://github.com/parse-community/Parse-SDK-Flutter/blob/master/MIGRATION_GUIDES.md)
- [ ] Tried `dependency_overrides` (temporary workaround)
- [ ] Searched existing issues

## Workaround

<!-- If you found a workaround, share it here to help others -->

## Additional Context

<!-- Add any other context, screenshots, or information -->
