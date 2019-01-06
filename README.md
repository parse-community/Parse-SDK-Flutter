# Parse Server Dart
A rewrite of a library hosted on GitHub. This is not my own content but based on a library already created and looks to be abandoned.

https://github.com/lotux/parse_server_dart

## Join in!
Want to get involved? Join our Slack channel and help out! FlutterParseSDK.Slack.com

## Getting Started

## To init Parse, call the method:-

```
Parse().initialize(
        ApplicationConstants.PARSE_APPLICATION_ID,
        ApplicationConstants.PARSE_SERVER_URL,
        masterKey: ApplicationConstants.PARSE_MASTER_KEY);
```

## After, you can then get and save Parse Objects by calling:-

```
var apiResponse = await ParseObject('ParseTableName').getAll();

    if (apiResponse.success){
      for (var testObject in apiResponse.result) {
        print(ApplicationConstants.APP_NAME + ": " + testObject.toString());
      }
    }
```

## Or, extend the ParseObject class and create custom objects:-

```
class DietPlan extends ParseObject {
  static const String DIET_PLAN = 'Diet_Plans';

  DietPlan() : super(DIET_PLAN);

  String name;

  DietPlan.fromJson(Map<String, dynamic> json)
      : name = json['name'],
        super(DIET_PLAN);

  Map<String, dynamic> toJson() => {'name': name};
}
```

## then call:-

```
var dietPlan = await DietPlan().get('R5EonpUDWy');

    if (dietPlan.success) {
      print(ApplicationConstants.APP_NAME + ": " + (dietPlan.result as DietPlan).toString());
    } else {
      print(ApplicationConstants.APP_NAME + ": " + dietPlan.exception.message);
    }
```

## Complex queries:-

'''
var queryBuilder = QueryBuilder<DietPlan>(DietPlan())
      ..startsWith(DietPlan.NAME, "Keto")
      ..greaterThan(DietPlan.FAT, 64)
      ..lessThan(DietPlan.FAT, 66)
      ..equals(DietPlan.CARBS, 5);

    var response = await queryBuilder.query();

    if (response.success) {
      print(ApplicationConstants.APP_NAME + ": " + ((response.result as List<dynamic>).first as DietPlan).toString());
    } else {
      print(ApplicationConstants.APP_NAME + ": " + response.exception.message);
    }
'''

## Current abilities:-

Main:
Users
Queries
LiveQueries
Debug Mode - Logging API calls

ParseUser:
Create
Login
CurrentUser
RequestPasswordReset
VerificationEmailRequest
AllUsers
Save
Destroy

Objects:
Create new object
Extend Parse Object and create local objects that can be saved and retreived

Queries:
Complex queries that can search for the following:-

Equals
Contains
LessThan
LessThanOrEqualTo
GreaterThan
GreaterThanOrEqualTo
NotEqualTo
StartsWith
EndsWith
Regex

Others but not tested

        
