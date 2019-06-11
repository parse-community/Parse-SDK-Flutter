part of flutter_parse_sdk;

final _ParseDateFormat _parseDateFormat = _ParseDateFormat._internal();

/// This is the currently used date format. It is precise to the millisecond.
class _ParseDateFormat {
  _ParseDateFormat._internal();

  /// Deserialize an ISO-8601 full-precision extended format representation of date string into [DateTime].
  DateTime parse(String strDate) {
    try {
      return DateTime.parse(strDate);
    } on FormatException {
      return null;
    }
  }

  /// Serialize [DateTime] into an ISO-8601 full-precision extended format representation.
  String format(DateTime datetime) {
    if (!datetime.isUtc) {
      datetime = datetime.toUtc();
    }

    final String y = _fourDigits(datetime.year);
    final String m = _twoDigits(datetime.month);
    final String d = _twoDigits(datetime.day);
    final String h = _twoDigits(datetime.hour);
    final String min = _twoDigits(datetime.minute);
    final String sec = _twoDigits(datetime.second);
    final String ms = _threeDigits(datetime.millisecond);

    return '$y-$m-${d}T$h:$min:$sec.${ms}Z';
  }

  static String _fourDigits(int n) {
    final int absN = n.abs();
    final String sign = n < 0 ? '-' : '';
    if (absN >= 1000) {
      return '$n';
    }
    if (absN >= 100) {
      return '${sign}0$absN';
    }
    if (absN >= 10) {
      return '${sign}00$absN';
    }
    return '${sign}000$absN';
  }

  static String _threeDigits(int n) {
    if (n >= 100) {
      return '$n';
    }
    if (n >= 10) {
      return '0$n';
    }
    return '00$n';
  }

  static String _twoDigits(int n) {
    if (n >= 10) {
      return '$n';
    }
    return '0$n';
  }
}
