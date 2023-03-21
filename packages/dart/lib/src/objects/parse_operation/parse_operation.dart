part of flutter_parse_sdk;

abstract class _ParseOperation<T> implements _Valuable {
  T value;

  _ParseOperation(this.value);

  String get operationName;

  bool canMergeWith(Object other);

  _ParseOperation<T> mergeWithPrevious(Object previous);

  Map<String, dynamic> toJson({bool full = false});

  static Object? maybeMergeWithPrevious<R>({
    required R newValue,
    required Object? previousValue,
  }) {
    if (newValue is List) {
      return _ParseArray()..estimatedArray = newValue;
    }

    if (newValue is _ParseArrayOperation) {
      if (previousValue is _ParseArray) {
        return previousValue.preformArrayOperation(newValue);
      }
      return _ParseArray().preformArrayOperation(newValue);
    }

    if (newValue is! _ParseOperation || previousValue == null) {
      return newValue;
    }

    return newValue.mergeWithPrevious(previousValue);
  }

  @override
  Object? getValue() {
    if (value is Iterable) {
      // return as new list to prevent the user from mutating the internal list state
      return (value as Iterable).toList();
    }
    return value;
  }
}

abstract class _ParseArrayOperation extends _ParseOperation<List> {
  List valueForAPIRequest = [];

  _ParseArrayOperation(List value) : super(value);

  @override
  Map<String, dynamic> toJson({bool full = false}) {
    if (full) {
      return {
        '__op': operationName,
        'objects': parseEncode(value, full: full),
        'valueForAPIRequest': parseEncode(valueForAPIRequest, full: full),
      };
    }

    return {'__op': operationName, 'objects': parseEncode(valueForAPIRequest)};
  }

  static _ParseArrayOperation? fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return null;
    }

    final List objects = parseDecode(json['objects'] as List);
    final List? objectsForAPIRequest =
        parseDecode(json['valueForAPIRequest'] as List?);

    final _ParseArrayOperation arrayOperation;
    switch (json['__op']) {
      case 'Add':
        arrayOperation = _ParseAddOperation(objects);
        break;
      case 'Remove':
        arrayOperation = _ParseRemoveOperation(objects);
        break;
      case 'AddUnique':
        arrayOperation = _ParseAddUniqueOperation(objects);
        break;
      default:
        return null;
    }

    arrayOperation.valueForAPIRequest = objectsForAPIRequest ?? [];

    return arrayOperation;
  }
}

abstract class _ParseRelationOperation
    extends _ParseOperation<List<ParseObject>> {
  _ParseRelationOperation(List<ParseObject> value) : super(value);

  @override
  Map<String, dynamic> toJson({bool full = false}) {
    return {'__op': operationName, 'objects': parseEncode(value, full: full)};
  }
}
