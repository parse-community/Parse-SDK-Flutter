part of flutter_parse_sdk;

class _ParseAddOperation extends _ParseArrayOperation {
  _ParseAddOperation(List value) : super(value);

  @override
  String get operationName => 'Add';

  @override
  bool canMergeWith(Object other) {
    return other is _ParseAddOperation || other is _ParseArray;
  }

  @override
  _ParseOperation<List> merge(Object previous) {
    final List previousValue;

    if (previous is _ParseArray) {
      previousValue = previous.estimatedArray;

      if (previous.savedArray.isEmpty) {
        valueForApiRequest.addAll(previous.estimatedArray);
      }
    } else {
      final previousAdd = (previous as _ParseAddOperation);

      previousValue = previousAdd.value;

      valueForApiRequest.addAll(previousAdd.valueForApiRequest);
    }

    valueForApiRequest.addAll(value);

    value = [...previousValue, ...value];

    return this;
  }
}
