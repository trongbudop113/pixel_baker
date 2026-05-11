import 'network_client.dart';

abstract class BaseApiRepository {
  const BaseApiRepository(this.apiClient);

  final ApiClient apiClient;

  T readItem<T>(
    Object? payload,
    T Function(Map<String, dynamic> json) fromJson,
  ) {
    return fromJson(Map<String, dynamic>.from(payload as Map));
  }

  List<T> readList<T>(
    Object? payload,
    T Function(Map<String, dynamic> json) fromJson,
  ) {
    final rawList = (payload as List<dynamic>);
    return rawList
        .map((item) => fromJson(Map<String, dynamic>.from(item as Map)))
        .toList(growable: false);
  }
}
