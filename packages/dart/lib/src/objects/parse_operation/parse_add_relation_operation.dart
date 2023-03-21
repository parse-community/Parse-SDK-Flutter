part of flutter_parse_sdk;

class _ParseAddRelationOperation extends _ParseRelationOperation {
  _ParseAddRelationOperation(List<ParseObject> value) : super(value);

  @override
  String get operationName => 'AddRelation';

  @override
  bool canMergeWith(Object other) {
    return other is _ParseAddRelationOperation;
  }

  @override
  _ParseOperation<List<ParseObject>> mergeWithPrevious(Object previous) {
    if (!canMergeWith(previous)) {
      throw _UnmergeableOperationException(this, previous);
    }

    final List<ParseObject> previousValue;

    if (previous is List<ParseObject>) {
      previousValue = previous;
    } else {
      previousValue = (previous as _ParseAddRelationOperation).value;
    }

    previousValue.addAll(value);
    value = previousValue.toSet().toList();

    return this;
  }
}
