part of flutter_parse_sdk;

class _ParseAddRelationOperation extends _ParseRelationOperation {
  _ParseAddRelationOperation(Set<ParseObject> value) : super(value);

  @override
  String get operationName => 'AddRelation';

  @override
  bool canMergeWith(Object other) {
    return other is _ParseAddRelationOperation || other is _ParseRelation;
  }

  @override
  _ParseOperation<Set<ParseObject>> merge(Object previous) {
    final Set<ParseObject> previousValue;

    if (previous is _ParseRelation) {
      previousValue = value.toSet();
    } else {
      previousValue = (previous as _ParseAddRelationOperation).value;
    }

    value = {
      ...previousValue,
      ...value.where((e) => previousValue.contains(e) == false),
    };

    value = Set.from(removeDuplicateParseObjectByObjectId(value));
    valueForApiRequest =
        Set.from(removeDuplicateParseObjectByObjectId(valueForApiRequest));

    return this;
  }
}
