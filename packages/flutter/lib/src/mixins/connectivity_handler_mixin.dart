import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart'; // Needed for State

/// Mixin to handle connectivity checks and state updates for Parse Live Widgets.
///
/// Requires the consuming State class to implement abstract methods for
/// loading data, disposing live resources, and providing configuration.
mixin ConnectivityHandlerMixin<T extends StatefulWidget> on State<T> {
  // State variables managed by the mixin
  bool _isOffline = false;
  late StreamSubscription<List<ConnectivityResult>> _connectivitySubscription;
  final Connectivity _connectivity = Connectivity();
  ConnectivityResult? _connectionStatus;

  // Abstract methods to be implemented by the consuming State class
  /// Loads data from the server (e.g., initializes LiveQuery).
  Future<void> loadDataFromServer();

  /// Loads data from the local cache.
  Future<void> loadDataFromCache();

  /// Disposes any active LiveQuery resources.
  void disposeLiveList();

  /// A prefix string for debug logs (e.g., "List", "Grid").
  String get connectivityLogPrefix;

  /// Indicates if offline mode is enabled in the widget's configuration.
  bool get isOfflineModeEnabled;

  /// Getter to access the internal offline state.
  bool get isOffline => _isOffline;

  /// Initializes the connectivity handler. Call this in initState.
  void initConnectivityHandler() {
    _internalInitConnectivity(); // Perform initial check

    // Listen for subsequent changes
    _connectivitySubscription =
        _connectivity.onConnectivityChanged.listen((List<ConnectivityResult> results) {
      final newResult = results.contains(ConnectivityResult.mobile)
          ? ConnectivityResult.mobile
          : results.contains(ConnectivityResult.wifi)
              ? ConnectivityResult.wifi
              : results.contains(ConnectivityResult.none)
                  ? ConnectivityResult.none
                  : ConnectivityResult.other;

      _internalUpdateConnectionStatus(newResult);
    });
  }

  /// Disposes the connectivity handler resources. Call this in dispose.
  void disposeConnectivityHandler() {
    _connectivitySubscription.cancel();
  }

  /// Performs the initial connectivity check.
  Future<void> _internalInitConnectivity() async {
    try {
      var connectivityResults = await _connectivity.checkConnectivity();
      final initialResult = connectivityResults.contains(ConnectivityResult.mobile)
          ? ConnectivityResult.mobile
          : connectivityResults.contains(ConnectivityResult.wifi)
              ? ConnectivityResult.wifi
              : connectivityResults.contains(ConnectivityResult.none)
                  ? ConnectivityResult.none
                  : ConnectivityResult.other;

      await _internalUpdateConnectionStatus(initialResult, isInitialCheck: true);
    } catch (e) {
      debugPrint('$connectivityLogPrefix Error during initial connectivity check: $e');
      // Default to offline on error
      await _internalUpdateConnectionStatus(ConnectivityResult.none, isInitialCheck: true);
    }
  }

  /// Updates the connection status and triggers appropriate data loading.
  Future<void> _internalUpdateConnectionStatus(ConnectivityResult result, {bool isInitialCheck = false}) async {
    // Only react if the status is actually different
    if (result == _connectionStatus) {
      debugPrint('$connectivityLogPrefix Connectivity status unchanged: $result');
      return;
    }

    debugPrint('$connectivityLogPrefix Connectivity status changed: From $_connectionStatus to $result');
    final previousStatus = _connectionStatus;
    _connectionStatus = result; // Update current status

    // Determine current and previous online state
    bool wasOnline = previousStatus != null && previousStatus != ConnectivityResult.none;
    bool isOnline = result == ConnectivityResult.mobile || result == ConnectivityResult.wifi;

    // --- Handle State Transitions ---
    if (isOnline && !wasOnline) {
      // --- Transitioning TO Online ---
      _isOffline = false;
      debugPrint('$connectivityLogPrefix Transitioning Online: $result. Loading data from server...');
      await loadDataFromServer(); // Call the implementation from the consuming class
    } else if (!isOnline && wasOnline) {
      // --- Transitioning TO Offline ---
      _isOffline = true;
      debugPrint('$connectivityLogPrefix Transitioning Offline: $result. Disposing liveList and loading from cache...');
      disposeLiveList(); // Call the implementation
      await loadDataFromCache(); // Call the implementation
    } else if (isInitialCheck) {
      // --- Handle Initial State (only runs once) ---
      if (isOnline) {
        _isOffline = false;
        debugPrint('$connectivityLogPrefix Initial State Online: $result. Loading data from server...');
        await loadDataFromServer();
      } else {
        _isOffline = true;
        debugPrint('$connectivityLogPrefix Initial State Offline: $result. Loading from cache...');
        // Only load from cache if offline mode is actually enabled
        if (isOfflineModeEnabled) {
           await loadDataFromCache();
        } else {
           debugPrint('$connectivityLogPrefix Offline mode disabled, skipping initial cache load.');
           // Optionally clear items or show empty state here if needed
        }
      }
    } else {
      // --- No Online/Offline Transition ---
      debugPrint('$connectivityLogPrefix Connectivity changed within same state (Online/Offline): $result');
      // Optional: Reload data even if staying online (e.g., wifi -> mobile)
      // if (isOnline) {
      //   await loadDataFromServer();
      // }
    }
  }
}