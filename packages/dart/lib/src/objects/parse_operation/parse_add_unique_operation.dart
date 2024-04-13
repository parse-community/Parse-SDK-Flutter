part of '../../../parse_server_sdk.dart';

/// An operation that adds a new element to an array field,
/// only if it wasn't already present
class _ParseAddUniqueOperation extends _ParseArrayOperation {
  _ParseAddUniqueOperation(super.value);

  @override
  String get operationName => 'AddUnique';

  @override
  bool canMergeWith(Object other) {
    return other is _ParseAddUniqueOperation || other is _ParseArray;
  }

  @override
  _ParseOperation<List> merge(Object previous) {
    final List previousValue;

    value = value.toSet().toList();

    // if the previous is _ParseArray this indicates that this operation
    // is the first operation on this array
    if (previous is _ParseArray) {
      previousValue = previous.estimatedArray;

      if (previous.savedArray.isEmpty) {
        valueForApiRequest.addAll(previous.estimatedArray.toSet());
      }
    } else {
      final previousAddUnique = (previous as _ParseAddUniqueOperation);

      previousValue = previousAddUnique.value;

      valueForApiRequest.addAll(previousAddUnique.valueForApiRequest);
    }

    valueForApiRequest.addAll(value);

    value = [
      ...previousValue,
      ...value.where((element) => !previousValue.contains(element)),
    ];

    value = removeDuplicateParseObjectByObjectId(value);

    valueForApiRequest =
        removeDuplicateParseObjectByObjectId(valueForApiRequest);

    return this;
  }
}
