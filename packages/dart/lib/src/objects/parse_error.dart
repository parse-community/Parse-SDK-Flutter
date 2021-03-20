part of flutter_parse_sdk;

/// ParseException is used in [ParseResult] to inform the user of the exception
class ParseError {
  ParseError(
      {this.code = -1,
      this.message = 'Unknown error',
      this.exception,
      bool debug = false}) {
    type = _exceptions[code];
    if (debug) {
      print(toString());
    }
  }

  Map<int, String> _exceptions = {
    -1: 'UnknownError',

    // SDK errors / Errors
    1: 'No Results',
    2: 'OK',
    400: 'Bad Request',

    // Parse specific / Exceptions
    100: 'ConnectionFailed',
    101: 'ObjectNotFound',
    102: 'InvalidQuery',
    103: 'InvalidClassName',
    104: 'MissingObjectId',
    105: 'InvalidKeyName',
    106: 'InvalidPointer',
    107: 'InvalidJson',
    108: 'CommandUnavailable',
    109: 'NotInitialized',
    111: 'IncorrectType',
    112: 'InvalidChannelName',
    115: 'PushMisconfigured',
    116: 'ObjectTooLarge',
    119: 'OperationForbidden',
    120: 'CacheMiss',
    121: 'InvalidNestedKey',
    122: 'InvalidFileName',
    123: 'InvalidAcl',
    124: 'Timeout',
    125: 'InvalidEmailAddress',
    135: 'MissingRequiredFieldError',
    137: 'DuplicateValue',
    139: 'InvalidRoleName',
    140: 'ExceededQuota',
    141: 'ScriptError',
    142: 'ValidationError',
    153: 'FileDeleteError',
    155: 'RequestLimitExceeded',
    160: 'InvalidEventName',
    200: 'UsernameMissing',
    201: 'PasswordMissing',
    202: 'UsernameTaken',
    203: 'EmailTaken',
    204: 'EmailMissing',
    205: 'EmailNotFound',
    206: 'SessionMissing',
    207: 'MustCreateUserThroughSignUp',
    208: 'AccountAlreadyLinked',
    209: 'InvalidSessionToken',
    250: 'LinkedIdMissing',
    251: 'InvalidLinkedSession',
    252: 'UnsupportedService'
  };

  final int code;
  final String message;
  final Exception? exception;
  String? type;

  @override
  String toString() {
    String exceptionString = ' \n';
    exceptionString += '----';
    exceptionString += '\nParseException (Type: $type) :';
    exceptionString += '\nCode: $code';
    exceptionString += '\nMessage: $message';
    exceptionString += '----';
    return exceptionString;
  }
}
