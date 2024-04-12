part of '../../parse_server_sdk.dart';

/// Creates method which can be used to deep clone objects
abstract class ParseCloneable {
  dynamic clone(Map<String, dynamic> map);
}
