part of flutter_parse_sdk;

// ignore_for_file: always_specify_types
class ParseRelation<T extends ParseObject> {
  ParseRelation({required ParseObject parent, required String key}) {
    if (!parent.containsKey(key)) {
      throw 'Invalid Relation key name';
    }
    _targetClass = parent.get<ParseRelation>(key)!.getTargetClass;
    _parent = parent;
    _key = key;
  }

  ParseRelation.fromJson(
      Map<String, dynamic> map, ParseObject parent, String key) {
    _parent = parent;
    _key = key;
    _targetClass = map['className'];
    _knownObjects = parseDecode(map['objects']) ?? {};
  }

  //The owning object of this ParseRelation
  late final ParseObject _parent;
  //The className of the target objects.
  late final String _targetClass;
  //The key of the relation in the parent object.
  late final String _key;
  //For offline caching, we keep track of every object we've known to be in the relation.
  late final Set<T> _knownObjects;

  QueryBuilder getQuery() {
    return QueryBuilder(ParseCoreData.instance.createObject(_targetClass))
      ..whereRelatedTo(_key, _parent.parseClassName, _parent.objectId!);
  }

  void add(T object) {
    _parent.addRelation(_key, [object]);
    _knownObjects.add(object);
  }

  void remove(T object) {
    _parent.removeRelation(_key, [object]);
    _knownObjects.remove(object);
  }

  void addAll(List<T> object) {
    _parent.addRelation(_key, object);
    _knownObjects.addAll(object);
  }

  void removeAll(List<T> object) {
    _parent.removeRelation(_key, object);
    _knownObjects.removeAll(object);
  }

  String get getTargetClass => _targetClass;

  Map<String, dynamic> toJson() => <String, dynamic>{
        '__type': keyRelation,
        'className': _targetClass,
        'objects': parseEncode(_knownObjects.toList())
      };
}
