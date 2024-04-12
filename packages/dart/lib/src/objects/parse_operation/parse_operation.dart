part of '../../../parse_server_sdk.dart';

/// Represents an operation performed on Parse data. It defines the core
/// functionality of any operation performed on Parse data.
abstract class _ParseOperation<T> implements _Valuable<T> {
  /// Used to store the estimated value for operation.
  ///
  /// This is what the user will see as the result of any operation on the data.
  /// For example, if the operation is an array addition and the user wants
  /// to add the value 4 to the list, and the list originally looks like this:
  /// [1,2,3], then the [value] variable will initially hold [1,2,3].
  /// After the addition operation is performed, the [value] variable will
  /// hold [1,2,3,4], which is what the user will see.
  /// The add operation itself will be stored in a separate variable,
  /// [valueForApiRequest], which will only hold the data that needs
  /// to be sent to the server, in this case [4].
  T value;

  /// The actual that will be sent to the server.
  late T valueForApiRequest;

  _ParseOperation(this.value);

  /// The name of the preformed operation.
  ///
  /// This value can be used when sending the operation to the server.
  ///
  /// e.g: Add, AddUnique, Remove, Increment, AddRelation, RemoveRelation
  String get operationName;

  /// Checks if [other] can be merged with the current operation.
  ///
  /// Some operations can be merged with others, and each operation defines
  /// what can be merged. For example, an Add operation can be merged with
  /// another Add operation or with a [_ParseArray] object.
  bool canMergeWith(Object other);

  /// Preform the merge between [previous] and current operation.
  ///
  /// This should be called after [canMergeWith] to check if the [previous]
  /// operation is eligible to merge with the current operation
  ///
  /// Will return the current(this) operation merged with the other(previous)
  /// operation
  _ParseOperation<T> merge(Object previous);

  /// Merges the current operation with the [previous] operation if possible.
  ///
  /// Throws a [_UnmergeableOperationException] if the [previous] operation
  /// cannot be merged with the current operation.
  _ParseOperation<T> mergeWithPrevious(Object previous) {
    if (!canMergeWith(previous)) {
      throw _UnmergeableOperationException(this, previous);
    }

    return merge(previous);
  }

  /// Convert the operation to json format (Map).
  ///
  /// Will be used to be sent the operation to the server or to store the
  /// operation in the cache. When [full] is true that should indicate that
  /// the intention of converting to json is to store the operation
  /// in the local cache
  Map<String, dynamic> toJson({bool full = false});

  /// construct a new value of [newValue] to be used in parse object.
  ///
  /// * If the [newValue] is [Iterable] will return [_ParseArray]
  /// * If the [newValue] is [num] will return [_ParseNumber]
  /// * If the [newValue] is [_ParseOperation] will try to merge the this
  /// operation with the [previousValue] and return this operation merged
  /// with the [previousValue] if possible.
  /// * Otherwise will return the [newValue] as it is.
  static Object? maybeMergeWithPrevious<R>({
    required R newValue,
    required Object? previousValue,
    required ParseObject parent,
    required String key,
  }) {
    if (newValue is Iterable) {
      return _ParseArray(setMode: true)..estimatedArray = newValue.toList();
    }

    if (newValue is num) {
      return _ParseNumber(newValue, setMode: true);
    }

    if (newValue is _ParseOperation) {
      return _handelOperation<R>(newValue, previousValue, parent, key);
    }

    return newValue;
  }

  static Object _handelOperation<R>(
    R newValue,
    Object? previousValue,
    ParseObject parent,
    String key,
  ) {
    if (newValue is _ParseNumberOperation) {
      return _handelNumOperation(newValue, previousValue);
    }

    if (newValue is _ParseArrayOperation) {
      return _handelArrayOperation(newValue, previousValue);
    }

    if (newValue is _ParseRelationOperation) {
      return _handelRelationOperation(newValue, previousValue, parent, key);
    }

    throw ParseOperationException(
        'operation ${newValue.runtimeType} not implemented');
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
    }

    throw ParseOperationException(
        'wrong key, unable to preform numeric operation on'
        ' the previous value: ${previousValue.runtimeType}');
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
    }

    throw ParseOperationException(
        'wrong key, unable to preform Array operation on'
        ' the previous value: ${previousValue.runtimeType}');
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
    }

    throw ParseOperationException(
        'wrong key, unable to preform Relation operation on'
        ' the previous value: ${previousValue.runtimeType}');
  }

  /// Returns the estimated value of this operation.
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
  _ParseArrayOperation(super.value) {
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
  _ParseRelationOperation(super.value) {
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
    return {
      '__op': operationName,
      'objects': parseEncode(valueForApiRequest, full: full)
    };
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
