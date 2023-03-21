part of flutter_parse_sdk;

class _ParseRemoveOperation extends _ParseArrayOperation {
  _ParseRemoveOperation(List value) : super(value);

  @override
  String get operationName => 'Remove';

  @override
  bool canMergeWith(Object other) {
    return other is _ParseRemoveOperation || other is _ParseArray;
  }

  @override
  _ParseOperation<List> mergeWithPrevious(Object previous) {
    if (!canMergeWith(previous)) {
      throw _UnmergeableOperationException(this, previous);
    }

    final List previousValue;

    if (previous is _ParseArray) {
      previousValue = previous.estimatedArray;

      if (previous.savedArray.isEmpty) {
        throw ParseOperationException('Can not remove from unsaved array');
      }

      valueForAPIRequest.addAll(value.where(
        (e) => previous.savedArray.contains(e),
      ));
    } else {
      final previousRemove = (previous as _ParseRemoveOperation);

      previousValue = previousRemove.value;

      valueForAPIRequest.addAll([
        ...previousRemove.valueForAPIRequest,
        ...value,
      ]);
    }

    value = [...previousValue]..removeWhere((e) => value.contains(e));

    return this;
  }
}
