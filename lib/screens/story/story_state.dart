import '../../app/models/story_models.dart';
import '../../app/repositories/story_repository.dart';
import '../../app/services/app_services.dart';
import '../../app/state/screen_controller.dart';

class StoryViewState {
  const StoryViewState({
    required this.pageResponse,
    this.isLoading = false,
    this.errorMessage,
  });

  final StoryPageResponse pageResponse;
  final bool isLoading;
  final String? errorMessage;

  StoryViewState copyWith({
    StoryPageResponse? pageResponse,
    bool? isLoading,
    String? errorMessage,
    bool clearErrorMessage = false,
  }) {
    return StoryViewState(
      pageResponse: pageResponse ?? this.pageResponse,
      isLoading: isLoading ?? this.isLoading,
      errorMessage:
          clearErrorMessage ? null : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is StoryViewState &&
        other.pageResponse == pageResponse &&
        other.isLoading == isLoading &&
        other.errorMessage == errorMessage;
  }

  @override
  int get hashCode => Object.hash(pageResponse, isLoading, errorMessage);
}

class StoryState extends ScreenController<StoryViewState, Never> {
  StoryState({
    StoryRepository? repository,
  })  : _repository = repository ?? AppServices.instance.storyRepository,
        super(const StoryViewState(pageResponse: defaultStoryPageResponse));

  final StoryRepository _repository;
  bool _hasLoaded = false;

  StoryPageResponse get pageResponse => state.pageResponse;
  bool get isLoading => state.isLoading;
  String? get errorMessage => state.errorMessage;

  Future<void> load() async {
    if (_hasLoaded) {
      return;
    }
    _hasLoaded = true;

    update((current) => current.copyWith(
          isLoading: true,
          clearErrorMessage: true,
        ));

    try {
      final page = await _repository.fetchStoryPage();
      update((current) => current.copyWith(
            pageResponse: page,
            isLoading: false,
            clearErrorMessage: true,
          ));
    } catch (_) {
      _hasLoaded = false;
      update((current) => current.copyWith(
            isLoading: false,
            errorMessage: 'Không thể tải dữ liệu trang câu chuyện.',
          ));
    }
  }
}
