import '../models/story_models.dart';
import '../network/base_api_repository.dart';

abstract class StoryRepository {
  Future<StoryPageResponse> fetchStoryPage();
}

class ApiStoryRepository extends BaseApiRepository implements StoryRepository {
  ApiStoryRepository(super.apiClient);

  StoryPageResponse? _cachedPageResponse;

  @override
  Future<StoryPageResponse> fetchStoryPage() async {
    if (_cachedPageResponse != null) {
      return _cachedPageResponse!;
    }

    if (!apiClient.config.hasBaseUrl) {
      return _cache(defaultStoryPageResponse);
    }

    try {
      final response = await apiClient.get<StoryPageResponse>(
        '/story',
        decoder: (json) => readItem(
          _unwrapItemPayload(json),
          StoryPageResponse.fromJson,
        ),
      );
      return _cache(response.data);
    } catch (_) {
      return _cache(defaultStoryPageResponse);
    }
  }

  Object? _unwrapItemPayload(Object? json) {
    if (json is Map<String, dynamic>) {
      final data = json['data'] ?? json['item'];
      return data ?? json;
    }
    return json;
  }

  StoryPageResponse _cache(StoryPageResponse response) {
    _cachedPageResponse = response;
    return response;
  }
}
