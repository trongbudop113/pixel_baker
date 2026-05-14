import 'package:flutter/material.dart';

import '../../app/models/contact_models.dart';
import '../shared/app_header.dart';
import '../shared/pixel_footer.dart';
import 'contact_state.dart';

class ContactColors {
  static const red = Color(0xFFE53935);
  static const blue = Color(0xFF1E88E5);
  static const gray = Color(0xFF8A8A8A);
}

class ResponsiveContactScreen extends StatefulWidget {
  const ResponsiveContactScreen({super.key, this.showTopHeader = true});
  final bool showTopHeader;

  @override
  State<ResponsiveContactScreen> createState() =>
      _ResponsiveContactScreenState();
}

class _ResponsiveContactScreenState extends State<ResponsiveContactScreen> {
  final ContactState _contactState = ContactState();
  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _messageController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _contactState.load();
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _messageController.dispose();
    _contactState.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 900;
        return isMobile
            ? MobileContactLayout(
                state: _contactState,
                fullNameController: _fullNameController,
                emailController: _emailController,
                phoneController: _phoneController,
                messageController: _messageController,
                showTopHeader: widget.showTopHeader,
              )
            : WebContactLayout(
                state: _contactState,
                fullNameController: _fullNameController,
                emailController: _emailController,
                phoneController: _phoneController,
                messageController: _messageController,
                showTopHeader: widget.showTopHeader,
              );
      },
    );
  }
}

class WebContactLayout extends StatelessWidget {
  const WebContactLayout({
    super.key,
    required this.state,
    required this.fullNameController,
    required this.emailController,
    required this.phoneController,
    required this.messageController,
    this.showTopHeader = true,
  });

  final ContactState state;
  final TextEditingController fullNameController;
  final TextEditingController emailController;
  final TextEditingController phoneController;
  final TextEditingController messageController;
  final bool showTopHeader;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: state,
      builder: (context, _) {
        final page = state.pageResponse;
        if (state.isLoading) {
          return const _ContactLoadingSkeleton();
        }
        return SizedBox(
          width: 1200,
          height: double.infinity,
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: ContactColors.gray, width: 3),
            ),
            child: Column(
              children: [
                if (showTopHeader)
                  const PixelHeaderBar(
                    rightLabel: 'liên hệ',
                    showBack: true,
                    showBrand: false,
                  ),
                if (showTopHeader) const SizedBox(height: 12),
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        _topBar(page),
                        if (state.errorMessage != null) ...[
                          const SizedBox(height: 12),
                          _statusBanner(state.errorMessage!),
                        ],
                        if (state.submitMessage != null) ...[
                          const SizedBox(height: 12),
                          _statusBanner(
                            state.submitMessage!,
                            isSuccess: state.isSubmitSuccess,
                          ),
                        ],
                        const SizedBox(height: 12),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(flex: 2, child: _leftForm(page)),
                            const SizedBox(width: 12),
                            Expanded(child: _rightInfo(page.infoCards)),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const PixelFooter(label: 'PIXEL BAKERY | LIÊN HỆ'),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _topBar(ContactPageResponse page) => _card(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _txt(page.heroTitle, ContactColors.blue, 22, FontWeight.w900),
            const SizedBox(height: 2),
            _txt(
              page.heroDescription,
              ContactColors.gray,
              11,
              FontWeight.w500,
            ),
          ],
        ),
      );

