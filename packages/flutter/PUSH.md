## Parse Push

### Installation
1 : first need install [Firebase Core](https://firebase.flutter.dev/docs/overview) and [Cloud Messaging](https://firebase.flutter.dev/docs/messaging/overview)

tip: It is recommended to check the [Firebase Core Manual](https://firebase.flutter.dev/docs/manual-installation/)

2 : Set the following codes after Parse().initialize
```dart
await Parse().initialize(...);

ParsePush.instance.initialize(FirebaseMessaging.instance);
FirebaseMessaging.onMessage.listen((message) => ParsePush.instance.onMessage(message));
```

3: To work with push notifications after closing the application, follow the steps below.

Put the following code after the above codes
```dart
FirebaseMessaging.onBackgroundMessage(onBackgroundMessage);
```

Put the following function in your code
```dart
Future<void> onBackgroundMessage(RemoteMessage message) async => ParsePush.instance.onMessage(message);
```

### Implemented example
Your code should look like the following code

```dart
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  await Parse().initialize("PeyI6koAvhlnLi3EkDu3Z7BsDoCQgYRLYqsBjHHS",
      "https://parseapi.back4app.com/",
      clientKey: "Vs0Lys86bX9ygVwBNWoyKa8kibRWZtpYs2P6zUYV", debug: true);

  ParsePush.instance.initialize(FirebaseMessaging.instance);
  FirebaseMessaging.onMessage.listen((message) => ParsePush.instance.onMessage(message));
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
      ...
```