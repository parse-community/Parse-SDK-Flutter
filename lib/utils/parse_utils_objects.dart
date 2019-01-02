import 'package:parse_server_sdk/base/parse_constants.dart';
import 'package:parse_server_sdk/objects/parse_object.dart';
import 'package:parse_server_sdk/utils/parse_utils_date.dart';

populateObjectBaseData(ParseObject object, Map<String, dynamic> objectData) {
  object.setValue(
      ParseConstants.OBJECT_ID, objectData[ParseConstants.OBJECT_ID]);
  object.setValue(ParseConstants.CREATED_AT,
      convertStringToDateTime(objectData[ParseConstants.CREATED_AT]));
  object.setValue(ParseConstants.OBJECT_ID,
      convertStringToDateTime(objectData[ParseConstants.UPDATED_AT]));
  return object;
}
