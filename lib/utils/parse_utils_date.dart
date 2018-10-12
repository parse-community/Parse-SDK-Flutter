import 'package:parse_server_sdk/base/parse_constants.dart';
import 'package:intl/intl.dart';

class ParseUtilsDates {
  static DateTime convertStringToDateTime(String date) {
    if (date == null) return null;

    var formatter = DateFormat(ParseConstants.PARSE_DATE_FORMAT);
    var dateToReturn = formatter.parse(_removeTimeZones(date));
    return dateToReturn;
  }

  static String _removeTimeZones(String date) {
    // TODO - library doesn't support timezones. Monitor this
    if (date.contains('zzzZ')) {
      return date.replaceRange(date.length - 4, date.length, '');
    } else {
      return date;
    }
  }
}
