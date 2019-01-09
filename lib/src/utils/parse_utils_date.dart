part of flutter_parse_sdk;

/// Converts a [String] into a [DateTime] from a Parse Server format
DateTime stringToDateTime(String date) {
  if (date == null) return null;

  try {
    return DateTime.parse(date);
  } on FormatException {
    return null;
  }
}

/// Serialize [DateTime] into an ISO-8601 full-precision extended format representation.
String dateTimeToString(DateTime datetime) {
  if (datetime == null) return null;

  if (!datetime.isUtc) {
    datetime = datetime.toUtc();
  }

  String y = _fourDigits(datetime.year);
  String m = _twoDigits(datetime.month);
  String d = _twoDigits(datetime.day);
  String h = _twoDigits(datetime.hour);
  String min = _twoDigits(datetime.minute);
  String sec = _twoDigits(datetime.second);
  String ms = _threeDigits(datetime.millisecond);

  return "$y-$m-${d}T$h:$min:$sec.${ms}Z";
}

String _fourDigits(int n) {
  int absN = n.abs();
  String sign = n < 0 ? "-" : "";
  if (absN >= 1000) return "$n";
  if (absN >= 100) return "${sign}0$absN";
  if (absN >= 10) return "${sign}00$absN";
  return "${sign}000$absN";
}

String _threeDigits(int n) {
  if (n >= 100) return "$n";
  if (n >= 10) return "0$n";
  return "00$n";
}

String _twoDigits(int n) {
  if (n >= 10) return "$n";
return "0$n";
}