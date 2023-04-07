part of flutter_parse_sdk;

/// An interface used to notify a child about its parent save state.
///
///                       x               x
///                       │               │
///                  ┌────▼─────┐ ┌───────▼────────┐
///         ┌────────┤ onSaving │ │ onClearUnsaved │
///         │        └─────┬────┘ └────────────────┘
///         │              │
/// ┌───────▼───────┐ ┌────▼────┐
/// │ onErrorSaving │ │ onSaved │
/// └───────┬───────┘ └─────────┘
///         │
/// ┌───────▼────────┐
/// │ onRevertSaving │
/// └────────────────┘
///
/// Each Parse data type should implement this interface.
/// The parent object will notify any child that implements this interface about
/// the state of the saving operation in the parent object
/// (i.e. saving, error saving, saved, revert saving, clear unsaved)
/// so the child can react to the save state. For instance,
/// when the parent notifies the children about (clear unsaved),
/// every Parse data type should clear its internal state,
/// keep only the saved data, and dispose of any unsaved data.
/// Another example is when the parent notifies the children about (being saved),
/// which means that the parent has been saved successfully. In this case,
/// every child should move its internal data from the unsaved state to the saved state.
///
///
/// The following classes make use of this interface:
///
/// * [_ParseArray], used to encapsulate a list and perform ParseArray operations on it
/// * [_ParseRelation], used to represent a Parse Relation and perform operations on the relation
/// * [_ParseNumber], used to encapsulate a num datatype and perform Parse operations on it.
abstract class _ParseSaveStateAwareChild {
  /// called when the parent object has been saved successfully.
  ///
  /// its safe to move any unsaved data to saved state
  void onSaved();

  /// called when the parent object attempts to save itself.
  ///
  /// At this stage, you can copy any unsaved data to a temporary variable so
  /// that you can move it to the saved state if the parent saves successfully.
  /// You need to take into account any operations that could be performed
  /// while the parent is being saved, and thus you should cache the current
  /// unsaved data in a separate variable. Then, when the parent saves
  /// successfully, you should move only the saved data to the saved state.
  void onSaving();

  /// called when the parent object fails to save itself.
  ///
  /// At this stage, you can dispose any temporary data that was created
  /// during [onSaving]
  void onErrorSaving();

  /// called when the parent object fails to save itself during a patch operation.
  ///
  /// In this scenario, the parent is part of a save operation for another object.
  /// This event will only be triggered after [onErrorSaving] if the parent
  /// is part of a save operation for another object
  void onRevertSaving();

  /// called when the parent object needs to clear all unsaved data.
  ///
  /// At this stage, any unsaved data or operations should be discarded,
  /// and the data should be reverted back to its original state
  /// before any modifications were made
  void onClearUnsaved();
}
