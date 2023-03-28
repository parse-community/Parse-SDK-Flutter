part of flutter_parse_sdk;

abstract class _ParseSaveStateAwareChild {
  void onSaved();

  void onSaving();

  void onRevertSaving();

  void onClearUnsaved();
}
