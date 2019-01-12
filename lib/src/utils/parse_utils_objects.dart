part of flutter_parse_sdk;

/// Populates the base object data from a server response
populateObjectBaseData(ParseBase object, Map<String, dynamic> objectData) {
  object.set(keyVarObjectId, objectData[keyVarObjectId]);
  object.set(keyVarCreatedAt, stringToDateTime(objectData[keyVarCreatedAt]));
  object.set(keyVarObjectId, stringToDateTime(objectData[keyVarUpdatedAt]));
  return object;
}
