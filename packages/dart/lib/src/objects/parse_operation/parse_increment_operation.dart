part of flutter_parse_sdk;

class _ParseIncrementOperation extends _ParseOperation<num> {
  _ParseIncrementOperation(num value) : super(value) {
    super.valueForApiRequest = 0.0;
  }

  @override
  String get operationName => 'Increment';

  @override
  void onSave() {
    super.onSave();

    valueForApiRequest = 0.0;
  }

  @override
  bool canMergeWith(Object other) {
    return other is _ParseIncrementOperation || other is num;
  }

  @override
  _ParseOperation<num> mergeWithPrevious(Object previous) {
    if (!canMergeWith(previous)) {
      throw _UnmergeableOperationException(this, previous);
    }

    valueForApiRequest += value;

    final num previousValue;

    if (previous is num) {
      previousValue = previous;
    } else {
      final previousIncrement = (previous as _ParseIncrementOperation);
      previousValue = previousIncrement.value;

      valueForApiRequest += previousIncrement.valueForApiRequest;
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
        'amount': valueForApiRequest,
        'estimatedValue': value
      };
    }

    return {'__op': operationName, 'amount': valueForApiRequest};
  }

  factory _ParseIncrementOperation.fromFullJson(Map<String, dynamic> json) {
    return _ParseIncrementOperation(json['estimatedValue'] as num)
      ..valueForApiRequest = json['amount'] as num;
  }
}
