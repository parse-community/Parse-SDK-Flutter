class ApiError {
  ApiError(this.code, this.message, this.isTypeOfException, this.type);

  final int code;
  final String message;
  final bool isTypeOfException;
  final String type;
}
