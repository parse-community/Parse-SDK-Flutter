part of flutter_parse_sdk;

class UnmergeableOperationException implements Exception {
  final ParseOperation current;
  final ParseOperation other;

  const UnmergeableOperationException(this.current, this.other);

  @override
  String toString() {
    return '${other.operationName} operation is invalid after '
        '${current.operationName} operation';
  }
}

abstract class ParseOperation<T> {
  String get operationName;

  T? _valueOperation;

  T? get value;

  set value(T? value);

  bool canMergeWith(ParseOperation other);

  ParseOperation<T> mergeWith(ParseOperation other);

  ParseOperation<T>? maybeMergeWith(ParseOperation other) {
    if (canMergeWith(other)) {
      return mergeWith(other);
    }
    return null;
  }

  Map<String, dynamic> toJson();
}

class IncrementOperation extends ParseOperation<num> {
  @override
  String get operationName => 'Increment';

  @override
  num? value;

  @override
  bool canMergeWith(ParseOperation other) {
    return other is IncrementOperation;
  }

  @override
  ParseOperation<num> mergeWith(ParseOperation other) {
    if (!canMergeWith(other)) {
      throw UnmergeableOperationException(this, other);
    }

    (other as IncrementOperation);

    value ??= 0;

    if (other.value == null) {
      value = null;
    } else {
      value = value! + other.value!;
    }

    return this;
  }

  @override
  Map<String, dynamic> toJson() {
    return {'__op': operationName, 'amount': value};
  }
}
