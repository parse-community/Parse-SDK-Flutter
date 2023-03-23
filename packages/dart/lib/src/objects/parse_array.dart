part of flutter_parse_sdk;

class _ParseArray with ParseSaveStateAwareChild implements _Valuable {
  _ParseArray();

  @override
  void onSave() {
    super.onSave();

    _savedArray.clear();
    _savedArray.addAll(estimatedArray);

    lastPreformedOperation = null;
  }

  List _savedArray = [];
  List estimatedArray = [];

  set savedArray(List array) {
    estimatedArray = _savedArray = array.toList();
  }

  List get savedArray => _savedArray;

  _ParseArrayOperation? lastPreformedOperation;

  _ParseArray preformArrayOperation(_ParseArrayOperation arrayOperation) {
    arrayOperation.mergeWithPrevious(
      lastPreformedOperation ?? this,
    );

    lastPreformedOperation = arrayOperation;

    estimatedArray = lastPreformedOperation!.value.toList();

    return this;
  }

  Object toJson({bool full = false}) {
    if (full) {
      return {
        'className': 'ParseArray',
        'estimatedArray': parseEncode(estimatedArray, full: full),
        'savedArray': parseEncode(savedArray, full: full),
        'lastPreformedOperation': lastPreformedOperation?.toJson(full: full)
      };
    }

    return lastPreformedOperation?.toJson() ?? parseEncode(estimatedArray);
  }

  factory _ParseArray.fromFullJson(Map<String, dynamic> json) {
    return _ParseArray()
      ..savedArray =
          (json['savedArray'] as List).map((e) => parseDecode(e)).toList()
      ..estimatedArray =
          (json['estimatedArray'] as List).map((e) => parseDecode(e)).toList()
      ..lastPreformedOperation =
          _ParseArrayOperation.fromFullJson(json['lastPreformedOperation']);
  }

  @override
  Object? getValue() {
    return estimatedArray.toList();
  }
}
