part of '../../parse_server_sdk.dart';

class _ParseArray implements _Valuable<List>, _ParseSaveStateAwareChild {
  _ParseArray({this.setMode = false});

  bool setMode;

  List _savedArray = [];
  List estimatedArray = [];

  set savedArray(List array) {
    _savedArray = array.toList();
    estimatedArray = array.toList();
  }

  List get savedArray => _savedArray;

  _ParseArrayOperation? lastPreformedOperation;

  _ParseArray preformArrayOperation(
    _ParseArrayOperation arrayOperation,
  ) {
    arrayOperation.mergeWithPrevious(lastPreformedOperation ?? this);

    lastPreformedOperation = arrayOperation;

    estimatedArray = lastPreformedOperation!.value.toList();

    if (setMode) {
      lastPreformedOperation = null;
    }

    return this;
  }

  Object toJson({bool full = false}) {
    if (full) {
      return {
        'className': 'ParseArray',
        'estimatedArray': parseEncode(estimatedArray, full: full),
        'savedArray': parseEncode(_savedArray, full: full),
        'lastPreformedOperation': lastPreformedOperation?.toJson(full: full)
      };
    }

    return lastPreformedOperation?.toJson(full: full) ??
        parseEncode(estimatedArray, full: full);
  }

  factory _ParseArray.fromFullJson(Map<String, dynamic> json) {
    return _ParseArray()
      .._savedArray = parseDecode(json['savedArray'])
      ..estimatedArray = parseDecode(json['estimatedArray'])
      ..lastPreformedOperation = json['lastPreformedOperation'] == null
          ? null
          : _ParseArrayOperation.fromFullJson(json['lastPreformedOperation']);
  }

  @override
  List getValue() {
    return estimatedArray.toList();
  }

  _ParseArrayOperation? _lastPreformedOperationBeforeSaving;
  List? _estimatedArrayBeforeSaving;

  @override
  @mustCallSuper
  void onSaved() {
    setMode = false;
    _savedArray.clear();
    _savedArray.addAll(_estimatedArrayBeforeSaving ?? []);
    _estimatedArrayBeforeSaving = null;

    if (_lastPreformedOperationBeforeSaving == lastPreformedOperation) {
      // No operations were performed during the save process
      lastPreformedOperation = null;
    } else {
      // remove the saved objects and keep the new added objects while saving
      if (lastPreformedOperation is _ParseRemoveOperation) {
        lastPreformedOperation?.valueForApiRequest
            .retainWhere((e) => _savedArray.contains(e));
      } else {
        lastPreformedOperation?.valueForApiRequest
            .removeWhere((e) => _savedArray.contains(e));
      }
    }

    _lastPreformedOperationBeforeSaving = null;
  }

  @override
  @mustCallSuper
  void onSaving() {
    _lastPreformedOperationBeforeSaving = lastPreformedOperation;
    _estimatedArrayBeforeSaving = estimatedArray.toList();
  }

  @override
  @mustCallSuper
  void onRevertSaving() {
    _lastPreformedOperationBeforeSaving = null;
    _estimatedArrayBeforeSaving = null;
  }

  @override
  @mustCallSuper
  void onErrorSaving() {
    _lastPreformedOperationBeforeSaving = null;
    _estimatedArrayBeforeSaving = null;
  }

  @override
  @mustCallSuper
  void onClearUnsaved() {
    estimatedArray = savedArray;
    lastPreformedOperation = null;
    _lastPreformedOperationBeforeSaving = null;
    _estimatedArrayBeforeSaving = null;
  }
}
