/// Standard backend envelope: `{ status, data, message }`.
class ApiResponse<T> {
  const ApiResponse({
    required this.status,
    this.data,
    this.message,
  });

  final int status;
  final T? data;
  final String? message;

  bool get isSuccess => status == 200;

  factory ApiResponse.fromJson(
    Map<String, dynamic> json,
    T Function(Object? json) parseData,
  ) {
    return ApiResponse(
      status: json['status'] as int? ?? 200,
      data: json['data'] == null ? null : parseData(json['data']),
      message: json['message'] as String?,
    );
  }
}
