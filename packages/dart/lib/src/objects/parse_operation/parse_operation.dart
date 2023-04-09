part of flutter_parse_sdk;

abstract class _ParseOperation<T> implements _Valuable<T> {
  T value;

  late T valueForApiRequest;

  _ParseOperation(this.value);

  String get operationName;

  bool canMergeWith(Object other);

  _ParseOperation<T> mergeWithPrevious(Object previous) {
    if (!canMergeWith(previous)) {
      throw _UnmergeableOperationException(this, previous);
    }

    return merge(previous);
  }

  _ParseOperation<T> merge(Object previous);

  Map<String, dynamic> toJson({bool full = false});

  static Object? maybeMergeWithPrevious<R>({
    required R newValue,
    required Object? previousValue,
    required ParseObject parent,
    required String key,
  }) {
    if (newValue is List) {
      return _ParseArray(setMode: true)..estimatedArray = newValue;
    }

    if (newValue is num) {
      return _ParseNumber(newValue, setMode: true);
    }

    if (newValue is _ParseNumberOperation) {
      return _handelNumOperation(newValue, previousValue);
    }

    if (newValue is _ParseArrayOperation) {
      return _handelArrayOperation(newValue, previousValue);
    }

    if (newValue is _ParseRelationOperation) {
      return _handelRelationOperation(newValue, previousValue, parent, key);
    }

    return newValue;
  }

  static _ParseNumber _handelNumOperation(
    _ParseNumberOperation numberOperation,
    Object? previousValue,
  ) {
    if (previousValue is _ParseNumber) {
      return previousValue.preformNumberOperation(numberOperation);
    }

    if (previousValue == null) {
      return _ParseNumber(0).preformNumberOperation(numberOperation);
    } else {
      throw ParseOperationException(
          'wrong key, unable to preform numeric operation on'
          ' the previous value: ${previousValue.runtimeType}');
    }
  }

  static _ParseArray _handelArrayOperation(
    _ParseArrayOperation arrayOperation,
    Object? previousValue,
  ) {
    if (previousValue is _ParseArray) {
      return previousValue.preformArrayOperation(arrayOperation);
    }

    if (previousValue == null) {
      return _ParseArray().preformArrayOperation(arrayOperation);
    } else {
      throw ParseOperationException(
          'wrong key, unable to preform Array operation on'
          ' the previous value: ${previousValue.runtimeType}');
    }
  }

  static _ParseRelation _handelRelationOperation(
    _ParseRelationOperation relationOperation,
    Object? previousValue,
    ParseObject parent,
    String key,
  ) {
    if (previousValue is _ParseRelation) {
      return previousValue.preformRelationOperation(relationOperation);
    }

    if (previousValue == null) {
      return _ParseRelation(parent: parent, key: key)
          .preformRelationOperation(relationOperation);
    } else {
      throw ParseOperationException(
          'wrong key, unable to preform Relation operation on'
          ' the previous value: ${previousValue.runtimeType}');
    }
  }

  @override
  T getValue() {
    if (value is Iterable) {
      // return as new Iterable to prevent the user from mutating the internal list state
      return (value as Iterable).cast() as T;
    }

    return value;
  }
}

abstract class _ParseArrayOperation extends _ParseOperation<List> {
  _ParseArrayOperation(List value) : super(value) {
    super.valueForApiRequest = [];
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

    return {
      '__op': operationName,
      'objects': parseEncode(valueForApiRequest, full: full),
    };
  }

  static _ParseArrayOperation? fromFullJson(Map<String, dynamic> json) {
    final List objects = parseDecode(json['objects']);
    final List? objectsForAPIRequest = parseDecode(json['valueForAPIRequest']);

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
    extends _ParseOperation<Set<ParseObject>> {
  _ParseRelationOperation(Set<ParseObject> value) : super(value) {
    super.valueForApiRequest = {};
  }

  static _ParseRelationOperation? fromFullJson(Map<String, dynamic> json) {
    final Set<ParseObject> objects =
        Set.from(parseDecode(json['objects']) ?? {});

    final Set<ParseObject>? objectsForAPIRequest =
        json['valueForAPIRequest'] == null
            ? null
            : Set.from(parseDecode(json['valueForAPIRequest']));

    final _ParseRelationOperation relationOperation;
    switch (json['__op']) {
      case 'AddRelation':
        relationOperation = _ParseAddRelationOperation(objects);
        break;
      case 'RemoveRelation':
        relationOperation = _ParseRemoveRelationOperation(objects);
        break;

      default:
        return null;
    }

    relationOperation.valueForApiRequest = objectsForAPIRequest ?? {};

    return relationOperation;
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
    return {'__op': operationName, 'objects': parseEncode(value, full: full)};
  }
}

abstract class _ParseNumberOperation extends _ParseOperation<num> {
  _ParseNumberOperation(num value) : super(value) {
    super.valueForApiRequest = value;
  }

  @override
  Map<String, dynamic> toJson({bool full = false}) {
    if (full) {
      return {
        '__op': operationName,
        'amount': valueForApiRequest,
        'estimatedValue': value
      };
    }

    return {'__op': operationName, 'amount': valueForApiRequest};
  }

  static _ParseNumberOperation? fromFullJson(Map<String, dynamic> json) {
    final num estimatedValueFromJson = json['estimatedValue'] as num;
    final num valueForApiRequestFromJson = json['amount'] as num;

    final _ParseNumberOperation parseNumberOperation;
    switch (json['__op']) {
      case 'Increment':
        parseNumberOperation = _ParseIncrementOperation(estimatedValueFromJson);
        break;
      default:
        return null;
    }

    parseNumberOperation.valueForApiRequest = valueForApiRequestFromJson;

    return parseNumberOperation;
  }
}
