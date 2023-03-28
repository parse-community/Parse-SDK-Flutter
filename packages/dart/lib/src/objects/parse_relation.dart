part of flutter_parse_sdk;

abstract class ParseRelation<T extends ParseObject> {
  //The owning object of this ParseRelation
  ParseObject getParent();

  //The key of the relation in the parent object. i.e. the column name
  String getKey();

  factory ParseRelation({
    required ParseObject parent,
    required String key,
  }) {
    return _ParseRelation(parent: parent, key: key);
  }

  /// The className of the target objects.
  @Deprecated('use the targetClass getter')
  String get getTargetClass;

  /// The className of the target objects.
  String? get targetClass;

  QueryBuilder getQuery();

  void add(T parseObject);

  void remove(T parseObject);

  factory ParseRelation.fromJson(
    Map<String, dynamic> map, {
    ParseObject? parent,
    String? key,
  }) {
    return _ParseRelation.fromJson(map, parent: parent, key: key);
  }

  Map<String, dynamic> toJson({bool full = false});
}

class _ParseRelation<T extends ParseObject>
    implements ParseRelation<T>, _ParseSaveStateAwareChild {
  String? _targetClass;

  ParseObject? parent;

  String? key;

  //For offline caching, we keep track of every object we've known to be in the relation.
  Set<T> knownObjects = <T>{};

  _ParseRelationOperation? lastPreformedOperation;

  _ParseRelation({required this.parent, required this.key});

  Set<ParseObject> valueForApiRequest() {
    return lastPreformedOperation?.valueForApiRequest ?? {};
  }

  @override
  ParseObject getParent() {
    return parent!;
  }

  @override
  String getKey() {
    return key!;
  }

  _ParseRelation<T> preformRelationOperation(
    _ParseRelationOperation relationOperation,
  ) {
    resolveTargetClassFromRelationObjets(relationOperation.value);

    relationOperation.mergeWithPrevious(lastPreformedOperation ?? this);

    lastPreformedOperation = relationOperation;

    knownObjects = lastPreformedOperation!.value.toSet() as Set<T>;

    return this;
  }

  @override
  QueryBuilder getQuery() {
    final parentClassName = parent!.parseClassName;
    final parentObjectId = parent!.objectId;

    if (parentObjectId == null) {
      throw ParseRelationException(
          'The parent objectId is null. Query based on a Relation require ObjectId');
    }

    final QueryBuilder queryBuilder;

    if (_targetClass == null) {
      queryBuilder = QueryBuilder(
        ParseCoreData.instance.createObject(parentClassName),
      )..setRedirectClassNameForKey(key!);
    } else {
      queryBuilder = QueryBuilder(
        ParseCoreData.instance.createObject(_targetClass!),
      );
    }

    return queryBuilder..whereRelatedTo(key!, parentClassName, parentObjectId);
  }

  @override
  void add(T parseObject) {
    parent!.addRelation(key!, [parseObject]);
  }

  @override
  void remove(T parseObject) {
    parent!.removeRelation(key!, [parseObject]);
  }

  @override
  String get getTargetClass => _targetClass ?? '';

  @override
  String? get targetClass => _targetClass;

  _ParseRelation.fromJson(
    Map<String, dynamic> json, {
    ParseObject? parent,
    String? key,
  }) {
    if (parent != null) {
      this.parent = parent;
    }
    if (key != null) {
      this.key = key;
    }

    knownObjects = Set.from(parseDecode(json['objects']) ?? {});
    _targetClass = json['className'];
  }

  _ParseRelation.fromFullJson(Map<String, dynamic> json) {
    knownObjects = Set.from(parseDecode(json['objects']));
    _targetClass = json['className'];
    key = json['key'];
    knownObjects = Set.from(parseDecode(json['objects']) ?? {});
    lastPreformedOperation = json['lastPreformedOperation'] == null
        ? null
        : _ParseRelationOperation.fromFullJson(json['lastPreformedOperation']);
  }

  @override
  Map<String, dynamic> toJson({bool full = false}) {
    if (full) {
      return {
        'className': 'ParseRelation',
        'targetClass': targetClass,
        'key': key,
        'objects': parseEncode(knownObjects, full: full),
        'lastPreformedOperation': lastPreformedOperation?.toJson(full: full)
      };
    }

    return lastPreformedOperation?.toJson(full: full) ?? {};
  }

  bool shouldIncludeInRequest() {
    return lastPreformedOperation?.valueForApiRequest.isNotEmpty ?? false;
  }

  void resolveTargetClassFromRelationObjets(Set<ParseObject> relationObjects) {
    var potentialTargetClass = _targetClass;

    for (final parseObject in relationObjects) {
      potentialTargetClass = parseObject.parseClassName;

      if (_targetClass != null && potentialTargetClass != _targetClass) {
        ParseRelationException(
            'Can not add more then one class for a relation. the current target '
            'class $targetClass and the passed class $potentialTargetClass');
      }
    }

    _targetClass = potentialTargetClass;
  }

  _ParseRelationOperation? _lastPreformedOperationBeforeSaving;
  List? _valueForApiRequestBeforeSaving;

  @override
  void onSaved() {
    if (_lastPreformedOperationBeforeSaving == lastPreformedOperation) {
      // No operations were performed during the save process
      lastPreformedOperation = null;
    } else {
      // remove the saved objects and keep the new added objects while saving
      lastPreformedOperation?.valueForApiRequest
          .removeAll(_valueForApiRequestBeforeSaving ?? []);
    }

    _lastPreformedOperationBeforeSaving = null;
    _valueForApiRequestBeforeSaving = null;
  }

  @override
  void onSaving() {
    _lastPreformedOperationBeforeSaving = lastPreformedOperation;
    _valueForApiRequestBeforeSaving =
        lastPreformedOperation?.valueForApiRequest.toList();
  }

  @override
  void onRevertSaving() {
    _lastPreformedOperationBeforeSaving = null;
    _valueForApiRequestBeforeSaving = null;
  }

  @override
  void onClearUnsaved() {
    if (lastPreformedOperation != null) {
      knownObjects.removeWhere(
        (e) => lastPreformedOperation!.valueForApiRequest.contains(e),
      );
    }

    lastPreformedOperation = null;
    _lastPreformedOperationBeforeSaving = null;
    _valueForApiRequestBeforeSaving = null;
  }
}
