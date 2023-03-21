part of flutter_parse_sdk;

class _ParseAddUniqueOperation extends _ParseArrayOperation {
  _ParseAddUniqueOperation(List value) : super(value);

  @override
  String get operationName => 'AddUnique';

  @override
  bool canMergeWith(Object other) {
    return other is _ParseAddUniqueOperation || other is _ParseArray;
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
        valueForAPIRequest.addAll({...previous.estimatedArray, ...value});
      } else {
        final estimatedSet = previous.estimatedArray.toSet();
        final savedSet = previous.savedArray.toSet();

        final valuesToBeAddedUniquely = estimatedSet.difference(savedSet);

        valueForAPIRequest.addAll({...valuesToBeAddedUniquely, ...value});
      }
    } else {
      final previousAddUnique = (previous as _ParseAddUniqueOperation);

      previousValue = previousAddUnique.value;

      valueForAPIRequest.addAll({
        ...previousAddUnique.valueForAPIRequest,
        ...value,
      });
    }

    value = [
      ...previousValue,
      ...value.where((e) => previousValue.contains(e) == false),
    ];

    return this;
  }
}
