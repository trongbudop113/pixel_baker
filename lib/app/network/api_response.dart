class ApiResponse<T> {
  const ApiResponse({
    required this.data,
    required this.statusCode,
    required this.headers,
  });

  final T data;
  final int statusCode;
  final Map<String, String> headers;

  bool get isSuccess => statusCode >= 200 && statusCode < 300;
}
