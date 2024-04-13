part of '../../../parse_server_sdk.dart';

/// An operation that Removes objects from a [ParseRelation]
class _ParseRemoveRelationOperation extends _ParseRelationOperation {
  _ParseRemoveRelationOperation(super.value);

  @override
  String get operationName => 'RemoveRelation';

  @override
  bool canMergeWith(Object other) {
    return other is _ParseRemoveRelationOperation || other is _ParseRelation;
  }

  @override
  _ParseOperation<Set<ParseObject>> merge(Object previous) {
    Set<ParseObject> previousValue = {};

    if (previous is _ParseRelation) {
      previousValue = previous.knownObjects.toSet();
    } else {
      final previousRemove = (previous as _ParseRemoveRelationOperation);

      previousValue = previousRemove.value.toSet();

      valueForApiRequest.addAll(previousRemove.valueForApiRequest);
    }

    valueForApiRequest.addAll(value);

    final parseObjectToRemoveByIds =
        value.where((e) => e.objectId != null).map((e) => e.objectId!);

    value = previousValue
      ..removeWhere((e) =>
          value.contains(e) || parseObjectToRemoveByIds.contains(e.objectId));

    value = Set.from(removeDuplicateParseObjectByObjectId(value));

    valueForApiRequest =
        Set.from(removeDuplicateParseObjectByObjectId(valueForApiRequest));

    return this;
  }
}
