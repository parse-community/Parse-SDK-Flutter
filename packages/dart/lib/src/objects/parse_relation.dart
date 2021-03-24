part of flutter_parse_sdk;

// ignore_for_file: always_specify_types
class ParseRelation<T extends ParseObject> {
  ParseRelation({required ParseObject parent, required String key}) {
    _parent = parent;
    _key = key;
    _parentObjectId = parent.objectId!;
  }

  ParseRelation.fromJson(Map<String, dynamic> map) {
    _knownObjects = parseDecode(map['objects']);
    _targetClass = map['className'];
  }

  //The owning object of this ParseRelation
  ParseObject? _parent;
  // The object Id of the parent.
  String _parentObjectId = '';
  //The className of the target objects.
  String? _targetClass;
  //The key of the relation in the parent object.
  String _key = '';
  //For offline caching, we keep track of every object we've known to be in the relation.
  Set<T>? _knownObjects = Set<T>();

  QueryBuilder getQuery() {
    return QueryBuilder(ParseObject(_targetClass!))
      ..whereRelatedTo(_key, _parent!.parseClassName, _parentObjectId);
  }

  void add(T object) {
    _targetClass = object.parseClassName;
    _knownObjects!.add(object);
    _parent!.addRelation(_key, _knownObjects!.toList());
  }

  void remove(T object) {
    _targetClass = object.parseClassName;
    _knownObjects!.remove(object);
    _parent!.removeRelation(_key, _knownObjects!.toList());
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        '__type': keyRelation,
        'className': _targetClass,
        'objects': parseEncode(_knownObjects?.toList())
      };
}
