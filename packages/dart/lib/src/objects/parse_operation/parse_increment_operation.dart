part of flutter_parse_sdk;

class _ParseIncrementOperation extends _ParseOperation<num> {
  _ParseIncrementOperation(num value) : super(value);

  @override
  String get operationName => 'Increment';

  @override
  bool canMergeWith(Object other) {
    return other is _ParseIncrementOperation || other is num;
  }

  @override
  _ParseOperation<num> mergeWithPrevious(Object previous) {
    if (!canMergeWith(previous)) {
      throw _UnmergeableOperationException(this, previous);
    }

    final num previousValue;

    if (previous is num) {
      previousValue = previous;
    } else {
      previousValue = (previous as _ParseIncrementOperation).value;
    }

    value = value + previousValue;

    return this;
  }

  @override
  Map<String, dynamic> toJson({bool full = false}) {
    return {'__op': operationName, 'amount': value};
  }
}
