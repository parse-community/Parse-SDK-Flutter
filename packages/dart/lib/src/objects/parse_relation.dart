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

  ParseRelation.fromJson(Map<String, dynamic> map) {
    _targetClass = map['className'];
  }

  //The owning object of this ParseRelation
  ParseObject? _parent;

  //The className of the target objects.
  late final String _targetClass;

  //The key of the relation in the parent object.
  late final String _key;

  //For offline caching, we keep track of every object we've known to be in the relation.
  /// This cannot work as a cache!
  /// Each time a relation instance is requested, a new instance is always returned.
  /// It cannot be done otherwise if you want to work with custom objects.
  /// This is due to the fact that when parsing the parent object
  /// the first time you cannot dynamically create a ParseRelation<CustomObject extends ParseObject> instance.
  /// Only a ParseRelation<ParseObject> can be created.
  ///
  /// An alternative version is to avoid defining relations by relying on custom objects.
  /// Then you can use this as a cache!
  ///
  /// An important thing to note is that the server includes in the response the class name for the relation.
  /// So, another valid proposal is to use the same pattern as used for custom objects
  /// and use this class only as a default and allow the user to extend it.
  /// In order to guarantee the correct type at runtime.
  ///
  /// Set<T>? _knownObjects = <T>{};

  QueryBuilder getQuery() {
    return QueryBuilder(ParseCoreData.instance.createObject(_targetClass))
      ..whereRelatedTo(_key, _parent!.parseClassName, _parent!.objectId!);
  }

  void add(T object) {
    _parent!.addRelation(_key, this, [object]);
  }

  void remove(T object) {
    _parent!.removeRelation(_key, this, [object]);
  }

  void addAll(List<T> object) {
    _parent!.addRelation(_key, this, object);
  }

  void removeAll(List<T> object) {
    _parent!.removeRelation(_key, this, object);
  }

  String get getTargetClass => _targetClass;

  Map<String, dynamic> toJson() => <String, dynamic>{
        '__type': keyRelation,
        'className': _targetClass,
      };
}
