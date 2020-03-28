part of flutter_parse_sdk;

class ParseMergeTool {
  // merge method
  dynamic mergeWithPrevious(dynamic previous, dynamic values) {
    if (previous == null) {
      return values;
    }
    String previousAction = 'Set';
    if (previous is Map) {
      previousAction = previous['__op'];
    }
    if (values is Map) {
      if (values['__op'] == 'Add') {
        values = _mergeWithPreviousAdd(previousAction, previous, values);
      } else if (values['__op'] == 'Remove') {
        values = _mergeWithPreviousRemove(previousAction, previous, values);
      } else if (values['__op'] == 'Increment') {
        values = _mergeWithPreviousIncrement(previousAction, previous, values);
      } else if (values['__op'] == 'AddUnique') {
        values = _mergeWithPreviousAddUnique(previousAction, previous, values);
      } else if (values['__op'] == 'AddRelation') {
        values =
            _mergeWithPreviousAddRelation(previousAction, previous, values);
      } else if (values['__op'] == 'RemoveRelation') {
        values =
            _mergeWithPreviousRemoveRelation(previousAction, previous, values);
      }
    }
    return values;
  }

  // Add operation Merge
  dynamic _mergeWithPreviousAdd(
      String previousAction, dynamic previous, dynamic values) {
    if (previousAction == 'Set') {
      if (previous is List) {
        return List<dynamic>.from(previous)..addAll(values['objects']);
      } else {
        throw 'Unable to add an item to a non-array.';
      }
    }
    if (previousAction == 'Add') {
      if (values['objects'].length == 1) {
        previous['objects'].add(values['objects'].first);
      } else {
        previous['objects'].add(values['objects']);
      }
      values = previous;
    }
    if (previousAction == 'Increment') {
      throw 'Add operation is invalid after Increment operation';
    }
    if (previousAction == 'Remove') {
      throw 'Add operation is invalid after Remove operation';
    }
    if (previousAction == 'AddUnique') {
      throw 'Add operation is invalid after AddUnique operation';
    }
    if (previousAction == 'AddRelation') {
      throw 'Add operation is invalid after AddRelation operation';
    }
    if (previousAction == 'RemoveRelation') {
      throw 'Add operation is invalid after RemoveRelation operation';
    }
    return values;
  }

  // Remove operation Merge
  dynamic _mergeWithPreviousRemove(
      String previousAction, dynamic previous, dynamic values) {
    if (previousAction == 'Set') {
      return previous;
    }
    if (previousAction == 'Remove') {
      if (values['objects'].length == 1) {
        previous['objects'].add(values['objects'].first);
      } else {
        previous['objects'].add(values['objects']);
      }
      values = previous;
    }
    if (previousAction == 'Increment') {
      throw 'Remove operation is invalid after Increment operation';
    }
    if (previousAction == 'Add') {
      throw 'Remove operation is invalid after Add operation';
    }
    if (previousAction == 'AddUnique') {
      throw 'Remove operation is invalid after AddUnique operation';
    }
    if (previousAction == 'AddRelation') {
      throw 'Remove operation is invalid after AddRelation operation';
    }
    if (previousAction == 'RemoveRelation') {
      throw 'Remove operation is invalid after RemoveRelation operation';
    }
    return values;
  }

  // Increment operation Merge
  dynamic _mergeWithPreviousIncrement(
      String previousAction, dynamic previous, dynamic values) {
    if (previousAction == 'Set') {
      if (previous is num) {
        values['amount'] += previous;
      } else {
        throw 'Invalid Operation';
      }
    }
    if (previousAction == 'Increment') {
      values['amount'] += previous['amount'];
    }
    if (previousAction == 'Add') {
      throw 'Increment operation is invalid after Add operation';
    }
    if (previousAction == 'Remove') {
      throw 'Increment operation is invalid after Remove operation';
    }
    if (previousAction == 'AddUnique') {
      throw 'Increment operation is invalid after AddUnique operation';
    }
    if (previousAction == 'AddRelation') {
      throw 'Increment operation is invalid after AddRelation operation';
    }
    if (previousAction == 'RemoveRelation') {
      throw 'Increment operation is invalid after RemoveRelation operation';
    }
    return values;
  }

