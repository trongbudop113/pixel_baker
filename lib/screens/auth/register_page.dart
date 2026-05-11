import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../app/repositories/auth_page_repository.dart';
import '../../app/state/screen_controller.dart';
import '../../app/routing/app_router.dart';
import '../shared/app_header.dart';
import 'auth_state.dart';

class AuthColors {
  static const red = Color(0xFFE53935);
  static const blue = Color(0xFF1E88E5);
  static const green = Color(0xFF2E7D32);
  static const gray = Color(0xFF8A8A8A);
}

class ResponsiveRegisterScreen extends StatefulWidget {
  const ResponsiveRegisterScreen({super.key, this.showTopHeader = true});
  final bool showTopHeader;

  @override
  State<ResponsiveRegisterScreen> createState() =>
      _ResponsiveRegisterScreenState();
}

class _ResponsiveRegisterScreenState extends State<ResponsiveRegisterScreen> {
  late final AuthState _authState;
  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  String? _lastShownMessage;

  @override
  void initState() {
    super.initState();
    _authState = AuthState(pageType: AuthPageType.register);
    _authState.addListener(_handleStateChanged);
    _authState.load();
  }

  @override
  void dispose() {
    _authState.removeListener(_handleStateChanged);
    _fullNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _authState.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ControllerEffectListener<AuthState, AuthNavTarget>(
      controller: _authState,
      listener: _handleNavEffect,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isMobile = constraints.maxWidth < 900;
          return isMobile
              ? _RegisterMobileLayout(
            state: _authState,
            fullNameController: _fullNameController,
            emailController: _emailController,
            phoneController: _phoneController,
            passwordController: _passwordController,
            confirmPasswordController: _confirmPasswordController,
            showTopHeader: widget.showTopHeader,
          )
              : _RegisterWebLayout(
            state: _authState,
            fullNameController: _fullNameController,
            emailController: _emailController,
            phoneController: _phoneController,
            passwordController: _passwordController,
            confirmPasswordController: _confirmPasswordController,
            showTopHeader: widget.showTopHeader,
          );
        },
      ),
    );
  }

  void _handleNavEffect(BuildContext context, AuthNavTarget nav) {
    switch (nav) {
      case AuthNavTarget.login:
        context.pushNamed(AppRouteNames.login);
        break;
      case AuthNavTarget.register:
        context.pushNamed(AppRouteNames.register);
        break;
      case AuthNavTarget.home:
        context.goNamed(AppRouteNames.home);
        break;
    }
  }

  void _handleStateChanged() {
    if (!mounted) {
      return;
    }

    final nextMessage = _authState.submitMessage ?? _authState.errorMessage;
    if (nextMessage == null || nextMessage == _lastShownMessage) {
      return;
    }

    _lastShownMessage = nextMessage;
    final isSuccess = _authState.isSubmitSuccess;
    final color = isSuccess
        ? AuthColors.green
        : (_authState.isSubmitting ? AuthColors.blue : AuthColors.red);

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(nextMessage),
          backgroundColor: color,
          behavior: SnackBarBehavior.floating,
        ),
      );
  }
}

