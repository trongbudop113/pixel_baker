class ApiConfig {
  const ApiConfig({
    required this.baseUrl,
    this.connectTimeout = const Duration(seconds: 15),
    this.receiveTimeout = const Duration(seconds: 15),
    this.defaultHeaders = const {
      'Accept': 'application/json',
      'Content-Type': 'application/json',
    },
  });

  factory ApiConfig.fromEnvironment() {
    const connectTimeoutMs = int.fromEnvironment(
      'API_CONNECT_TIMEOUT_MS',
      defaultValue: 15000,
    );
    const receiveTimeoutMs = int.fromEnvironment(
      'API_RECEIVE_TIMEOUT_MS',
      defaultValue: 15000,
    );

    return ApiConfig(
      baseUrl: const String.fromEnvironment('API_BASE_URL'),
      connectTimeout: const Duration(milliseconds: connectTimeoutMs),
      receiveTimeout: const Duration(milliseconds: receiveTimeoutMs),
    );
  }

  final String baseUrl;
  final Duration connectTimeout;
  final Duration receiveTimeout;
  final Map<String, String> defaultHeaders;

  bool get hasBaseUrl => baseUrl.trim().isNotEmpty;
}
