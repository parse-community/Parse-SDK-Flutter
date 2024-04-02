part of '../../parse_server_sdk.dart';

/// A unified interface used to expose the internal state of a private class.
///
/// Use this interface to expose internal state to end users.
/// For example, [_ParseArray] implements this interface to expose
/// its [estimatedArray] property to end-users.
///
/// Note that any state exposed through this interface will be directly
/// accessible to end users. To prevent unintended manipulation, return copies
/// of internal state rather than references.
abstract class _Valuable<T> {
  /// provide access to an internal value of a class
  T getValue();
}
