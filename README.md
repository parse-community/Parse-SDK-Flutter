![enter image description here](https://upload.wikimedia.org/wikipedia/commons/1/17/Google-flutter-logo.png)
![enter image description here](https://i2.wp.com/blog.openshift.com/wp-content/uploads/parse-server-logo-1.png?fit=200%2C200&ssl=1&resize=350%2C200)

## Parse For Flutter! 
Hi, this is a Flutter plugin that allows communication with a Parse Server, (https://parseplatform.org) either hosted on your own server or another, like Back4App.com

## Join in!
Want to get involved? Join our Slack channel and help out! FlutterParseSDK.Slack.com

## Getting Started
To install, either add to your pubspec.yaml
```
dependencies:  
	parse_server_sdk: ^0.0.2
```
or clone this repository and add to your project. As this is an early development with multiple contributors, it is probably best to download/clone and keep updating as an when a new feature is added.


Once you have the library added to your project, upon first call to your app (Similar to what your application class would be) add the following...

```
Parse().initialize(
        ApplicationConstants.PARSE_APPLICATION_ID,
        ApplicationConstants.PARSE_SERVER_URL);
```

It's possible to add other params, such as ...

```
Parse().initialize(
        ApplicationConstants.PARSE_APPLICATION_ID,
        ApplicationConstants.PARSE_SERVER_URL,
        masterKey: ApplicationConstants.PARSE_MASTER_KEY,
        debug: true,
        liveQuery: true);
```

## Queries
Once you have setup the project and initialised the instance, you can then retreive data from your server by calling:
```
var apiResponse = await ParseObject('ParseTableName').getAll();

    if (apiResponse.success){
      for (var testObject in apiResponse.result) {
        print(ApplicationConstants.APP_NAME + ": " + testObject.toString());
      }
    }
```
Or you can get an object by its objectId:

```
var dietPlan = await DietPlan().get('R5EonpUDWy');

    if (dietPlan.success) {
      print(ApplicationConstants.APP_NAME + ": " + (dietPlan.result as DietPlan).toString());
    } else {
      print(ApplicationConstants.APP_NAME + ": " + dietPlan.exception.message);
    }
```


## Complex queries
You can create complex queries to really put your database to the test:

```
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
 * Regex
 * Order
 * Limit
 * Skip
 * Ascending
 * Descending
 * Plenty more!

## Objects

You can create custom objects by calling:
```
var dietPlan = ParseObject('DietPlan')
	..setValue('Name', 'Ketogenic')
	..setValue('Fat', 65);
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
 * Plenty more

## Custom Objects
You can create your own ParseObjects or convert your existing objects into Parse Objects by doing the following:

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
## Users

You can create and control users just as normal using this SDK.

To register a user, first create one :
```
var user =  ParseUser().create("TestFlutter", "TestPassword123", "TestFlutterSDK@gmail.com");
```
Then have the user sign up:

```
user =  await  ParseUser().signUp();
```
You can also logout and login with the user:
```
user =  await  ParseUser().login();
```
Also, once logged in you can manage sessions tokens:
```
user =  await  ParseUser().currentUser(fromServer:  true);
```
Other user features are:-
 * Request Password Reset
 * Verification Email Request
 * Get all users
 * Save
 * Query - By object Id
 * Delete
 * Complex queries as shown above
 * Plenty more

## Other Features of this library

* Main:
        * Users
        * Queries
        * LiveQueries
        * Debug Mode - Logging API calls

* ParseUser:
        * Create
        * Login
        * CurrentUser
        * RequestPasswordReset
        * VerificationEmailRequest
        * AllUsers
        * Save
        * Destroy

* Objects:
        * Create new object
        * Extend Parse Object and create local objects that can be saved and retreived

* Queries:
        * Complex queries that can search for the following:-

## Author:-
This project was authored by Phill Wiggins. You can contact me at phill.wiggins@gmail.com
<!--stackedit_data:
eyJoaXN0b3J5IjpbMzgwNjMwODM5LC0yMzg4MzYzMzhdfQ==
-->