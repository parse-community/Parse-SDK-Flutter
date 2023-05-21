# Push Notifications

Push notifications are a great way to keep your users engaged and informed about your app. You can reach your entire user base quickly and effectively. This guide will help you through the setup process and the general usage of Parse to send push notifications.

To activate and implement Push Notifications in Parse Server, check [this page](https://docs.parseplatform.org/parse-server/guide/#push-notifications)

## Installation
1 : First need install [Firebase Core](https://firebase.flutter.dev/docs/overview) and [Cloud Messaging](https://firebase.flutter.dev/docs/messaging/overview)

Tip : Recommend reviewing the [Firebase Core Manual](https://firebase.flutter.dev/docs/manual-installation/)

2 : Set the following codes after ```Parse().initialize```
```dart
await Parse().initialize(...);

ParsePush.instance.initialize(FirebaseMessaging.instance);
FirebaseMessaging.onMessage.listen((message) => ParsePush.instance.onMessage(message));
```

3 : To work with push notifications after closing the application, follow the steps below.

Put the following code after the above codes
```dart
FirebaseMessaging.onBackgroundMessage(onBackgroundMessage);
```

Put the following function in your codes
```dart
Future<void> onBackgroundMessage(RemoteMessage message) async => ParsePush.instance.onMessage(message);
```

## Implemented example
Your code should look like the following code

```dart
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // initialize Firebase Core
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // initialize Parse
  await Parse().initialize("applicationId", "serverUrl",
      clientKey: "clientKey", debug: true);

  // initialize Parse Push
  ParsePush.instance.initialize(FirebaseMessaging.instance);
  FirebaseMessaging.onMessage
      .listen((message) => ParsePush.instance.onMessage(message));
  
  // for run ParsePush in the background
  FirebaseMessaging.onBackgroundMessage(onBackgroundMessage);

  runApp(const MyApp());
}

Future<void> onBackgroundMessage(RemoteMessage message) async =>
    ParsePush.instance.onMessage(message);

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}
...
```
