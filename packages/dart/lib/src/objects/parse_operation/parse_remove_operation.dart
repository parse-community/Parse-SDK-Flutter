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
  _ParseOperation<List> merge(Object previous) {
    final List previousValue;

    valueForApiRequest.addAll(value.toSet());

    if (previous is _ParseArray) {
      previousValue = previous.estimatedArray;
    } else {
      final previousRemove = (previous as _ParseRemoveOperation);

      previousValue = previousRemove.value;

      valueForApiRequest = {
        ...valueForApiRequest,
        ...previousRemove.valueForApiRequest,
      }.toList();
    }

    value = [...previousValue]..removeWhere((e) => value.contains(e));

    return this;
  }
}