  // AddUnique operation Merge
  dynamic _mergeWithPreviousAddUnique(
      String previousAction, dynamic previous, dynamic values) {
    if (previousAction == 'Set') {
      if (previous is List) {
        return _applyToValueAddUnique(previous, values['objects']);
      } else {
        throw 'Unable to add an item to a non-array.';
      }
    }
    if (previousAction == 'AddUnique') {
      values['objects'] =
          _applyToValueAddUnique(previous['objects'], values['objects']);
      return values;
    }
    if (previousAction == 'Add') {
      throw 'AddUnique operation is invalid after Add operation';
    }
    if (previousAction == 'Remove') {
      throw 'AddUnique operation is invalid after Reomve operation';
    }
    if (previousAction == 'Increment') {
      throw 'AddUnique operation is invalid after Increment operation';
    }
    if (previousAction == 'AddRelation') {
      throw 'AddUnique operation is invalid after AddRelation operation';
    }
    if (previousAction == 'RemoveRelation') {
      throw 'AddUnique operation is invalid after RemoveRelation operation';
    }
    return values;
  }

  // AddRelation operation Merge
  dynamic _mergeWithPreviousAddRelation(
      String previousAction, dynamic previous, dynamic values) {
    if (previousAction == 'AddRelation') {
      if (values['objects'].length == 1) {
        previous['objects'].add(values['objects'].first);
      } else {
        previous['objects'].add(values['objects']);
      }
      values = previous;
    }
    if (previousAction == 'Set') {
      throw 'AddRelation operation is invalid after Set operation.';
    }
    if (previousAction == 'Increment') {
      throw 'AddRelation operation is invalid after Increment operation';
    }
    if (previousAction == 'Add') {
      throw 'AddRelation operation is invalid after Add operation';
    }
    if (previousAction == 'Remove') {
      throw 'AddRelation operation is invalid after Remove operation';
    }
    if (previousAction == 'AddUnique') {
      throw 'AddRelation operation is invalid after AddUnique operation';
    }
    if (previousAction == 'RemoveRelation') {
      throw 'AddRelation operation is invalid after RemoveRelation operation';
    }
    return values;
  }

  // RemoveRelation operation Merge
  dynamic _mergeWithPreviousRemoveRelation(
      String previousAction, dynamic previous, dynamic values) {
    if (previousAction == 'RemoveRelation') {
      if (values['objects'].length == 1) {
        previous['objects'].add(values['objects'].first);
      } else {
        previous['objects'].add(values['objects']);
      }
      values = previous;
    }
    if (previousAction == 'Set') {
      throw 'RemoveRelation operation is invalid after Set operation.';
    }
    if (previousAction == 'Increment') {
      throw 'RemoveRelation operation is invalid after Increment operation';
    }
    if (previousAction == 'Add') {
      throw 'RemoveRelation operation is invalid after Add operation';
    }
    if (previousAction == 'Remove') {
      throw 'RemoveRelation operation is invalid after Remove operation';
    }
    if (previousAction == 'AddUnique') {
      throw 'RemoveRelation operation is invalid after AddUnique operation';
    }
    if (previousAction == 'AddRelation') {
      throw 'RemoveRelation operation is invalid after AddRelation operation';
    }
    return values;
  }

  // service for AddUnique method
  dynamic _applyToValueAddUnique(dynamic oldValue, dynamic newValue) {
    // ignore: always_specify_types
    for (var objectToAdd in newValue) {
      if (objectToAdd is ParseObject && objectToAdd.objectId != null) {
        int index = 0;
        // ignore: always_specify_types
        for (var objc in oldValue) {
          if (objc is ParseObject && objc.objectId == objectToAdd.objectId) {
            oldValue[index] = objectToAdd;
            break;
          }
          index += 1;
        }
        if (index == oldValue.length) {
          oldValue.add(objectToAdd);
        }
      } else if (!oldValue.contains(objectToAdd)) {
        oldValue.add(objectToAdd);
      }
    }
    print(oldValue);
    return oldValue;
  }
}
