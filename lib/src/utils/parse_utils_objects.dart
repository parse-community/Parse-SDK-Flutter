part of flutter_parse_sdk;

/// Populates the base object data from a server response
populateObjectBaseData(ParseBase object, Map<String, dynamic> objectData) {
  object.set(OBJECT_ID, objectData[OBJECT_ID]);
  object.set(CREATED_AT, stringToDateTime(objectData[CREATED_AT]));
  object.set(OBJECT_ID, stringToDateTime(objectData[UPDATED_AT]));
  return object;
}
