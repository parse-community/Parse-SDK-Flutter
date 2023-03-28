part of flutter_parse_sdk;

abstract class ParseException implements Exception {}

class ParseRelationException implements ParseException {
  final String? message;

  const ParseRelationException([this.message]);

  @override
  String toString() {
    if (message == null) return "ParseRelationException";
    return "ParseRelationException: $message";
  }
}

class ParseOperationException implements ParseException {
  final String? message;

  const ParseOperationException([this.message]);

  @override
  String toString() {
    if (message == null) return "ParseOperationException";
    return "ParseOperationException: $message";
  }
}

class _UnmergeableOperationException extends ParseOperationException {
  final _ParseOperation current;
  final Object previous;

  const _UnmergeableOperationException(this.current, this.previous);

  @override
  String toString() {
    if (previous is _ParseOperation) {
      return '${current.operationName} operation is invalid after '
          '${(previous as _ParseOperation).operationName} operation';
    }

    return 'can not perform ${current.operationName} merge operation on the previous value $previous';
  }
}
