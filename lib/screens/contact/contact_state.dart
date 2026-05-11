import '../../app/models/contact_models.dart';
import '../../app/repositories/contact_repository.dart';
import '../../app/services/app_services.dart';
import '../../app/state/screen_controller.dart';

class ContactViewState {
  const ContactViewState({
    required this.pageResponse,
    this.selectedInfoIndex = 0,
    this.isLoading = false,
    this.isSubmitting = false,
    this.errorMessage,
    this.submitMessage,
    this.isSubmitSuccess = false,
  });

  final ContactPageResponse pageResponse;
  final int selectedInfoIndex;
  final bool isLoading;
  final bool isSubmitting;
  final String? errorMessage;
  final String? submitMessage;
  final bool isSubmitSuccess;

  ContactViewState copyWith({
    ContactPageResponse? pageResponse,
    int? selectedInfoIndex,
    bool? isLoading,
    bool? isSubmitting,
    String? errorMessage,
    String? submitMessage,
    bool? isSubmitSuccess,
    bool clearErrorMessage = false,
    bool clearSubmitMessage = false,
  }) {
    return ContactViewState(
      pageResponse: pageResponse ?? this.pageResponse,
      selectedInfoIndex: selectedInfoIndex ?? this.selectedInfoIndex,
      isLoading: isLoading ?? this.isLoading,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      errorMessage:
          clearErrorMessage ? null : (errorMessage ?? this.errorMessage),
      submitMessage:
          clearSubmitMessage ? null : (submitMessage ?? this.submitMessage),
      isSubmitSuccess: isSubmitSuccess ?? this.isSubmitSuccess,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is ContactViewState &&
        other.pageResponse == pageResponse &&
        other.selectedInfoIndex == selectedInfoIndex &&
        other.isLoading == isLoading &&
        other.isSubmitting == isSubmitting &&
        other.errorMessage == errorMessage &&
        other.submitMessage == submitMessage &&
        other.isSubmitSuccess == isSubmitSuccess;
  }

  @override
  int get hashCode => Object.hash(
        pageResponse,
        selectedInfoIndex,
        isLoading,
        isSubmitting,
        errorMessage,
        submitMessage,
        isSubmitSuccess,
      );
}

class ContactState extends ScreenController<ContactViewState, Never> {
  ContactState({
    ContactRepository? repository,
  })  : _repository = repository ?? AppServices.instance.contactRepository,
        super(const ContactViewState(pageResponse: defaultContactPageResponse));

  final ContactRepository _repository;
  bool _hasLoaded = false;

  ContactPageResponse get pageResponse => state.pageResponse;
  int get selectedInfoIndex => state.selectedInfoIndex;
  bool get isLoading => state.isLoading;
  bool get isSubmitting => state.isSubmitting;
  String? get errorMessage => state.errorMessage;
  String? get submitMessage => state.submitMessage;
  bool get isSubmitSuccess => state.isSubmitSuccess;

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
      final page = await _repository.fetchContactPage();
      update((current) => current.copyWith(
            pageResponse: page,
            isLoading: false,
            clearErrorMessage: true,
          ));
    } catch (_) {
      _hasLoaded = false;
      update((current) => current.copyWith(
            isLoading: false,
            errorMessage: 'Không thể tải dữ liệu trang liên hệ.',
          ));
    }
  }

  void selectInfo(int index) {
    update((current) => current.copyWith(selectedInfoIndex: index));
  }

  Future<void> submit({
    required String fullName,
    required String email,
    required String phone,
    required String message,
  }) async {
    final normalizedName = fullName.trim();
    final normalizedEmail = email.trim();
    final normalizedPhone = phone.trim();
    final normalizedMessage = message.trim();

    if (normalizedName.length < 2 ||
        normalizedEmail.isEmpty ||
        !normalizedEmail.contains('@') ||
        normalizedMessage.length < 10) {
      update(
        (current) => current.copyWith(
          submitMessage:
              'Vui lòng nhập đầy đủ họ tên, email hợp lệ và nội dung ít nhất 10 ký tự.',
          isSubmitSuccess: false,
        ),
      );
      return;
    }
    if (state.isSubmitting) {
      return;
    }

    update(
      (current) => current.copyWith(
        isSubmitting: true,
        clearSubmitMessage: true,
      ),
    );

    try {
      final responseMessage = await _repository.submitContact(
        ContactSubmitRequest(
          fullName: normalizedName,
          email: normalizedEmail,
          phone: normalizedPhone.isEmpty ? null : normalizedPhone,
          message: normalizedMessage,
        ),
      );
      update(
        (current) => current.copyWith(
          isSubmitting: false,
          submitMessage: responseMessage,
          isSubmitSuccess: true,
        ),
      );
    } catch (_) {
      update(
        (current) => current.copyWith(
          isSubmitting: false,
          submitMessage: 'Không thể gửi liên hệ lúc này.',
          isSubmitSuccess: false,
        ),
      );
    }
  }
}
