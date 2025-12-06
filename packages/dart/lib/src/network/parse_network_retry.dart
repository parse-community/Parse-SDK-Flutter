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
/// - Status code is `-1` (indicates network/parsing error)
/// - Response body contains HTML markup (proxy/load balancer error)
/// - An exception is thrown during the request
///
/// A request will NOT be retried for:
/// - Successful responses (status 200, 201)
/// - Valid Parse Server errors (e.g., 101 for object not found)
///
/// Important Note on Non-Idempotent Methods (POST/PUT):
///
/// This retry mechanism is applied to ALL HTTP methods including POST and PUT.
/// While GET and DELETE are generally safe to retry, POST and PUT operations
/// may cause duplicate operations if the original request succeeded but the
/// response was lost or corrupted. Consider this when using retry intervals
/// with operations that modify server state.
///
/// In most Parse Server scenarios, this is acceptable because:
/// - Parse uses optimistic locking with object versions
/// - Many Parse operations are idempotent by design
/// - Retries only occur on network-level failures (status -1), not on
///   successful operations that return Parse error codes
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
/// - [debug]: Whether to log retry attempts (defaults to [ParseCoreData.debug])
///
/// Returns:
///
/// The final response (either [ParseNetworkResponse] or [ParseNetworkByteResponse])
/// after all retry attempts are exhausted.
Future<T> executeWithRetry<T extends ParseNetworkResponse>({
  required Future<T> Function() operation,
  bool? debug,
}) async {
  final List<int> retryIntervals = ParseCoreData().restRetryIntervals;
  final bool debugEnabled = debug ?? ParseCoreData().debug;

  // Enforce maximum retry limit to prevent excessive attempts
  const int maxRetries = 100;
  if (retryIntervals.length > maxRetries) {
    throw ArgumentError(
      'restRetryIntervals cannot exceed $maxRetries retries. '
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

  // Should never reach here, but return last response as fallback
  return lastResponse!;
}

/// Determines if a network response should be retried.
///
/// Returns `true` if the response indicates a transient network error
/// that might succeed on retry, `false` otherwise.
///
/// Retry Triggers:
///
/// - Status code `-1` (network/parsing errors)
/// - Response body starts with HTML tags (proxy/load balancer errors)
///
/// No Retry:
///
/// - Status code 200 or 201 (success)
/// - Valid Parse Server error codes (e.g., 100-series errors)
bool _shouldRetryResponse(ParseNetworkResponse response) {
  // Retry on status code -1 (network/parse errors)
  if (response.statusCode == ParseError.otherCause) {
    // Additional check: is it HTML instead of JSON?
    final String trimmedData = response.data.trimLeft().toLowerCase();

    // Check for common HTML patterns that indicate proxy/load balancer errors
    // More robust than just checking for '<' which could be in valid JSON strings
    if (trimmedData.startsWith('<!doctype') ||
        trimmedData.startsWith('<html') ||
        trimmedData.startsWith('<head') ||
        trimmedData.startsWith('<body')) {
      // HTML response indicates proxy/load balancer error
      return true;
    }

    // Other -1 errors (network issues, parse failures)
    return true;
  }

  // Don't retry successful responses or valid Parse API errors
  return false;
}
