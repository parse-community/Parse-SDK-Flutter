enum ParseApiObjectCallType {
  get, getAll, create, save, query, delete
}

getEnumValue(ParseApiObjectCallType type){
    switch (type){
      case ParseApiObjectCallType.get: {
        return 'get';
      }
      case ParseApiObjectCallType.getAll: {
        return 'getAll';
      }
      case ParseApiObjectCallType.create: {
        return 'create';
      }
      case ParseApiObjectCallType.save: {
        return 'save';
      }
      case ParseApiObjectCallType.query: {
        return 'query';
      }
      case ParseApiObjectCallType.delete: {
        return 'delete';
      }
    }
}