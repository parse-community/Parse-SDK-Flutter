part of flutter_parse_sdk;

/// Checks whether debug is enabled
///
/// Debug can be set in 2 places, one global param in the Parse.initialise, and
/// then can be overidden class by class
bool isDebugEnabled({objectLevelDebug: false}) {
  bool debug = objectLevelDebug;
  if (ParseCoreData().debug != null) debug = ParseCoreData().debug;
  return debug;
}