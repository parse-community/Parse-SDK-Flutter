![enter image description here](https://upload.wikimedia.org/wikipedia/commons/1/17/Google-flutter-logo.png)
![enter image description here](https://i2.wp.com/blog.openshift.com/wp-content/uploads/parse-server-logo-1.png?fit=200%2C200&ssl=1&resize=350%2C200)

## Parse For Flutter! 
Hi, this is a Flutter plugin that allows communication with a Parse Server, (https://parseplatform.org) either hosted on your own server or another, like (http://Back4App.com).

This is a work in project and we are consistently updating it. Please let us know if you think anything needs changing/adding, and more than ever, please do join in on this project (Even if it is just to improve our documentation.

## Join in!
Want to get involved? Join our Slack channel and help out! (http://flutter-parse-sdk.slack.com)

## Getting Started
To install, either add to your pubspec.yaml
```yml
dependencies:  
    parse_server_sdk: ^1.0.17
```
or clone this repository and add to your project. As this is an early development with multiple contributors, it is probably best to download/clone and keep updating as an when a new feature is added.


Once you have the library added to your project, upon first call to your app (Similar to what your application class would be) add the following...

```dart
Parse().initialize(
        ApplicationConstants.keyApplicationId,
        ApplicationConstants.keyParseServerUrl);
```

It's possible to add other params, such as ...

```dart
Parse().initialize(
        ApplicationConstants.keyApplicationId,
        ApplicationConstants.keyParseServerUrl,
        masterKey: ApplicationConstants.keyParseMasterKey,
        clientKey: ApplicationConstants.keyParseClientKey,
        debug: true,
        liveQuery: true,
        autoSendSessionId: true,
        securityContext: securityContext);
```

## Queries
Once you have setup the project and initialised the instance, you can then retreive data from your server by calling:
```dart
var apiResponse = await ParseObject('ParseTableName').getAll();

    if (apiResponse.success){
      for (var testObject in apiResponse.result) {
        print(ApplicationConstants.APP_NAME + ": " + testObject.toString());
      }
    }
```
Or you can get an object by its objectId:

```dart
var dietPlan = await DietPlan().getObject('R5EonpUDWy');

    if (dietPlan.success) {
      print(ApplicationConstants.keyAppName + ": " + (dietPlan.result as DietPlan).toString());
    } else {
      print(ApplicationConstants.keyAppName + ": " + dietPlan.exception.message);
    }
```


## Complex queries
You can create complex queries to really put your database to the test:

```dart
    var queryBuilder = QueryBuilder<DietPlan>(DietPlan())
      ..startsWith(DietPlan.keyName, "Keto")
      ..greaterThan(DietPlan.keyFat, 64)
      ..lessThan(DietPlan.keyFat, 66)
      ..equals(DietPlan.keyCarbs, 5);

    var response = await queryBuilder.query();

    if (response.success) {
      print(ApplicationConstants.keyAppName + ": " + ((response.result as List<dynamic>).first as DietPlan).toString());
    } else {
      print(ApplicationConstants.keyAppName + ": " + response.exception.message);
    }
```

The features available are:-
 * Equals
 * Contains
 * LessThan
 * LessThanOrEqualTo
 * GreaterThan
 * GreaterThanOrEqualTo
 * NotEqualTo
 * StartsWith
 * EndsWith
 * Exists
 * Near
 * WithinMiles
 * WithinKilometers
 * WithinRadians
 * WithinGeoBox
 * Regex
 * Order
 * Limit
 * Skip
 * Ascending
 * Descending
 * Plenty more!
 
## Relational queries
If you want to retrieve objects where a field contains an object that matches another query, you can use the
__whereMatchesQuery__ condition.
For example, imagine you have Post class and a Comment class, where each Comment has a pointer to its parent Post.
You can find comments on posts with images by doing:

```dart
  QueryBuilder<ParseObject> queryPost =
      QueryBuilder<ParseObject>(ParseObject('Post'))
        ..whereValueExists('image', true);

  QueryBuilder<ParseObject> queryComment =
      QueryBuilder<ParseObject>(ParseObject('Comment'))
        ..whereMatchesQuery('post', queryPost);

  var apiResponse = await queryComment.query();
```

If you want to retrieve objects where a field contains an object that does not match another query,  you can use the
__whereDoesNotMatchQuery__ condition.
Imagine you have Post class and a Comment class, where each Comment has a pointer to its parent Post.
You can find comments on posts without images by doing:

```dart
  QueryBuilder<ParseObject> queryPost =
      QueryBuilder<ParseObject>(ParseObject('Post'))
        ..whereValueExists('image', true);

  QueryBuilder<ParseObject> queryComment =
      QueryBuilder<ParseObject>(ParseObject('Comment'))
        ..whereDoesNotMatchQuery('post', queryPost);

  var apiResponse = await queryComment.query();
```

## Counting Objects
If you only care about the number of games played by a particular player:

```dart
  QueryBuilder<ParseObject> queryPlayers =
      QueryBuilder<ParseObject>(ParseObject('GameScore'))
        ..whereEqualTo('playerName', 'Jonathan Walsh');
  var apiResponse = await queryPlayers.count();
  if (apiResponse.success && apiResponse.result != null) {
    int countGames = apiResponse.count;
  }
```

## Objects

You can create custom objects by calling:
```dart
var dietPlan = ParseObject('DietPlan')
	..set('Name', 'Ketogenic')
	..set('Fat', 65);
```
You then have the ability to do the following with that object:
The features available are:-
 * Get
 * GetAll
 * Create
 * Save
 * Query - By object Id
 * Delete
 * Complex queries as shown above
 * Pin
 * Plenty more
 * Counters
 * Array Operators

## Custom Objects
You can create your own ParseObjects or convert your existing objects into Parse Objects by doing the following:

```dart
class DietPlan extends ParseObject implements ParseCloneable {

  DietPlan() : super(_keyTableName);
  DietPlan.clone(): this();

  /// Looks strangely hacky but due to Flutter not using reflection, we have to
  /// mimic a clone
  @override clone(Map map) => DietPlan.clone()..fromJson(map);

  static const String _keyTableName = 'Diet_Plans';
  static const String keyName = 'Name';
  
  String get name => get<String>(keyName);
  set name(String name) => set<String>(keyName, name);
}
  
```

## Add new values to objects

To add a variable to an object call and retrieve it, call

```dart
dietPlan.set<int>('RandomInt', 8);
var randomInt = dietPlan.get<int>('RandomInt');
```

## Save objects using pins

You can now save an object by calling .pin() on an instance of an object

```dart
dietPlan.pin();
```

and to retrieve it

```dart
var dietPlan = DietPlan().fromPin('OBJECT ID OF OBJECT');
```

## Increment Counter values in objects

Retrieve it, call

```dart
var response = await dietPlan.increment("count", 1);

```

## Array Operator in objects

Retrieve it, call

```dart
var response = await dietPlan.add("listKeywords", ["a", "a","d"]);

var response = await dietPlan.addUnique("listKeywords", ["a", "a","d"]);

var response = await dietPlan.remove("listKeywords", ["a"]);

```


## Users

You can create and control users just as normal using this SDK.

To register a user, first create one :
```dart
var user =  ParseUser().create("TestFlutter", "TestPassword123", "TestFlutterSDK@gmail.com");
```
Then have the user sign up:

```dart
var response = await user.signUp();
if (response.success) user = response.result;
```
You can also logout and login with the user:
```dart
var response = await user.login();
if (response.success) user = response.result;
```
Also, once logged in you can manage sessions tokens. This feature can be called after Parse().init() on startup to check for a logged in user.
```dart
user = ParseUser.currentUser();
```
Other user features are:-
 * Request Password Reset
 * Verification Email Request
 * Get all users
 * Save
 * Destroy user
 * Queries 

## Config

The SDK now supports Parse Config. A map of all configs can be grabbed from the server by calling :
```dart
var response = await ParseConfig().getConfigs();
```

and to add a config:
```dart
ParseConfig().addConfig('TestConfig', 'testing');
```

## Other Features of this library

Main:
* Users
* Installation
* Objects
* Queries
* LiveQueries
* GeoPoints
* Files
* Persistent storage
* Debug Mode - Logging API calls
* Manage Session ID's tokens

User:
* Create       
* Login
* Logout
* CurrentUser
* RequestPasswordReset
* VerificationEmailRequest
* AllUsers
* Save
* Destroy
* Queries

Objects:
* Create new object
* Extend Parse Object and create local objects that can be saved and retreived
* Queries:

## Author:-
This project was authored by Phill Wiggins. You can contact me at phill.wiggins@gmail.com
<!--stackedit_data:
eyJoaXN0b3J5IjpbNzE4NjUwNDIwXX0=
-->
