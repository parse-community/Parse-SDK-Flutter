<img src="https://user-images.githubusercontent.com/5673677/166121333-2a144ce3-95bc-45d6-8840-d5b2885f2046.png" alt="parse-repository-header-sdk-flutter" style="max-width: 100%;">

---

[![Build Status](https://github.com/parse-community/Parse-SDK-Flutter/workflows/ci/badge.svg?branch=master)](https://github.com/parse-community/Parse-SDK-Flutter/actions?query=workflow%3Aci+branch%3Amaster)
[![Coverage](https://img.shields.io/codecov/c/github/parse-community/Parse-SDK-Flutter/master)](https://app.codecov.io/gh/parse-community/Parse-SDK-Flutter/branch/master)

[![pub package](https://img.shields.io/pub/v/parse_server_sdk_flutter.svg)](https://pub.dev/packages/parse_server_sdk_flutter)

[![Forum](https://img.shields.io/discourse/https/community.parseplatform.org/topics.svg)](https://community.parseplatform.org/c/parse-server)
[![Backers on Open Collective](https://opencollective.com/parse-server/backers/badge.svg)][open-collective-link]
[![Sponsors on Open Collective](https://opencollective.com/parse-server/sponsors/badge.svg)][open-collective-link]
[![Twitter Follow](https://img.shields.io/twitter/follow/ParsePlatform.svg?label=Follow%20us&style=social)](https://twitter.com/intent/follow?screen_name=ParsePlatform)
[![Chat](https://img.shields.io/badge/Chat-Join!-%23fff?style=social&logo=slack)](https://chat.parseplatform.org)

---

This library gives you access to the powerful Parse Server backend from your Flutter app. For more information on Parse Platform and its features, visit [parseplatform.org](https://parseplatform.org).

---

- [Compatibility](#compatibility)
  - [Handling Version Conflicts](#handling-version-conflicts)
- [Getting Started](#getting-started)
- [Features](#features)
  - [Live Queries](#live-queries)
  - [Offline Support](#offline-support)
- [Usage](#usage)
  - [ParseLiveList](#parselivelist)
  - [ParseLiveSliverList](#parselivesliverlist)
  - [ParseLiveSliverGrid](#parseliveslivergrid)
  - [ParseLivePageView](#parselivepageview)
  - [Offline Mode](#offline-mode)
- [Documentation](#documentation)
- [Contributing](#contributing)

---

## Compatibility

The Parse Flutter SDK is continuously tested with the most recent release of the Flutter framework to ensure compatibility. Previous Flutter framework releases are supported for **6 months** after the [release date](https://docs.flutter.dev/release/archive?tab=linux) of the next higher significant version (major or minor).

> [!Important]
> The Parse Flutter SDK depends on the Parse Dart SDK which may require a higher Dart framework version than the Flutter framework version, in which case the specific Flutter framework version cannot be supported. Check both SDK compatibility tables.

> [!Note]
> Support windows are calculated from official Flutter release dates. When a version's support period expires, it will be dropped in the next Parse SDK major release without advance notice. For full details, see [VERSIONING_POLICY.md](../../VERSIONING_POLICY.md).

### Handling Version Conflicts

If you encounter version conflicts with the Parse SDK:

1. Check if a newer Parse Flutter SDK version resolves your conflict.
2. Review your dependencies by running `flutter pub outdated` to see available updates.
3. Check [Parse Dart SDK compatibility](../dart/README.md#compatibility).
4. Check [Migration Guides](../../MIGRATION_GUIDES.md) for common scenarios.
5. [Create an issue](https://github.com/parse-community/Parse-SDK-Flutter/issues) with your full dependency tree.

For detailed troubleshooting, see our [Version Conflict Guide](../../MIGRATION_GUIDES.md#handling-version-conflicts).

## Getting Started

To install, add the Parse Flutter SDK as a [dependency](https://pub.dev/packages/parse_server_sdk_flutter/install) in your `pubspec.yaml` file.

## Features

### Live Queries

The Parse Flutter SDK provides real-time data synchronization with your Parse Server through live queries. The SDK includes multiple widget types to display live data:

- **ParseLiveList**: Traditional scrollable list for displaying Parse objects
- **ParseLiveSliverList**: Sliver-based list for use within CustomScrollView
- **ParseLiveSliverGrid**: Sliver-based grid for use within CustomScrollView
- **ParseLivePageView**: PageView-based widget for swiping through objects

All live query widgets support:
- Real-time updates via live query subscriptions
- Pagination for handling large datasets
- Lazy loading for efficient memory usage
- Customizable child builders for flexible UI design
- Error handling and loading states

### Offline Support

The Parse Flutter SDK includes comprehensive offline support through local caching. When enabled, the app can:

- Cache Parse objects locally for offline access
- Automatically sync cached objects when connectivity is restored
- Provide seamless user experience even without network connection
- Efficiently manage disk storage with LRU caching

## Usage

### ParseLiveList

A traditional ListView widget that displays a live-updating list of Parse objects:

```dart
ParseLiveListWidget<MyObject>(
  query: QueryBuilder<MyObject>(MyObject()),
  childBuilder: (context, snapshot) {
    if (snapshot.hasData) {
      return ListTile(title: Text(snapshot.data.name));
    }
    return const ListTile(title: Text('Loading...'));
  },
  offlineMode: true,
  fromJson: (json) => MyObject().fromJson(json),
)
```

### ParseLiveSliverList

A sliver-based list widget for use within CustomScrollView:

```dart
CustomScrollView(
  slivers: [
    SliverAppBar(title: const Text('Live List')),
    ParseLiveSliverListWidget<MyObject>(
      query: QueryBuilder<MyObject>(MyObject()),
      childBuilder: (context, snapshot) {
        if (snapshot.hasData) {
          return ListTile(title: Text(snapshot.data.name));
        }
        return const ListTile(title: Text('Loading...'));
      },
      offlineMode: true,
      fromJson: (json) => MyObject().fromJson(json),
    ),
  ],
)
```

### ParseLiveSliverGrid

A sliver-based grid widget for use within CustomScrollView:

```dart
CustomScrollView(
  slivers: [
    SliverAppBar(title: const Text('Live Grid')),
    ParseLiveSliverGridWidget<MyObject>(
      query: QueryBuilder<MyObject>(MyObject()),
      crossAxisCount: 2,
      childBuilder: (context, snapshot) {
        if (snapshot.hasData) {
          return Card(child: Text(snapshot.data.name));
        }
        return const Card(child: Text('Loading...'));
      },
      offlineMode: true,
      fromJson: (json) => MyObject().fromJson(json),
    ),
  ],
)
```

#### Controlling Sliver Widgets with GlobalKey

For sliver widgets, you can use a `GlobalKey` to control refresh and pagination from a parent widget:

```dart
final gridKey = GlobalKey<ParseLiveSliverGridWidgetState<MyObject>>();

// In your CustomScrollView
ParseLiveSliverGridWidget<MyObject>(
  key: gridKey,
  query: query,
  pagination: true,
  offlineMode: true,
  fromJson: (json) => MyObject().fromJson(json),
)

// To refresh
gridKey.currentState?.refreshData();

// To load more (if pagination is enabled)
gridKey.currentState?.loadMoreData();

// Access status
final hasMore = gridKey.currentState?.hasMoreData ?? false;
final status = gridKey.currentState?.loadMoreStatus;
```

The same pattern works for `ParseLiveSliverListWidget` using `ParseLiveSliverListWidgetState`.

### ParseLivePageView

A PageView widget for swiping through Parse objects:

```dart
ParseLiveListPageView<MyObject>(
  query: QueryBuilder<MyObject>(MyObject()),
  childBuilder: (context, snapshot) {
    if (snapshot.hasData) {
      return Center(child: Text(snapshot.data.name));
    }
    return const Center(child: Text('Loading...'));
  },
  pagination: true,
  pageSize: 1,
  offlineMode: true,
  fromJson: (json) => MyObject().fromJson(json),
)
```

### Offline Mode

Enable offline support on any live query widget by setting `offlineMode: true`. The widget will automatically cache data and switch to cached data when offline.

#### Offline Caching Methods

Use the `ParseObjectOffline` extension methods for manual offline control:

```dart
// Save a single object to cache
await myObject.saveToLocalCache();

// Load a single object from cache
final cachedObject = await ParseObjectOffline.loadFromLocalCache('ClassName', 'objectId');

// Save multiple objects efficiently
await ParseObjectOffline.saveAllToLocalCache('ClassName', listOfObjects);

// Load all objects of a class from cache
final allCached = await ParseObjectOffline.loadAllFromLocalCache('ClassName');

// Remove an object from cache
await myObject.removeFromLocalCache();

// Update an object in cache
await myObject.updateInLocalCache({'field': 'newValue'});

// Clear all cached objects for a class
await ParseObjectOffline.clearLocalCacheForClass('ClassName');

// Check if an object exists in cache
final exists = await ParseObjectOffline.existsInLocalCache('ClassName', 'objectId');

// Get all object IDs in cache for a class
final objectIds = await ParseObjectOffline.getAllObjectIdsInLocalCache('ClassName');

// Sync cached objects with server
await ParseObjectOffline.syncLocalCacheWithServer('ClassName');
```

#### Configuration

Customize offline behavior with widget parameters:

- `offlineMode`: Enable/disable offline caching (default: `false`)
- `cacheSize`: Maximum number of objects to keep in memory (default: `50`)
- `lazyLoading`: Load full object data on-demand (default: `true`)
- `preloadedColumns`: Specify which fields to fetch initially when lazy loading is enabled

## Documentation

Find the full documentation in the [Parse Flutter SDK guide][guide].

## Contributing

We want to make contributing to this project as easy and transparent as possible. Please refer to the [Contribution Guidelines](https://github.com/parse-community/Parse-SDK-Flutter/blob/master/CONTRIBUTING.md).

[guide]: https://docs.parseplatform.org/flutter/guide/
[open-collective-link]: https://opencollective.com/parse-server