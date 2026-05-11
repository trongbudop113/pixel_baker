import 'api_method.dart';

class ApiRequest {
  const ApiRequest({
    required this.path,
    this.method = ApiMethod.get,
    this.queryParameters = const {},
    this.headers = const {},
    this.body,
    this.requiresAuth = false,
    this.timeout,
  });

  final String path;
  final ApiMethod method;
  final Map<String, dynamic> queryParameters;
  final Map<String, String> headers;
  final Object? body;
  final bool requiresAuth;
  final Duration? timeout;
}