  Widget _leftForm(ContactPageResponse page) => _card(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _txt(page.formTitle, ContactColors.blue, 16, FontWeight.w800),
            ..._buildFormFields(page.fields, multilineHeight: 100),
            const SizedBox(height: 10),
            GestureDetector(
              onTap: state.isSubmitting
                  ? null
                  : () => state.submit(
                        fullName: fullNameController.text,
                        email: emailController.text,
                        phone: phoneController.text,
                        message: messageController.text,
                      ),
              child: _btn(
                state.isSubmitting ? 'Đang gửi...' : page.submitLabel,
              ),
            ),
          ],
        ),
      );

  Widget _rightInfo(List<ContactInfoCardModel> infoCards) => Column(
        children: List.generate(infoCards.length * 2 - 1, (index) {
          if (index.isOdd) {
            return const SizedBox(height: 8);
          }
          final itemIndex = index ~/ 2;
          final info = infoCards[itemIndex];
          return GestureDetector(
            onTap: () => state.selectInfo(itemIndex),
            child: _infoCard(
              info,
              highlighted: state.selectedInfoIndex == itemIndex,
            ),
          );
        }),
      );

  Widget _infoCard(ContactInfoCardModel info, {required bool highlighted}) =>
      _card(
        highlighted: highlighted,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _txt(info.title, ContactColors.blue, 14, FontWeight.w800),
            const SizedBox(height: 8),
            if (info.isPreviewCard)
              Container(
                width: double.infinity,
                height: 78,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: const Color(0xFFF8F8F8),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: ContactColors.gray, width: 1.5),
                ),
                child: _txt(
                  info.previewLabel ?? '',
                  ContactColors.gray,
                  11,
                  FontWeight.w600,
                ),
              )
            else
              ...info.lines.map(
                (line) => _txt(line, Colors.black87, 11, FontWeight.w500),
              ),
          ],
        ),
      );

  List<Widget> _buildFormFields(
    List<ContactFormFieldModel> fields, {
    required double multilineHeight,
  }) {
    final controllers = [
      fullNameController,
      emailController,
      phoneController,
      messageController,
    ];
    final widgets = <Widget>[];
    for (var index = 0; index < fields.length; index++) {
      final field = fields[index];
      widgets.add(const SizedBox(height: 8));
      widgets.add(
        _field(
          field.placeholder,
          controller: index < controllers.length ? controllers[index] : null,
          h: field.multiline ? multilineHeight : 36,
          multiline: field.multiline,
        ),
      );
    }
    return widgets;
  }

  Widget _card({required Widget child, bool highlighted = false}) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: highlighted ? ContactColors.blue : ContactColors.gray,
            width: 1.5,
          ),
        ),
        child: child,
      );

  Widget _field(
    String hint, {
    TextEditingController? controller,
    double h = 36,
    bool multiline = false,
  }) => Container(
        width: double.infinity,
        height: h,
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: const Color(0xFFF8F8F8),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: ContactColors.gray, width: 1.5),
        ),
        child: TextField(
          controller: controller,
          maxLines: multiline ? null : 1,
          style: const TextStyle(
            color: Color(0xFF111827),
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
          decoration: InputDecoration(
            hintText: hint,
            filled: false,
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
            disabledBorder: InputBorder.none,
            errorBorder: InputBorder.none,
            focusedErrorBorder: InputBorder.none,
            isCollapsed: true,
            contentPadding: EdgeInsets.zero,
            hintStyle: const TextStyle(
              color: ContactColors.gray,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      );

  Widget _btn(String text) => Container(
        width: double.infinity,
        height: 30,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: ContactColors.red,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: ContactColors.gray, width: 1.5),
        ),
        child: _txt(text, Colors.white, 11, FontWeight.w800),
      );

  Widget _statusBanner(String message, {bool isSuccess = false}) => Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: isSuccess ? const Color(0xFFEAF8EF) : const Color(0xFFFCEAEA),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: isSuccess ? const Color(0xFF2E7D32) : ContactColors.red,
            width: 1.5,
          ),
        ),
        child: _txt(
          message,
          isSuccess ? const Color(0xFF2E7D32) : ContactColors.red,
          11,
          FontWeight.w700,
        ),
      );

  Widget _txt(String text, Color color, double size, FontWeight fw) => Text(
        text,
        style: TextStyle(color: color, fontSize: size, fontWeight: fw),
      );
}

class _ContactLoadingSkeleton extends StatelessWidget {
  const _ContactLoadingSkeleton({this.mobile = false});

  final bool mobile;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: mobile ? 390 : 1200,
      height: double.infinity,
      padding: EdgeInsets.all(mobile ? 12 : 24),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: ContactColors.gray, width: 3),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _line(width: mobile ? 180 : 260, height: mobile ? 18 : 22),
          SizedBox(height: mobile ? 10 : 12),
          _block(height: mobile ? 90 : 110),
          SizedBox(height: mobile ? 10 : 12),
          if (mobile) ...[
            _block(height: 230),
            const SizedBox(height: 10),
            _block(height: 180),
          ] else
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: _block(height: 360)),
                  const SizedBox(width: 12),
                  Expanded(child: _block(height: 260)),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _block({required double height}) => Container(
        height: height,
        decoration: BoxDecoration(
          color: const Color(0xFFF3F5F9),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: ContactColors.gray, width: 2),
        ),
      );

  Widget _line({required double width, required double height}) => Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: const Color(0xFFE5EAF2),
          borderRadius: BorderRadius.circular(999),
        ),
      );
}

class MobileContactLayout extends StatelessWidget {
  const MobileContactLayout({
    super.key,
    required this.state,
    required this.fullNameController,
    required this.emailController,
    required this.phoneController,
    required this.messageController,
    this.showTopHeader = true,
  });

