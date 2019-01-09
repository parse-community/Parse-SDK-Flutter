part of flutter_parse_sdk;

void logger(
    String appName,
    String className,
    String type,
    ParseResponse parseResponse) {
    var responseString = ' \n';

    responseString += "----\n$appName API Response ($className : $type) :";

    if (parseResponse.success && parseResponse.result != null) {
      responseString += "\nStatus Code: ${parseResponse.statusCode}";
      responseString += "\nPayload: ${parseResponse.result.toString()}";
    } else if (!parseResponse.success) {
      responseString += "\nStatus Code: ${parseResponse.error.code}";
      responseString += "\nType: ${parseResponse.error.type}";

      String errorOrException = parseResponse.error.isTypeOfException ? "Exception" : "Error";

      responseString += "\n$errorOrException: ${parseResponse.error.message}";
    }

    responseString += "\n----\n";
    print(responseString);
}