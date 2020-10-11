part of flutter_parse_sdk;

/// Creates method which can be used to deep clone objects
abstract class ParseCloneable {
  dynamic clone(Map<String, dynamic> map);
}