  final ContactState state;
  final TextEditingController fullNameController;
  final TextEditingController emailController;
  final TextEditingController phoneController;
  final TextEditingController messageController;
  final bool showTopHeader;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: state,
      builder: (context, _) {
        final page = state.pageResponse;
        if (state.isLoading) {
          return const _ContactLoadingSkeleton(mobile: true);
        }
        return SizedBox(
          width: 390,
          height: double.infinity,
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: ContactColors.gray, width: 3),
            ),
            child: Column(
              children: [
                if (showTopHeader)
                  const PixelHeaderBar(
                    rightLabel: 'liên hệ',
                    showBack: true,
                    showBrand: false,
                  ),
                if (showTopHeader) const SizedBox(height: 8),
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        // Hero title (đồng bộ với web)
                        _box(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _txt(page.heroTitle, ContactColors.blue, 18, FontWeight.w900),
                              const SizedBox(height: 2),
                              _txt(page.heroDescription, ContactColors.gray, 11, FontWeight.w500),
                            ],
                          ),
                        ),
                        if (state.errorMessage != null) ...[
                          const SizedBox(height: 8),
                          _box(child: _statusText(state.errorMessage!)),
                        ],
                        if (state.submitMessage != null) ...[
                          const SizedBox(height: 8),
                          _box(child: _statusText(state.submitMessage!, isSuccess: state.isSubmitSuccess)),
                        ],
                        const SizedBox(height: 8),
                        // Form (đồng bộ với web _leftForm)
                        _box(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _txt(page.formTitle, ContactColors.blue, 16, FontWeight.w800),
                              ..._buildFormFields(page.fields),
                              const SizedBox(height: 8),
                              GestureDetector(
                                onTap: state.isSubmitting
                                    ? null
                                    : () => state.submit(
                                          fullName: fullNameController.text,
                                          email: emailController.text,
                                          phone: phoneController.text,
                                          message: messageController.text,
                                        ),
                                child: _btn(state.isSubmitting ? 'Đang gửi...' : page.submitLabel),
                              ),
                            ],
                          ),
                        ),
                        // Info cards (đồng bộ với web _rightInfo)
                        ..._buildInfoCards(page.infoCards),
                        const SizedBox(height: 8),
                        _bottomNav(page.bottomNavLabels),
                        const SizedBox(height: 8),
                        const PixelFooter(label: 'PIXEL BAKERY | LIÊN HỆ', mobile: true),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _mobileTop(ContactPageResponse page) => Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: ContactColors.gray, width: 1.5),
        ),
        child: Row(
          children: [
            _txt(page.mobileTitle, ContactColors.blue, 18, FontWeight.w900),
            const Spacer(),
            _txt(page.mobileBadge, ContactColors.red, 12, FontWeight.w800),
          ],
        ),
      );

  Widget _bottomNav(List<String> labels) => Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: ContactColors.gray, width: 1.5),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(labels.length, (index) {
            final isActive = labels[index].toLowerCase() == 'liên hệ';
            return _txt(
              labels[index],
              isActive ? ContactColors.blue : ContactColors.gray,
              10,
              isActive ? FontWeight.w800 : FontWeight.w500,
            );
          }),
        ),
      );

  List<Widget> _buildFormFields(List<ContactFormFieldModel> fields) {
    final controllers = [
      fullNameController,
      emailController,
      phoneController,
      messageController,
    ];
    final widgets = <Widget>[];
    for (var index = 0; index < fields.length; index++) {
      final field = fields[index];
      widgets.add(const SizedBox(height: 8));
      widgets.add(
        _field(
          field.placeholder,
          controller: index < controllers.length ? controllers[index] : null,
          h: field.multiline ? 90 : 36,
          multiline: field.multiline,
        ),
      );
    }
    return widgets;
  }

  List<Widget> _buildInfoCards(List<ContactInfoCardModel> infoCards) {
    final widgets = <Widget>[];
    for (final info in infoCards) {
      widgets.add(const SizedBox(height: 8));
      widgets.add(
        _box(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _txt(info.title, ContactColors.blue, 14, FontWeight.w800),
              const SizedBox(height: 6),
              if (info.isPreviewCard)
                Container(
                  width: double.infinity,
                  height: 66,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8F8F8),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: ContactColors.gray, width: 1.5),
                  ),
                  child: _txt(
                    info.previewLabel ?? '',
                    ContactColors.gray,
                    11,
                    FontWeight.w600,
                  ),
                )
              else
                ...info.lines.map(
                  (line) => _txt(line, Colors.black87, 11, FontWeight.w500),
                ),
            ],
          ),
        ),
      );
    }
    return widgets;
  }

  Widget _box({required Widget child}) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: ContactColors.gray, width: 1.5),
        ),
        child: child,
      );

  Widget _field(
    String hint, {
    TextEditingController? controller,
    double h = 36,
    bool multiline = false,
  }) => Container(
        width: double.infinity,
        height: h,
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: const Color(0xFFF8F8F8),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: ContactColors.gray, width: 1.5),
        ),
        child: TextField(
          controller: controller,
          maxLines: multiline ? null : 1,
          decoration: InputDecoration(
            hintText: hint,
            filled: false,
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
            disabledBorder: InputBorder.none,
            errorBorder: InputBorder.none,
            focusedErrorBorder: InputBorder.none,
            isCollapsed: true,
            contentPadding: EdgeInsets.zero,
            hintStyle: const TextStyle(
              color: ContactColors.gray,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
          style: const TextStyle(
            color: ContactColors.blue,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      );

  Widget _btn(String text) => Container(
        width: double.infinity,
        height: 30,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: ContactColors.red,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: ContactColors.gray, width: 1.5),
        ),
        child: _txt(text, Colors.white, 11, FontWeight.w800),
      );

  Widget _statusText(String message, {bool isSuccess = false}) => _txt(
        message,
        isSuccess ? const Color(0xFF2E7D32) : ContactColors.red,
        11,
        FontWeight.w700,
      );

  Widget _txt(String text, Color color, double size, FontWeight fw) => Text(
        text,
        style: TextStyle(color: color, fontSize: size, fontWeight: fw),
      );
}
