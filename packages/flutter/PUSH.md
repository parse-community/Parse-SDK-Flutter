# Push Notifications

Push notifications are a great way to keep your users engaged and informed about your app. You can reach your user base quickly and effectively. This guide will help you through the setup process and the general usage of Parse Platform to send push notifications.

To configure push notifications in Parse Server, check out the [push notification guide](https://docs.parseplatform.org/parse-server/guide/#push-notifications).

## Installation

1. Install [Firebase Core](https://firebase.flutter.dev/docs/overview) and [Cloud Messaging](https://firebase.flutter.dev/docs/messaging/overview). For more details review the [Firebase Core Manual](https://firebase.flutter.dev/docs/manual-installation/).

2. Add the following code after `Parse().initialize(...);`:

  ```dart
  ParsePush.instance.initialize(FirebaseMessaging.instance);
  FirebaseMessaging.onMessage.listen((message) => ParsePush.instance.onMessage(message));
  ```

3. For you app to process push notification while in the background, add the following code:

  ```dart
  FirebaseMessaging.onBackgroundMessage(onBackgroundMessage);
  ```

  ```dart
  Future<void> onBackgroundMessage(RemoteMessage message) async => ParsePush.instance.onMessage(message);
  ```

## Implementation Example

The following is a code example for a simple implementation of push notifications:

```dart
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase Core
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Initialize Parse
  await Parse().initialize("applicationId", "serverUrl",
      clientKey: "clientKey", debug: true);

  // Initialize Parse push notifications
  ParsePush.instance.initialize(FirebaseMessaging.instance);
  FirebaseMessaging.onMessage
      .listen((message) => ParsePush.instance.onMessage(message));

  // Process push notifications while app is in the background
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
