part of flutter_parse_sdk;

class _ParseNumber implements _Valuable<num>, _ParseSaveStateAwareChild {
  num estimateNumber;

  num _savedNumber = 0.0;

  set savedNumber(num number) {
    estimateNumber = _savedNumber = number;
  }

  num get savedNumber => _savedNumber;

  _ParseNumber(this.estimateNumber, {this.setMode = false});

  bool setMode;

  _ParseNumberOperation? lastPreformedOperation;

  _ParseNumber preformNumberOperation(
    _ParseNumberOperation incrementOperation,
  ) {
    incrementOperation.mergeWithPrevious(lastPreformedOperation ?? this);

    lastPreformedOperation = incrementOperation;

    estimateNumber = lastPreformedOperation!.value;

    return this;
  }

  Object toJson({bool full = false}) {
    if (full) {
      return {
        'className': 'ParseNumber',
        'estimateNumber': estimateNumber,
        'savedNumber': _savedNumber,
        'setMode': setMode,
        'lastPreformedOperation': lastPreformedOperation?.toJson(full: full)
      };
    }

    return setMode
        ? estimateNumber
        : lastPreformedOperation?.toJson(full: full) ?? estimateNumber;
  }

  factory _ParseNumber.fromFullJson(Map<String, dynamic> json) {
    return _ParseNumber(json['estimateNumber'] as num)
      .._savedNumber = json['savedNumber'] as num
      ..setMode = json['setMode'] as bool
      ..lastPreformedOperation = json['lastPreformedOperation'] == null
          ? null
          : _ParseNumberOperation.fromFullJson(json['lastPreformedOperation']);
  }

  @override
  num getValue() {
    return estimateNumber;
  }

  _ParseNumberOperation? _lastPreformedOperationBeforeSaving;
  num? _numberForApiRequestBeforeSaving;
  num? _estimateNumberBeforeSaving;

  @override
  @mustCallSuper
  void onSaved() {
    setMode = false;

    if (_lastPreformedOperationBeforeSaving == lastPreformedOperation) {
      // No operations were performed during the save process
      lastPreformedOperation = null;
    } else {
      // Some operations performed during the save process.
      // Subtract the saved APiNumber from the modified APiNumber while saving,
      // in order to keep only the modifications that were made while saving the object
      if (lastPreformedOperation != null) {
        lastPreformedOperation!.valueForApiRequest -=
            _numberForApiRequestBeforeSaving ?? 0.0;
      }
    }

    if (_estimateNumberBeforeSaving != null) {
      _savedNumber = _estimateNumberBeforeSaving!;
    }

    _lastPreformedOperationBeforeSaving = null;
    _estimateNumberBeforeSaving = null;
    _numberForApiRequestBeforeSaving = null;
  }

  @override
  @mustCallSuper
  void onSaving() {
    _lastPreformedOperationBeforeSaving = lastPreformedOperation;
    _estimateNumberBeforeSaving = estimateNumber;
    _numberForApiRequestBeforeSaving =
        lastPreformedOperation?.valueForApiRequest;
  }

  @override
  @mustCallSuper
  void onRevertSaving() {
    _lastPreformedOperationBeforeSaving = null;
    _numberForApiRequestBeforeSaving = null;
    _estimateNumberBeforeSaving = null;
  }

  @override
  @mustCallSuper
  void onErrorSaving() {
    _lastPreformedOperationBeforeSaving = null;
    _numberForApiRequestBeforeSaving = null;
    _estimateNumberBeforeSaving = null;
  }

  @override
  @mustCallSuper
  void onClearUnsaved() {
    estimateNumber = _savedNumber;

    lastPreformedOperation = null;
    _lastPreformedOperationBeforeSaving = null;
    _estimateNumberBeforeSaving = null;
    _numberForApiRequestBeforeSaving = null;
  }
}
