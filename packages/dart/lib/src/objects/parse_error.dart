part of '../../parse_server_sdk.dart';

/// ParseException is used in [ParseResult] to inform the user of the exception
class ParseError {
  ParseError(
      {this.code = otherCause,
      this.message = 'OtherCause',
      this.exception,
      bool debug = false}) {
    type = _exceptions[code];
    if (debug) {
      print(toString());
    }
  }

  /// Error code indicating some error other than those enumerated here.
  static const int otherCause = -1;

  /// Error code indicating that something has gone wrong with the server.
  static const int internalServerError = 1;

  /// Error code indicating the connection to the Parse servers failed.
  static const int connectionFailed = 100;

  /// Error code indicating the specified object doesn't exist.
  static const int objectNotFound = 101;

  /// Error code indicating you tried to query with a datatype that doesn't
  /// support it, like exact matching an array or object.
  static const int invalidQuery = 102;

  /// Error code indicating a missing or invalid classname. Classnames are
  /// case-sensitive. They must start with a letter, and a-zA-Z0-9_ are the
  /// only valid characters.
  static const int invalidClassName = 103;

  /// Error code indicating an unspecified object id.
  static const int missingObjectId = 104;

  /// Error code indicating an invalid key name. Keys are case-sensitive. They
  /// must start with a letter, and a-zA-Z0-9_ are the only valid characters.
  static const int invalidKeyName = 105;

  /// Error code indicating a malformed pointer. You should not see this unless
  /// you have been mucking about changing internal Parse code.
  static const int invalidPointer = 106;

  /// Error code indicating that badly formed JSON was received upstream. This
  /// either indicates you have done something unusual with modifying how
  /// things encode to JSON, or the network is failing badly.
  static const int invalidJson = 107;

  /// Error code indicating that the feature you tried to access is only
  /// available internally for testing purposes.
  static const int commandUnavailable = 108;

  /// You must call Parse().initialize before using the Parse library.
  static const int notInitialized = 109;

  /// Error code indicating that a field was set to an inconsistent type.
  static const int incorrectType = 111;

  /// Error code indicating an invalid channel name. A channel name is either
  /// an empty string (the broadcast channel) or contains only a-zA-Z0-9_
  /// characters and starts with a letter.
  static const int invalidChannelName = 112;

  /// Error code indicating that push is misconfigured.
  static const int pushMisconfigured = 115;

  /// Error code indicating that the object is too large.
  static const int objectTooLarge = 116;

  /// Error code indicating that the operation isn't allowed for clients.
  static const int operationForbidden = 119;

  /// Error code indicating the result was not found in the cache.
  static const int cacheMiss = 120;

  /// Error code indicating that an invalid key was used in a nested
  /// JSONObject.
  static const int invalidNestedKey = 121;

  /// Error code indicating that an invalid filename was used for ParseFile.
  /// A valid file name contains only a-zA-Z0-9_. characters and is between 1
  /// and 128 characters.
  static const int invalidFileName = 122;

  /// Error code indicating an invalid ACL was provided.
  static const int invalidAcl = 123;

  /// Error code indicating that the request timed out on the server. Typically
  /// this indicates that the request is too expensive to run.
  static const int timeout = 124;

  /// Error code indicating that the email address was invalid.
  static const int invalidEmailAddress = 125;

  /// Error code indicating a missing content type.
  static const int missingContentType = 126;

  /// Error code indicating a missing content length.
  static const int missingContentLength = 127;

  /// Error code indicating an invalid content length.
  static const int invalidContentLength = 128;

  /// Error code indicating a file that was too large.
  static const int fileTooLarge = 129;

  /// Error code indicating an error saving a file.
  static const int fileSaveError = 130;

  /// Error code indicating that a unique field was given a value that is
  /// already taken.
  static const int duplicateValue = 137;

  /// Error code indicating that a role's name is invalid.
  static const int invalidRoleName = 139;

  /// Error code indicating that an application quota was exceeded.  Upgrade to
  /// resolve.
  static const int exceededQuota = 140;

  /// Error code indicating that a Cloud Code script failed.
  static const int scriptFailed = 141;

  /// Error code indicating that a Cloud Code validation failed.
  static const int validationError = 142;

  /// Error code indicating that invalid image data was provided.
  static const int invalidImageData = 143;

  /// Error code indicating an unsaved file.
  static const int unsavedFileError = 151;

  /// Error code indicating an invalid push time.
  static const int invalidPushTimeError = 152;

  /// Error code indicating an error deleting a file.
  static const int fileDeleteError = 153;

  /// Error code indicating an error deleting an unnamed file.
  static const int fileDeleteUnnamedError = 161;

  /// Error code indicating that the application has exceeded its request
  /// limit.
  static const int requestLimitExceeded = 155;

  /// Error code indicating that the request was a duplicate and has been discarded due to
  /// idempotency rules.
  static const int duplicateRequest = 159;

  /// Error code indicating an invalid event name.
  static const int invalidEventName = 160;

  /// Error code indicating that a field had an invalid value.
  static const int invalidValue = 162;

  /// Error code indicating that the username is missing or empty.
  static const int usernameMissing = 200;

