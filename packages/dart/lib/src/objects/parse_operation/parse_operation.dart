part of flutter_parse_sdk;

abstract class _ParseOperation<T> implements _Valuable {
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

    if (newValue is _ParseRelationOperation) {
      if (previousValue is _ParseRelation) {
        return previousValue.preformRelationOperation(newValue);
      }

      if (previousValue == null || previousValue is! _ParseOperation) {
        return _ParseRelation(parent: parent, key: key)
            .preformRelationOperation(newValue);
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
  Map<String, dynamic> toJson({bool full = false}) {
    if (full) {
      return {
        '__op': operationName,
        'objects': parseEncode(value, full: true),
        'valueForAPIRequest': parseEncode(valueForApiRequest, full: true),
      };
    }

    return {'__op': operationName, 'objects': parseEncode(valueForApiRequest)};
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
        'objects': parseEncode(value, full: true),
        'valueForAPIRequest': parseEncode(valueForApiRequest, full: true),
      };
    }
    return {'__op': operationName, 'objects': parseEncode(value, full: false)};
  }
}
