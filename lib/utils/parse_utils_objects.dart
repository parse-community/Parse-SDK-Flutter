import 'package:parse_server_sdk/base/parse_constants.dart';
import 'package:parse_server_sdk/objects/parse_object.dart';
import 'package:parse_server_sdk/utils/parse_utils_date.dart';

class ParseUtilsObjects {
  static ParseObject populateObjectBaseData(ParseObject object, Map<String, dynamic> objectData) {
    object.objectId = objectData[ParseConstants.OBJECT_ID];
    object.createdAt = ParseUtilsDates.convertStringToDateTime(objectData[ParseConstants.CREATED_AT]);
    object.updatedAt = ParseUtilsDates.convertStringToDateTime(objectData[ParseConstants.UPDATED_AT]);
    return object;
  }
}