  /// Error code indicating that the password is missing or empty.
  static const int passwordMissing = 201;

  /// Error code indicating that the username has already been taken.
  static const int usernameTaken = 202;

  /// Error code indicating that the email has already been taken.
  static const int emailTaken = 203;

  /// Error code indicating that the email is missing, but must be specified.
  static const int emailMissing = 204;

  /// Error code indicating that a user with the specified email was not found.
  static const int emailNotFound = 205;

  /// Error code indicating that a user object without a valid session could
  /// not be altered.
  static const int sessionMissing = 206;

  /// Error code indicating that a user can only be created through signup.
  static const int mustCreateUserThroughSignup = 207;

  /// Error code indicating that an an account being linked is already linked
  /// to another user.
  static const int accountAlreadyLinked = 208;

  /// Error code indicating that the current session token is invalid.
  static const int invalidSessionToken = 209;

  /// Error code indicating an error enabling or verifying MFA
  static const int mfaError = 210;

  /// Error code indicating that a valid MFA token must be provided
  static const int mfaTokenRequired = 211;

  /// Error code indicating that a user cannot be linked to an account because
  /// that account's id could not be found.
  static const int linkedIdMissing = 250;

  /// Error code indicating that a user with a linked (e.g. Facebook) account
  /// has an invalid session.
  static const int invalidLinkedSession = 251;

  /// Error code indicating that a service being linked (e.g. Facebook or
  /// Twitter) is unsupported.
  static const int unsupportedService = 252;

  /// Error code indicating an invalid operation occured on schema
  static const int invalidSchemaOperation = 255;

  /// Error code indicating that there were multiple errors. Aggregate errors
  /// have an "errors" property, which is an array of error objects with more
  /// detail about each error that occurred.
  static const int aggregateError = 600;

  /// Error code indicating the client was unable to read an input file.
  static const int fileReadError = 601;

  /// Error code indicating a real error code is unavailable because
  /// we had to use an XDomainRequest object to allow CORS requests in
  /// Internet Explorer, which strips the body from HTTP responses that have
  /// a non-2XX status code.
  static const int xDomainRequest = 602;

  static const Map<int, String> _exceptions = {
    otherCause: 'OtherCause',
    internalServerError: 'InternalServerError',
    connectionFailed: 'ConnectionFailed',
    objectNotFound: 'ObjectNotFound',
    invalidQuery: 'InvalidQuery',
    invalidClassName: 'InvalidClassName',
    missingObjectId: 'MissingObjectId',
    invalidKeyName: 'InvalidKeyName',
    invalidPointer: 'InvalidPointer',
    invalidJson: 'InvalidJson',
    commandUnavailable: 'CommandUnavailable',
    notInitialized: 'NotInitialized',
    incorrectType: 'IncorrectType',
    invalidChannelName: 'InvalidChannelName',
    pushMisconfigured: 'PushMisconfigured',
    objectTooLarge: 'ObjectTooLarge',
    operationForbidden: 'OperationForbidden',
    cacheMiss: 'CacheMiss',
    invalidNestedKey: 'InvalidNestedKey',
    invalidFileName: 'InvalidFileName',
    invalidAcl: 'InvalidAcl',
    timeout: 'Timeout',
    invalidEmailAddress: 'InvalidEmailAddress',
    missingContentType: 'MissingContentType',
    missingContentLength: 'MissingContentLength',
    invalidContentLength: 'InvalidContentLength',
    fileTooLarge: 'FileTooLarge',
    fileSaveError: 'FileSaveError',
    duplicateValue: 'DuplicateValue',
    invalidRoleName: 'InvalidRoleName',
    exceededQuota: 'ExceededQuota',
    scriptFailed: 'ScriptError',
    validationError: 'ValidationError',
    invalidImageData: 'InvalidImageData',
    unsavedFileError: 'UnsavedFileError',
    invalidPushTimeError: 'InvalidPushTimeError',
    fileDeleteError: 'FileDeleteError',
    fileDeleteUnnamedError: 'FileDeleteUnnamedError',
    requestLimitExceeded: 'RequestLimitExceeded',
    duplicateRequest: 'DuplicateRequest',
    invalidEventName: 'InvalidEventName',
    invalidValue: 'InvalidValue',
    usernameMissing: 'UsernameMissing',
    passwordMissing: 'PasswordMissing',
    usernameTaken: 'UsernameTaken',
    emailTaken: 'EmailTaken',
    emailMissing: 'EmailMissing',
    emailNotFound: 'EmailNotFound',
    sessionMissing: 'SessionMissing',
    mustCreateUserThroughSignup: 'MustCreateUserThroughSignUp',
    accountAlreadyLinked: 'AccountAlreadyLinked',
    invalidSessionToken: 'InvalidSessionToken',
    mfaError: 'MfaError',
    mfaTokenRequired: 'MfaTokenRequired',
    linkedIdMissing: 'LinkedIdMissing',
    invalidLinkedSession: 'InvalidLinkedSession',
    unsupportedService: 'UnsupportedService',
    invalidSchemaOperation: 'InvalidSchemaOperation',
    aggregateError: 'AggregateError',
    fileReadError: 'FileReadError',
    xDomainRequest: 'XDomainRequest',
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
