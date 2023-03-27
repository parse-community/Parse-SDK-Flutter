part of flutter_parse_sdk;

class _ParseIncrementOperation extends _ParseOperation<num>
    implements _ParseSaveStateAwareChild {
  _ParseIncrementOperation(num value) : super(value) {
    super.valueForApiRequest = 0.0;
  }

  @override
  String get operationName => 'Increment';

  @override
  bool canMergeWith(Object other) {
    return other is _ParseIncrementOperation || other is num;
  }

  @override
  _ParseOperation<num> merge(Object previous) {
    valueForApiRequest += value;

    final num previousValue;

    if (previous is num) {
      previousValue = previous;
    } else {
      final previousIncrement = (previous as _ParseIncrementOperation);
      previousValue = previousIncrement.value;

      valueForApiRequest += previousIncrement.valueForApiRequest;

      if (previousIncrement.valueForApiRequestBeforeSaving != null) {
        valueForApiRequestBeforeSaving =
            (valueForApiRequestBeforeSaving ?? 0.0) +
                previousIncrement.valueForApiRequestBeforeSaving!;
      }
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

  num? valueForApiRequestBeforeSaving;

  @override
  @mustCallSuper
  void onSaved() {
    if (valueForApiRequestBeforeSaving == valueForApiRequest) {
      // No operations were performed during the save process
      valueForApiRequest = 0.0;
    } else {
      // some operation performed during the save process subtract the saved value
      valueForApiRequest =
          valueForApiRequest - (valueForApiRequestBeforeSaving ?? 0.0);
    }

    valueForApiRequestBeforeSaving = null;
  }

  @override
  @mustCallSuper
  void onSaving() {
    valueForApiRequestBeforeSaving = valueForApiRequest;
  }

  @override
  @mustCallSuper
  void onRevertSaving() {
    valueForApiRequestBeforeSaving = null;
  }
}
