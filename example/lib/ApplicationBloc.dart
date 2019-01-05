import 'dart:async';

import 'package:Parse_example/blocProvider.dart';
import 'package:parse_server_sdk/network/parse_livequery.dart';

class ApplicationBloc implements BlocBase {
  ///
  /// Synchronous Stream to handle the provision of the movie genres
  ///
  StreamController<List> _syncController = StreamController<List>.broadcast();
  Stream<List> get outParseStream => _syncController.stream;

  ///
  StreamController<List> _cmdController = StreamController<List>.broadcast();
  StreamSink get getMovieGenres => _cmdController.sink;

  List _genresList;

  ApplicationBloc(LiveQuery liveQuery) {
    // _genresList = liveQuery.channel as List;
    // Read all genres from Internet
    // api.movieGenres().then((list) {
    //   _genresList = list;
    // });
    _syncController.stream.listen((_) {
      _syncController.sink.addStream(liveQuery.channel.stream);
    });
    // _cmdController.stream.listen((_) {
    //   _syncController.sink
    //       .add(UnmodifiableListView<MovieGenre>(_genresList.genres));
    // });
  }

  void dispose() {
    _syncController.close();
    _cmdController.close();
  }
}
