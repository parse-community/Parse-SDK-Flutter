part of flutter_parse_sdk;

class _ParseIncrementOperation extends _ParseOperation<num> {
  num incrementAmountForApiRequest = 0;

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

    incrementAmountForApiRequest += value;

    final num previousValue;

    if (previous is num) {
      previousValue = previous;
    } else {
      final previousIncrement = (previous as _ParseIncrementOperation);
      previousValue = previousIncrement.value;

      incrementAmountForApiRequest +=
          previousIncrement.incrementAmountForApiRequest;
    }

    value = value + previousValue;

    return this;
  }

  @override
  Map<String, dynamic> toJson({bool full = false}) {
    if (full) {
      return {
        'className': 'ParseIncrementOperation',
        '__op': operationName,
        'amount': incrementAmountForApiRequest,
        'estimatedValue': value
      };
    }

    return {'__op': operationName, 'amount': incrementAmountForApiRequest};
  }

  factory _ParseIncrementOperation.fromFullJson(Map<String, dynamic> json) {
    return _ParseIncrementOperation(json['estimatedValue'] as num)
      ..incrementAmountForApiRequest = json['amount'] as num;
  }
}
