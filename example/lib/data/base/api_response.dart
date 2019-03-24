import 'package:parse_server_sdk/parse_server_sdk.dart';

import 'api_error.dart';

class ApiResponse {
  ApiResponse(this.success, this.statusCode, this.result, this.error);

  final bool success;
  final int statusCode;
  final dynamic result;
  final ApiError error;

  dynamic getResult<T extends ParseObject>() {
    return result;
  }
}

ApiResponse getApiResponse<T extends ParseObject>(ParseResponse response) {
  return ApiResponse(response.success, response.statusCode, response.result,
      getApiError(response.error));
}

ApiError getApiError(ParseError response) {
  if (response == null) {
    return null;
  }
  return ApiError(response.code, response.message, response.isTypeOfException,
      response.type);
}
