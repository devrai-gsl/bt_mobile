class ApiException implements Exception {
  ApiException(this.message, {this.statusCode, this.expired = false});

  final String message;
  final int? statusCode;
  final bool expired;

  @override
  String toString() => message;
}
