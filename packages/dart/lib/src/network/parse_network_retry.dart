part of '../../parse_server_sdk.dart';

/// Executes a network operation with automatic retry on transient failures.
///
/// This function will retry REST API requests that fail due to network issues,
/// such as receiving HTML error pages from proxies/load balancers instead of
/// JSON responses, or experiencing connection failures.
///
/// Retries are performed based on [ParseCoreData.restRetryIntervals].
/// Each retry is delayed according to the corresponding interval in milliseconds.
/// The maximum number of retries is enforced to prevent excessive retry attempts
/// (limited to 100 retries maximum).
///
/// Retry Conditions:
///
/// A request will be retried if:
/// - Status code is `-1` (indicates network/parsing error, including HTML responses from proxies/load balancers)
///   (HTML detection and conversion to status -1 happens in the HTTP client layer)
/// - An exception is thrown during the request
///
/// A request will NOT be retried for:
/// - Successful responses (status 200, 201)
/// - Valid Parse Server errors (e.g., 101 for object not found)
///
/// Important Note on Non-Idempotent Methods (POST/PUT):
///
/// **While Parse Server supports idempotency headers for preventing duplicate
/// requests, this SDK does not currently implement that feature.** To prevent
/// duplicate data creation or unintended state changes, this SDK defaults to
/// **no retries** for write operations (POST/PUT/postBytes).
///
/// Default Behavior:
/// - **Write operations (POST/PUT)**: No retries (`restRetryIntervalsForWrites = []`)
/// - **Read operations (GET)**: Retries enabled (`restRetryIntervals = [0, 250, 500, 1000, 2000]`)
/// - **DELETE operations**: Retries enabled (generally safe to retry)
///
/// If you need to enable retries for write operations, configure
/// `restRetryIntervalsForWrites` during initialization. Consider these mitigations:
/// - Implement application-level idempotency keys or version tracking
/// - Use Parse's experimental `X-Parse-Request-Id` header (if available)
///   with explicit duplicate detection in your application logic
/// - Use conservative retry intervals (e.g., `[1000, 2000]`) to allow time
///   for server-side processing before retrying
///
/// Example:
/// ```dart
/// await Parse().initialize(
///   'appId',
///   'serverUrl',
///   // Enable retries for writes (use with caution)
///   restRetryIntervalsForWrites: [1000, 2000],
/// );
/// ```
///
/// Note: Retries only occur on network-level failures (status -1), not on
/// successful operations that return Parse error codes
///
/// Example:
///
/// ```dart
/// final response = await executeWithRetry(
///   operation: () async {
///     final result = await client.get(url);
///     return result;
///   },
///   debug: true,
/// );
/// ```
///
/// Parameters:
///
/// - [operation]: The network operation to execute and potentially retry
/// - [isWriteOperation]: Whether this is a write operation (POST/PUT).
///   Defaults to `false`. When `true`, uses [ParseCoreData.restRetryIntervalsForWrites]
///   which defaults to no retries to prevent duplicate creates/updates.
/// - [debug]: Whether to log retry attempts (defaults to [ParseCoreData.debug])
///
/// Returns:
///
/// The final response (either [ParseNetworkResponse] or [ParseNetworkByteResponse])
/// after all retry attempts are exhausted.
Future<T> executeWithRetry<T extends ParseNetworkResponse>({
  required Future<T> Function() operation,
  bool isWriteOperation = false,
  bool? debug,
}) async {
  final List<int> retryIntervals = isWriteOperation
      ? ParseCoreData().restRetryIntervalsForWrites
      : ParseCoreData().restRetryIntervals;
  final bool debugEnabled = debug ?? ParseCoreData().debug;

  // Enforce maximum retry limit to prevent excessive attempts
  const int maxRetries = 100;
  if (retryIntervals.length > maxRetries) {
    throw ArgumentError(
      'restRetryIntervals cannot exceed $maxRetries elements '
      '(which allows up to ${maxRetries + 1} total attempts). '
      'Current length: ${retryIntervals.length}',
    );
  }

  int attemptNumber = 0;
  T? lastResponse;

  // Attempt initial request plus retries based on interval list
  for (int i = 0; i <= retryIntervals.length; i++) {
    attemptNumber = i + 1;

    try {
      lastResponse = await operation();

      // Check if we should retry this response
      if (!_shouldRetryResponse(lastResponse)) {
        // Success or non-retryable error - return immediately
        if (debugEnabled && i > 0) {
          print(
            'Parse REST retry: Attempt $attemptNumber succeeded after $i ${i == 1 ? 'retry' : 'retries'}',
          );
        }
        return lastResponse;
      }

      // If this was the last attempt, return the failure
      if (i >= retryIntervals.length) {
        if (debugEnabled) {
          print(
            'Parse REST retry: All $attemptNumber attempts failed, returning error',
          );
        }
        return lastResponse;
      }

      // Wait before next retry
      final int delayMs = retryIntervals[i];
      if (debugEnabled) {
        print(
          'Parse REST retry: Attempt $attemptNumber failed (status: ${lastResponse.statusCode}), '
          'retrying in ${delayMs}ms... (${i + 1}/${retryIntervals.length} retries)',
        );
      }
      await Future<void>.delayed(Duration(milliseconds: delayMs));
    } catch (e) {
      // If this was the last attempt, rethrow the exception
      if (i >= retryIntervals.length) {
        if (debugEnabled) {
          print(
            'Parse REST retry: All $attemptNumber attempts failed with exception: $e',
          );
        }
        rethrow;
      }

      // Wait before next retry
      final int delayMs = retryIntervals[i];
      if (debugEnabled) {
        print(
          'Parse REST retry: Attempt $attemptNumber threw exception: $e, '
          'retrying in ${delayMs}ms... (${i + 1}/${retryIntervals.length} retries)',
        );
      }
      await Future<void>.delayed(Duration(milliseconds: delayMs));
    }
  }

  // This should never be reached due to the loop logic above
  throw StateError(
    'Retry loop completed without returning or rethrowing. '
    'This indicates a logic error.',
  );
}

/// Determines if a network response should be retried.
///
/// Returns `true` if the response indicates a transient network error
/// that might succeed on retry, `false` otherwise.
///
/// Retry Triggers:
///
/// - Status code `-1` (network/parsing errors from the HTTP client layer)
///   Note: HTML responses, socket exceptions, timeouts, and parse errors
///   are converted to status -1 by the HTTP client before reaching here.
///
/// No Retry:
///
/// - Status code 200 or 201 (success)
/// - Valid Parse Server error codes (e.g., 100-series errors)
///   - These are application-level errors that won't resolve with retries
bool _shouldRetryResponse(ParseNetworkResponse response) {
  // Retry all -1 status codes (network/parse errors, including HTML from proxies)
  return response.statusCode == ParseError.otherCause;
}
