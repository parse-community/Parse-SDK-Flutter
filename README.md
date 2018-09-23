# Parse Server Dart
A rewrite of a library hosted on GitHub. This is not my own content but based on a library already created and looks to be abandoned.

https://github.com/lotux/parse_server_dart

## Getting Started

## To init Parse, call the method:-

```
Parse().initialize(
        appId: ApplicationConstants.PARSE_APPLICATION_ID,
        serverUrl: ApplicationConstants.PARSE_SERVER_URL,
        masterKey: ApplicationConstants.PARSE_MASTER_KEY);
```

## After, you can then get and save Parse Objects by calling:-

```
Parse().object('Diet_Plans').get('R5EonpUDWy').then((dietPlan) {
      print(dietPlan['name']);
});
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
DietPlan().get('R5EonpUDWy').then((plan) {
      print(DietPlan.fromJson(plan).name);
});
```
