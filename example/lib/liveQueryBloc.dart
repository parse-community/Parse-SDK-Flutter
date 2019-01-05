import 'dart:async';

import 'package:Parse_example/blocProvider.dart';
import 'package:Parse_example/parseData.dart';
import 'package:parse_server_sdk/network/parse_livequery.dart';
import 'package:rxdart/rxdart.dart';

class LiveQueryBloc implements BlocBase {
  ///
  /// A stream only meant to return whether THIS movie is part of the parseLives
  ///
  final BehaviorSubject<dynamic> _parseLiveStreamController =
      BehaviorSubject<dynamic>();
  Stream<dynamic> get outParseLiveStream =>
      _parseLiveStreamController.stream.asBroadcastStream();

  ///
  /// Stream of all the parseLives
  ///
  final StreamController<List> _parseLiveController =
      StreamController<List>.broadcast();
  Stream<dynamic> get outParseLiveStreams => _parseLiveController.stream;
  Sink<List> get inParseLives => _parseLiveController.sink;

  ///
  /// Constructor
  ///
  LiveQueryBloc({ParseData parseData, LiveQuery liveQuery}) {
    // liveQuery.connect();
    print("LiveQueryBloc: $LiveQueryBloc");
    // Future<List<dynamic>> s =
    //     (liveQuery.channel as IOWebSocketChannel).stream.toList();
    // var v = liveQuery.channel.closeCode;
    // print("channel.closeCode: $v");
    // if (liveQuery.channel.closeCode == null) liveQuery.connect();
    var s = liveQuery.channel.stream;
    _parseLiveStreamController.addStream(s);
    // var s = Stream.fromFuture(liveQuery.channel);
    // _isParseLiveController.addStream(s);
    // _isParseLiveController.stream.asBroadcastStream();

    _parseLiveStreamController.stream.listen((_) {
      var v = liveQuery.channel.closeCode;
      print("channel.closeCode: $v");
      // print("readyState: $liveQuery.c")
      // if (liveQuery.channel.closeCode != null) liveQuery.connect();

      print("liveQuery.channel: ${liveQuery.channel} \n---> $_");
      // _isParseLiveController.sink.add(_);
      // _isParseLiveController.sink.addStream(liveQuery.channel);
      // print(JsonEncoder().convert(_));

      // Map<String, dynamic> actionData = JsonDecoder().convert(_);
      // print(JsonEncoder().convert(actionData));
      // print(eventCallbacks);
      // liveQuery.close();
    });

    //
    // We are listening to all parseLives
    //
    // _parseLiveController.stream
    //     // but, we only consider the one that matches THIS one
    //     .map((list) => list.any((item) => item.id == parseData.id))
    //     // if any, we notify that it is part of the parseLives
    //     .listen((isParseLive) => _isParseLiveController.add(isParseLive));
  }

  void dispose() {
    _parseLiveController.close();
    _parseLiveStreamController.close();
  }
}
