part of flutter_parse_sdk;

abstract class _ParseOperation<T>
    with ParseSaveStateAwareChild
    implements _Valuable {
  T value;

  late T valueForApiRequest;

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

      if (previousValue == null || previousValue is! _ParseOperation) {
        return _ParseArray().preformArrayOperation(newValue);
      }
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
  _ParseArrayOperation(List value) : super(value) {
    super.valueForApiRequest = [];
  }

  @override
  void onSave() {
    super.onSave();

    valueForApiRequest.clear();
  }

  @override
  Map<String, dynamic> toJson({bool full = false}) {
    if (full) {
      return {
        '__op': operationName,
        'objects': parseEncode(value, full: full),
        'valueForAPIRequest': parseEncode(valueForApiRequest, full: full),
      };
    }

    return {'__op': operationName, 'objects': parseEncode(valueForApiRequest)};
  }

  static _ParseArrayOperation? fromFullJson(Map<String, dynamic>? json) {
    if (json == null) {
      return null;
    }

    final List objects =
        (json['objects'] as List).map((e) => parseDecode(e)).toList();

    final List? objectsForAPIRequest = (json['valueForAPIRequest'] as List?)
        ?.map((e) => parseDecode(e))
        .toList();

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

    arrayOperation.valueForApiRequest = objectsForAPIRequest ?? [];

    return arrayOperation;
  }
}

abstract class _ParseRelationOperation
    extends _ParseOperation<List<ParseObject>> {
  _ParseRelationOperation(List<ParseObject> value) : super(value) {
    super.valueForApiRequest = [];
  }

  @override
  void onSave() {
    super.onSave();

    valueForApiRequest.clear();
    value.clear();
  }

  @override
  Map<String, dynamic> toJson({bool full = false}) {
    return {'__op': operationName, 'objects': parseEncode(value, full: full)};
  }
}
