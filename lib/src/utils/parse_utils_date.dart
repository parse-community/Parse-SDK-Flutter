part of flutter_parse_sdk;

/// Converts a [String] into a [DateTime] from a Parse Server format
DateTime convertStringToDateTime(String date) {
  if (date == null) return null;
  var formatter = DateFormat(ParseConstants.PARSE_DATE_FORMAT);
  var dateToReturn = formatter.parse(_removeTimeZones(date));
  return dateToReturn;
}

/// Removes timezones as our current implementation does work
String _removeTimeZones(String date) {
  // TODO - library doesn't support timezones. Monitor this
  if (date.contains('zzzZ')) {
    return date.replaceRange(date.length - 4, date.length, '');
  } else {
    return date;
  }
}
