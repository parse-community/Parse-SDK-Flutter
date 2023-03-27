part of flutter_parse_sdk;

class _ParseRemoveRelationOperation extends _ParseRelationOperation {
  _ParseRemoveRelationOperation(Set<ParseObject> value) : super(value);

  @override
  String get operationName => 'RemoveRelation';

  @override
  bool canMergeWith(Object other) {
    return other is _ParseRemoveRelationOperation || other is _ParseRelation;
  }

  @override
  _ParseOperation<Set<ParseObject>> merge(Object previous) {
    final Set<ParseObject> previousValue;

    // if (previous is List<ParseObject>) {
    //   previousValue = previous;
    // } else {
    //   previousValue = (previous as _ParseRemoveRelationOperation).value;
    // }

    // previousValue.addAll(value);
    // value = previousValue.toSet().toList();

    return this;
  }
}
