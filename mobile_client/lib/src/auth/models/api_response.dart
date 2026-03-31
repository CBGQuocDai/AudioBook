class ApiResponse<T> {
  final int code;
  final T? data;
  final String message;

  const ApiResponse({
    this.code = 1000,
    this.data,
    this.message = 'success',
  });
}
