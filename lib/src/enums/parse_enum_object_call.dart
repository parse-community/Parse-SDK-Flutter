part of flutter_parse_sdk;

enum ParseApiObjectCallType { get, getAll, create, save, query, delete }

class ParseApiObjectCallTypeUtil {
  static getEnumValue(ParseApiObjectCallType type) {
    switch (type) {
      case ParseApiObjectCallType.get:
        {
          return 'get';
        }
      case ParseApiObjectCallType.getAll:
        {
          return 'getAll';
        }
      case ParseApiObjectCallType.create:
        {
          return 'create';
        }
      case ParseApiObjectCallType.save:
        {
          return 'save';
        }
      case ParseApiObjectCallType.query:
        {
          return 'query';
        }
      case ParseApiObjectCallType.delete:
        {
          return 'delete';
        }
    }
  }
}
