part of flutter_parse_sdk;

/// An operation that adds new objects to a [ParseRelation]
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
    Set<ParseObject> previousValue = {};

    if (previous is _ParseRelation) {
      previousValue = previous.knownObjects.toSet();
    } else {
      final previousAdd = (previous as _ParseAddRelationOperation);

      previousValue = previousAdd.value.toSet();

      valueForApiRequest.addAll(previousAdd.valueForApiRequest);
    }

    valueForApiRequest.addAll(value);

    value = {...previousValue, ...value};

    value = Set.from(removeDuplicateParseObjectByObjectId(value));

    valueForApiRequest =
        Set.from(removeDuplicateParseObjectByObjectId(valueForApiRequest));

    return this;
  }
}
