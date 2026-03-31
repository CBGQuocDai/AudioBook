class ApiResponse<T> {
  final T data;
  final int? code;
  final String? message;

  ApiResponse({
    required this.data,
    this.code,
    this.message,
  });

  factory ApiResponse.fromJson(
      Map<String, dynamic> json,
      T Function(dynamic data) parser,
      ) {
    return ApiResponse<T>(
      data: parser(json['data']),
      code: json['code'],
      message: json['message'],
    );
  }
}