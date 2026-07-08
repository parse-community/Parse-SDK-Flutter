# Versioning and Support Policy

Parse SDK for Dart/Flutter versioning, framework compatibility, dependency management, and release strategy.

## Framework Version Support

The support window is **6 months** after the next significant version (major/minor, not patch).

**Example:**
- Dart 3.3.0 released: February 15, 2024
- Dart 3.2.x end-of-support: August 15, 2024

> [!Important]
> There are no deprecation notices. Versions are dropped immediately when support expires.

See the README files in `/packages/dart/` and `/packages/flutter/` for current compatibility tables.

## Dependency Management

### Constraints

Use **caret constraints** (`^`) following Dart conventions:

```yaml
dependencies:
  dio: ^5.7.0          # Allows >=5.7.0 <6.0.0
  http: ^1.2.0         # Allows >=1.2.0 <2.0.0
```

### Updates

**Dependabot checks daily** and creates PRs immediately when updates available and PRs are merged as soon as the CI passes.

### Version Bumps

| Dependency Change | Parse SDK Bump |
|-------------------|----------------|
| Major with breaking API impact | Major |
| Major with non-breaking API impact | Minor |
| Major without API impact | Patch |
| Minor | Patch |
| Patch | Patch |

## Handling Version Conflicts

See [MIGRATION_GUIDES.md](MIGRATION_GUIDES.md) for detailed solutions.

**Quick fixes:**
1. Update Parse SDK to latest version
2. Update all dependencies: `flutter pub upgrade`
3. Check GitHub issues for known conflicts

## Testing

**CI Matrix:**
- Latest: All platforms (Ubuntu, macOS, Windows)
- 1-2 previous: Ubuntu only
- Beta: Ubuntu only

## Automated Management

- Dependabot: Regular checks for Dart/Flutter dependencies.

- Security Audit: Monthly `dart pub audit`, creates issues for vulnerabilities.

## Resources

- [MIGRATION_GUIDES.md](MIGRATION_GUIDES.md) - Conflict resolution
