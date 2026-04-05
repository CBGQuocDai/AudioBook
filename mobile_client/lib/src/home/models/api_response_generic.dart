class ApiResponseGeneric<T> {
  final int code;
  final T? data;
  final String message;

  ApiResponseGeneric({
    required this.code,
    this.data,
    required this.message,
  });

  factory ApiResponseGeneric.fromJson(
    Map<String, dynamic> json,
    T Function(Map<String, dynamic>) fromJsonT,
  ) {
    int parsedCode = 1000;
    final codeValue = json['code'];
    if (codeValue is int) {
      parsedCode = codeValue;
    } else if (codeValue is String) {
      parsedCode = int.tryParse(codeValue) ?? 1000;
    }

    return ApiResponseGeneric(
      code: parsedCode,
      data: json['data'] != null ? fromJsonT(json['data']) : null,
      message: json['message'] ?? '',
    );
  }
}
