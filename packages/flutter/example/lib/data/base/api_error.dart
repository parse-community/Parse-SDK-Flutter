class ApiError {
  ApiError(this.code, this.message, this.exception, this.type);

  final int code;
  final String message;
  final Exception exception;
  final String type;
}