class _RegisterWebLayout extends StatelessWidget {
  final AuthState state;
  final TextEditingController fullNameController;
  final TextEditingController emailController;
  final TextEditingController phoneController;
  final TextEditingController passwordController;
  final TextEditingController confirmPasswordController;
  final bool showTopHeader;
  const _RegisterWebLayout({
    required this.state,
    required this.fullNameController,
    required this.emailController,
    required this.phoneController,
    required this.passwordController,
    required this.confirmPasswordController,
    this.showTopHeader = true,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: state,
      builder: (context, _) {
        final page = state.pageResponse;
        return Container(
          width: 1200,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: AuthColors.gray, width: 3),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (showTopHeader)
                const PixelHeaderBar(
                    rightLabel: 'đăng ký', showBack: true, showBrand: false),
              if (showTopHeader) const SizedBox(height: 16),
              if (state.submitMessage != null) ...[
                _messageBanner(
                  state.submitMessage!,
                  state.isSubmitSuccess
                      ? AuthColors.green
                      : (state.isSubmitting ? AuthColors.blue : AuthColors.red),
                ),
                const SizedBox(height: 8),
              ],
              Container(
                height: 72,
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                decoration: _boxDec(radius: 8, borderWidth: 2),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _title(page.headerBrand, AuthColors.red, 20,
                        fw: FontWeight.w900),
                    _title(page.headerTitle, AuthColors.blue, 15,
                        fw: FontWeight.w800),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: _boxDec(radius: 8, borderWidth: 2),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _title(page.introTitle, AuthColors.blue, 24),
                    const SizedBox(height: 4),
                    _hint(
                      page.introDescription,
                      AuthColors.gray,
                      size: 14,
                      fw: FontWeight.w500,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: _boxDec(radius: 8, borderWidth: 2),
                child: Column(
                  children: [
                    _field(page.fields[0].label,
                        controller: fullNameController,
                        height: 44,
                        borderWidth: 2,
                        radius: 6),
                    const SizedBox(height: 10),
                    _field(page.fields[1].label,
                        controller: emailController,
                        height: 44,
                        borderWidth: 2,
                        radius: 6),
                    const SizedBox(height: 10),
                    _field(page.fields[2].label,
                        controller: phoneController,
                        height: 44,
                        borderWidth: 2,
                        radius: 6),
                    const SizedBox(height: 10),
                    _field(page.fields[3].label,
                        controller: passwordController,
                        height: 44,
                        borderWidth: 2,
                        radius: 6),
                    const SizedBox(height: 10),
                    _field(page.fields[4].label,
                        controller: confirmPasswordController,
                        height: 44,
                        borderWidth: 2,
                        radius: 6),
                    const SizedBox(height: 10),
                    GestureDetector(
                      onTap: state.isSubmitting
                          ? null
                          : () => state.submitRegister(
                                fullName: fullNameController.text,
                                email: emailController.text,
                                phone: phoneController.text,
                                password: passwordController.text,
                                confirmPassword: confirmPasswordController.text,
                              ),
                      child: _cta(
                        state.isSubmitting
                            ? 'Đang tạo tài khoản...'
                            : page.primaryActionLabel,
                        AuthColors.red,
                        height: 48,
                        borderWidth: 2,
                        radius: 8,
                      ),
                    ),
                    const SizedBox(height: 10),
                    _cta(
                      page.socialActionLabel,
                      Colors.white,
                      textColor: AuthColors.blue,
                      height: 40,
                      borderWidth: 2,
                      radius: 6,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              GestureDetector(
                onTap: state.openLogin,
                child: Container(
                  height: 46,
                  alignment: Alignment.center,
                  decoration: _boxDec(radius: 8, borderWidth: 2),
                  child: _hint(
                    '${page.switchPrompt} ${page.switchActionLabel}',
                    AuthColors.blue,
                    size: 14,
                    fw: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Container(
                height: 52,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: const Color(0xFFF8F8F8),
                  border: Border.all(color: AuthColors.gray, width: 2),
                ),
                child: _hint(page.footerTagline, AuthColors.gray,
                    size: 10, fw: FontWeight.w700),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _RegisterMobileLayout extends StatelessWidget {
  final AuthState state;
  final TextEditingController fullNameController;
  final TextEditingController emailController;
  final TextEditingController phoneController;
  final TextEditingController passwordController;
  final TextEditingController confirmPasswordController;
  final bool showTopHeader;
  const _RegisterMobileLayout({
    required this.state,
    required this.fullNameController,
    required this.emailController,
    required this.phoneController,
    required this.passwordController,
    required this.confirmPasswordController,
    this.showTopHeader = true,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: state,
      builder: (context, _) {
        final page = state.pageResponse;
        return Container(
          constraints: const BoxConstraints(maxWidth: 390),
          width: double.infinity,
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: const Color(0xFFF8F8F8),
            border: Border.all(color: AuthColors.gray, width: 3),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (showTopHeader)
                const PixelHeaderBar(
                    rightLabel: 'đăng ký', showBack: true, showBrand: false),
              if (showTopHeader) const SizedBox(height: 8),
              if (state.submitMessage != null) ...[
                _messageBanner(
                  state.submitMessage!,
                  state.isSubmitSuccess
                      ? AuthColors.green
                      : (state.isSubmitting ? AuthColors.blue : AuthColors.red),
                ),
                const SizedBox(height: 8),
              ],
              Container(
                height: 54,
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: _boxDec(radius: 8, borderWidth: 2),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _title(page.headerBrand, AuthColors.red, 14,
                        fw: FontWeight.w900),
                    _title(page.headerTitle, AuthColors.blue, 12,
                        fw: FontWeight.w800),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: _boxDec(radius: 8, borderWidth: 2),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _title(page.introTitle, AuthColors.blue, 20,
                        fw: FontWeight.w800),
                    const SizedBox(height: 4),
                    _hint(
                      page.introDescription,
                      AuthColors.gray,
                      size: 12,
                      fw: FontWeight.w500,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: _boxDec(radius: 8, borderWidth: 2),
                child: Column(
                  children: [
                    _field(page.fields[0].label,
                        controller: fullNameController,
                        height: 40,
                        borderWidth: 2,
                        radius: 6),
                    const SizedBox(height: 8),
                    _field(page.fields[1].label,
                        controller: emailController,
                        height: 40,
                        borderWidth: 2,
                        radius: 6),
                    const SizedBox(height: 8),
                    _field(page.fields[2].label,
                        controller: phoneController,
                        height: 40,
                        borderWidth: 2,
                        radius: 6),
                    const SizedBox(height: 8),
                    _field(page.fields[3].label,
                        controller: passwordController,
                        height: 40,
                        borderWidth: 2,
                        radius: 6),
                    const SizedBox(height: 8),
                    _field(page.fields[4].label,
                        controller: confirmPasswordController,
                        height: 40,
                        borderWidth: 2,
                        radius: 6),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: state.isSubmitting
                    ? null
                    : () => state.submitRegister(
                          fullName: fullNameController.text,
                          email: emailController.text,
                          phone: phoneController.text,
                          password: passwordController.text,
                          confirmPassword: confirmPasswordController.text,
                        ),
                child: _cta(
                  state.isSubmitting
                      ? 'Đang tạo tài khoản...'
                      : page.primaryActionLabel,
                  AuthColors.red,
                  height: 46,
                  borderWidth: 2,
                  radius: 8,
                ),
              ),
              const SizedBox(height: 8),
              _hint('hoặc', AuthColors.gray, size: 11, fw: FontWeight.w600),
              const SizedBox(height: 8),
              _cta(
                page.socialActionLabel,
                Colors.white,
                textColor: AuthColors.blue,
                height: 44,
                borderWidth: 2,
                radius: 8,
              ),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: state.openLogin,
                child: Container(
                  height: 40,
                  decoration: _boxDec(radius: 8, borderWidth: 2),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _hint(page.switchPrompt, AuthColors.blue,
                          size: 11, fw: FontWeight.w700),
                      const SizedBox(width: 5),
                      _hint(page.switchActionLabel, AuthColors.blue,
                          size: 11, fw: FontWeight.w900),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 10),
              _hint(page.footerTagline, AuthColors.gray,
                  size: 8, fw: FontWeight.w700),
            ],
          ),
        );
      },
    );
  }
}

Widget _field(
    String text, {
      TextEditingController? controller,
      double height = 44,
      double borderWidth = 2,
      double radius = 8,
    }) =>
    Container(
      height: height,
      width: double.infinity,
      alignment: Alignment.centerLeft,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: AuthColors.gray, width: borderWidth),
      ),
      child: TextField(
        controller: controller,
        obscureText: text.toLowerCase().contains('mật khẩu'),
        style: const TextStyle(
          color: Color(0xFF111827),
          fontSize: 13,
          fontWeight: FontWeight.w700,
        ),
        decoration: InputDecoration(
          hintText: text,
          filled: false,
          hintStyle: const TextStyle(
            color: Color(0xFF6B7280),
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          disabledBorder: InputBorder.none,
          errorBorder: InputBorder.none,
          focusedErrorBorder: InputBorder.none,
          isCollapsed: true,
          contentPadding: EdgeInsets.zero,
        ),
      ),
    );

Widget _cta(
    String label,
    Color color, {
      Color textColor = Colors.white,
      double height = 38,
      double borderWidth = 2,
      double radius = 8,
    }) =>
    Container(
      width: double.infinity,
      height: height,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: AuthColors.gray, width: borderWidth),
      ),
      child: Text(
        label,
        style: TextStyle(
            color: textColor, fontWeight: FontWeight.w800, fontSize: 13),
      ),
    );

Widget _title(
    String text,
    Color color,
    double size, {
      FontWeight fw = FontWeight.w800,
    }) =>
    Text(
      text,
      style: TextStyle(color: color, fontSize: size, fontWeight: fw),
    );

Widget _hint(
    String text,
    Color color, {
      double size = 12,
      FontWeight fw = FontWeight.w600,
    }) =>
    Text(
      text,
      style: TextStyle(color: color, fontSize: size, fontWeight: fw),
    );

Widget _messageBanner(String message, Color color) => Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color, width: 2),
      ),
      child: Text(
        message,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w700,
          height: 1.35,
        ),
      ),
    );

BoxDecoration _boxDec({double radius = 10, double borderWidth = 2}) =>
    BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: AuthColors.gray, width: borderWidth),
    );
