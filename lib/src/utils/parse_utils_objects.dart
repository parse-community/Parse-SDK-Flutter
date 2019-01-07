part of flutter_parse_sdk;

populateObjectBaseData(ParseObject object, Map<String, dynamic> objectData) {
  object.set(ParseConstants.OBJECT_ID, objectData[ParseConstants.OBJECT_ID]);
  object.set(ParseConstants.CREATED_AT, convertStringToDateTime(objectData[ParseConstants.CREATED_AT]));
  object.set(ParseConstants.OBJECT_ID, convertStringToDateTime(objectData[ParseConstants.UPDATED_AT]));
  return object;
}
