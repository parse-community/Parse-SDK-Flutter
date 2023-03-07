import 'package:parse_server_sdk/parse_server_sdk.dart';
import 'package:test/test.dart';

/// If an unmergeable operation [testingOn] is attempted after an operation,
/// it should result in an exception being thrown. in context of the same key.
///
/// So for example you can call setAdd after setAddAll on the same key, because
/// the values can be merged together. but calling setAdd after setIncrement
/// will throw an error because you can not increment a value and then add a
/// value to it like a list, it is not a list in the first place to be able
/// to add to it.
///
///
/// if a certain operation cannot be merged or combined with other operations
/// in a particular context, then an exception should be thrown to alert
/// the developer that the operation cannot be performed.
///
/// List of available operations:
/// * setAdd
/// * setAddUnique
/// * setAddAll
/// * setAddAllUnique
/// * setRemove
/// * setRemoveAll
/// * setIncrement
/// * setDecrement
/// * addRelation
/// * removeRelation
///
/// e.g.
/// ```dart
///    testUnmergeableOperationShouldThrow(
///      parseObject: dietPlansObject,
///      testingOn: dietPlansObject.setDecrement,
///      excludeMergeableOperations: [dietPlansObject.setIncrement],
///   );
/// ```
void testUnmergeableOperationShouldThrow({
  required ParseObject parseObject,
  required Function testingOn,
  List<Function> excludeMergeableOperations = const [],
}) {
  String testingOnKey = 'key';

  final Map<Function, List> operationsFuncRefWithArgs = {
    parseObject.setAdd: [
      testingOnKey,
      1,
    ],
    parseObject.setAddUnique: [
      testingOnKey,
      1,
    ],
    parseObject.setAddAll: [
      testingOnKey,
      [1, 2],
    ],
    parseObject.setAddAllUnique: [
      testingOnKey,
      [1, 2],
    ],
    parseObject.setRemove: [
      testingOnKey,
      1,
    ],
    parseObject.setRemoveAll: [
      testingOnKey,
      [1, 2]
    ],
    parseObject.setIncrement: [
      testingOnKey,
      1,
    ],
    parseObject.setDecrement: [
      testingOnKey,
      1,
    ],
    parseObject.addRelation: [
      testingOnKey,
      [ParseObject('class')]
    ],
    parseObject.removeRelation: [
      testingOnKey,
      [ParseObject('class')]
    ],
  };

  final testingOnValue = operationsFuncRefWithArgs.remove(testingOn);

  for (final functionExclude in excludeMergeableOperations) {
    operationsFuncRefWithArgs.remove(functionExclude);
  }

  for (final operation in operationsFuncRefWithArgs.entries) {
    parseObject.unset(testingOnKey, offlineOnly: true);

    final functionRef = operation.key;
    final positionalArguments = operation.value;

    Function.apply(functionRef, positionalArguments);

    expect(
      () => Function.apply(testingOn, testingOnValue),
      throwsA(isA<String>()),
    );
  }
}
