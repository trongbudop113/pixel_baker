import '../models/contact_models.dart';
import '../network/base_api_repository.dart';

abstract class ContactRepository {
  Future<ContactPageResponse> fetchContactPage();
  Future<String> submitContact(ContactSubmitRequest request);
}

class ApiContactRepository extends BaseApiRepository implements ContactRepository {
  ApiContactRepository(super.apiClient);

  ContactPageResponse? _cachedPageResponse;

  @override
  Future<ContactPageResponse> fetchContactPage() async {
    if (_cachedPageResponse != null) {
      return _cachedPageResponse!;
    }

    if (!apiClient.config.hasBaseUrl) {
      return _cache(defaultContactPageResponse);
    }

    try {
      final response = await apiClient.get<ContactPageResponse>(
        '/contact',
        decoder: (json) => readItem(
          _unwrapItemPayload(json),
          ContactPageResponse.fromJson,
        ),
      );
      return _cache(response.data);
    } catch (_) {
      return _cache(defaultContactPageResponse);
    }
  }

  Object? _unwrapItemPayload(Object? json) {
    if (json is Map<String, dynamic>) {
      final data = json['data'] ?? json['item'];
      return data ?? json;
    }
    return json;
  }

  ContactPageResponse _cache(ContactPageResponse response) {
    _cachedPageResponse = response;
    return response;
  }

  @override
  Future<String> submitContact(ContactSubmitRequest request) async {
    if (!apiClient.config.hasBaseUrl) {
      return 'Đã gửi liên hệ thành công. Chúng tôi sẽ phản hồi sớm nhất.';
    }

    final response = await apiClient.post<String>(
      '/contact/submit',
      body: request.toJson(),
      decoder: (json) {
        final payload = _unwrapItemPayload(json);
        if (payload is Map<String, dynamic>) {
          return (payload['message'] ??
                  'Đã gửi liên hệ thành công. Chúng tôi sẽ phản hồi sớm nhất.')
              .toString();
        }
        return 'Đã gửi liên hệ thành công. Chúng tôi sẽ phản hồi sớm nhất.';
      },
    );
    return response.data;
  }
}
