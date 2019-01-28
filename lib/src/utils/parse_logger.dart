part of flutter_parse_sdk;

void logger(String appName, String className, String type,
    ParseResponse parseResponse) {
  var responseString = ' \n';
  var name = appName;
  if (name.length > 0) name = "$appName ";

  responseString += "----\n${name}API Response ($className : $type) :";

  if (parseResponse.success) {
    responseString += "\nStatus Code: ${parseResponse.statusCode}";
    if (parseResponse.result != null) {
      responseString += "\nPayload: ${parseResponse.result.toString()}";
    } else {
      responseString += "\nReponse: OK";
    }
  } else if (!parseResponse.success) {
    responseString += "\nStatus Code: ${parseResponse.error.code}";
    responseString += "\nType: ${parseResponse.error.type}";

    String errorOrException =
        parseResponse.error.isTypeOfException ? "Exception" : "Error";

    responseString += "\n$errorOrException: ${parseResponse.error.message}";
  }

  responseString += "\n----\n";
  print(responseString);
}
