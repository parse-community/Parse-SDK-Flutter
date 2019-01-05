import 'dart:async';
import 'package:Parse_example/blocProvider.dart';
import 'package:rxdart/rxdart.dart';

class CountBLoC implements BlocBase {
  int _count = 0;
  var _countController = StreamController<int>.broadcast();
  var _subject = BehaviorSubject<int>();
  Stream<int> get stream => _subject.stream;
  int get value => _count;

  increment() {
    _countController.sink.add(++_count);
  }

  dispose() {
    _countController.close();
  }
}
