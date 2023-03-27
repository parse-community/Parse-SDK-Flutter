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
  _ParseOperation<List> merge(Object previous) {
    final List previousValue;

    if (previous is _ParseArray) {
      previousValue = previous.estimatedArray;

      // if the previous is _ParseArray then its the first unique add operation on this list
      // we should make all the values unique before using them
      value = value.toSet().toList();

      if (previous.savedArray.isEmpty) {
        valueForApiRequest.addAll({...previous.estimatedArray, ...value});
      } else {
        final estimatedSet = previous.estimatedArray.toSet();
        final savedSet = previous.savedArray.toSet();

        final valuesToBeAddedUniquely = estimatedSet.difference(savedSet);

        valueForApiRequest.addAll({...valuesToBeAddedUniquely, ...value});
      }
    } else {
      final previousAddUnique = (previous as _ParseAddUniqueOperation);

      previousValue = previousAddUnique.value;

      valueForApiRequest.addAll({
        ...previousAddUnique.valueForApiRequest,
        ...value,
      });
    }

    value = [
      ...previousValue,
      ...value.where((e) => previousValue.contains(e) == false),
    ];

    value = removeDuplicateParseObjectByObjectId(value);
    valueForApiRequest =
        removeDuplicateParseObjectByObjectId(valueForApiRequest);

    return this;
  }
}
