part of flutter_parse_sdk;

// Library
const String keySdkVersion = '1.0.26';
const String keyLibraryName = 'Flutter Parse SDK';

// End Points
const String keyEndPointUserName = '/users/me';
const String keyEndPointLogin = '/login';
const String keyEndPointLogout = '/logout';
const String keyEndPointUsers = '/users';
const String keyEndPointSessions = '/sessions';
const String keyEndPointInstallations = '/installations';
const String keyEndPointVerificationEmail = '/verificationEmailRequest';
const String keyEndPointRequestPasswordReset = '/requestPasswordReset';
const String keyEndPointClasses = '/classes/';
const String keyEndPointHealth = '/health';
const String keyEndPointAggregate = '/aggregate/';

// ParseObject variables
const String keyVarClassName = 'className';
const String keyVarObjectId = 'objectId';
const String keyVarCreatedAt = 'createdAt';
const String keyVarUpdatedAt = 'updatedAt';
const String keyVarUsername = 'username';
const String keyVarEmail = 'email';
const String keyVarPassword = 'password';
const String keyVarSessionToken = 'sessionToken';
const String keyVarAuthData = 'authData';
const String keyVarAcl = 'ACL';
const String keyVarName = 'name';
const String keyVarURL = 'url';

// Classes
const String keyClassMain = 'ParseMain';
const String keyClassUser = '_User';
const String keyClassSession = '_Session';
const String keyClassInstallation = '_Installation';
const String keyGeoPoint = 'GeoPoint';
const String keyFile = 'File';
const String keyRelation = 'Relation';

// Headers
const String keyHeaderSessionToken = 'X-Parse-Session-Token';
const String keyHeaderRevocableSession = 'X-Parse-Revocable-Session';
const String keyHeaderUserAgent = 'user-agent';
const String keyHeaderApplicationId = 'X-Parse-Application-Id';
const String keyHeaderContentType = 'Content-Type';
const String keyHeaderContentTypeJson = 'application/json';
const String keyHeaderMasterKey = 'X-Parse-Master-Key';
const String keyHeaderClientKey = 'X-Parse-Client-Key';
const String keyHeaderInstallationId = 'X-Parse-Installation-Id';

// URL params
const String keyParamSessionToken = 'sessionToken';

// Storage
const String keyParseStoreBase = 'flutter_parse_sdk_';
const String keyParseStoreUser = '${keyParseStoreBase}user';
const String keyParseStoreInstallation = '${keyParseStoreBase}installation';

// Installation
const String keyTimeZone = 'timeZone';
const String keyLocaleIdentifier = 'localeIdentifier';
const String keyDeviceToken = 'deviceToken';
const String keyDeviceType = 'deviceType';
const String keyInstallationId = 'installationId';
const String keyAppName = 'appName';
const String keyAppVersion = 'appVersion';
const String keyAppIdentifier = 'appIdentifier';
const String keyParseVersion = 'parseVersion';

// Parse Session
const String keyVarUser = 'user';
const String keyVarCreatedWith = 'createdWith';
const String keyVarRestricted = 'restricted';
const String keyVarExpiresAt = 'expiresAt';
const String keyVarInstallationId = 'installationId';

// Error
const String keyError = 'error';
const String keyCode = 'code';
