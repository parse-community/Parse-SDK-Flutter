part of '../../../parse_server_sdk.dart';

/// An operation that increment a numeric value by a given amount
class _ParseIncrementOperation extends _ParseNumberOperation {
  _ParseIncrementOperation(super.value);

  @override
  String get operationName => 'Increment';

  @override
  bool canMergeWith(Object other) {
    return other is _ParseIncrementOperation || other is _ParseNumber;
  }

  @override
  _ParseOperation<num> merge(Object previous) {
    final num previousValue;

    if (previous is _ParseNumber) {
      previousValue = previous.estimateNumber;
      valueForApiRequest += previous.estimateNumber - previous.savedNumber;
    } else {
      final previousIncrement = (previous as _ParseIncrementOperation);
      previousValue = previousIncrement.value;

      valueForApiRequest += previousIncrement.valueForApiRequest;
    }

    value = value + previousValue;

    return this;
  }
}
