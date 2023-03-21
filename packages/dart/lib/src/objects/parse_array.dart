part of flutter_parse_sdk;

class _ParseArray implements _Valuable {
  _ParseArray();

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
        'lastPreformedOperation': lastPreformedOperation?.toJson()
      };
    }

    return lastPreformedOperation?.toJson() ?? parseEncode(estimatedArray);
  }

  factory _ParseArray.fromFullJson(Map<String, dynamic> json) {
    return _ParseArray()
      ..savedArray = parseDecode(json['savedArray'])
      ..estimatedArray = parseDecode(json['estimatedArray'])
      ..lastPreformedOperation =
          _ParseArrayOperation.fromJson(json['lastPreformedOperation']);
  }

  @override
  Object? getValue() {
    return estimatedArray.toList();
  }
}
