part of flutter_parse_sdk;

/// Checks wether debug is enabled
///
/// Debug can be set in 2 places, one global param in the Parse.initialise, and
/// then can be overriden class by class
bool isDebugEnabled(bool debug, ParseHTTPClient _client) {
  if (debug == null) {
    _client.data.debug != null ? debug = _client.data.debug : debug = false;
  } else {
    return debug;
  }

  return debug;
}