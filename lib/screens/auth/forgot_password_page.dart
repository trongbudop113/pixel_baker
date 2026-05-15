import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/routing/app_router.dart';
import '../../app/services/app_services.dart';
import '../shared/app_header.dart';

class ResponsiveForgotPasswordScreen extends StatefulWidget {
  const ResponsiveForgotPasswordScreen({super.key, this.showTopHeader = true});

  final bool showTopHeader;

  @override
  State<ResponsiveForgotPasswordScreen> createState() =>
      _ResponsiveForgotPasswordScreenState();
}

class _ResponsiveForgotPasswordScreenState
    extends State<ResponsiveForgotPasswordScreen> {
  final TextEditingController _emailController = TextEditingController();
  bool _isSubmitting = false;
  String? _message;
  bool _isSuccess = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 900;
    return Align(
      alignment: Alignment.topCenter,
      child: Container(
        width: isMobile ? 390 : 760,
        padding: EdgeInsets.all(isMobile ? 12 : 24),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          border: Border.all(color: const Color(0xFF8A8A8A), width: 3),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (widget.showTopHeader)
              const PixelHeaderBar(
                rightLabel: 'quên mật khẩu',
                showBack: true,
                showBrand: false,
              ),
            if (widget.showTopHeader) SizedBox(height: isMobile ? 8 : 16),
            _SectionCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Khôi phục mật khẩu',
                    style: TextStyle(
                      color: const Color(0xFF1E88E5),
                      fontSize: isMobile ? 22 : 28,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Nhập email đã đăng ký. Nếu tài khoản tồn tại, hệ thống sẽ gửi hướng dẫn đặt lại mật khẩu.',
                    style: TextStyle(
                      color: Color(0xFF6B7280),
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: isMobile ? 10 : 16),
            if (_message != null) ...[
              _StatusBanner(message: _message!, isSuccess: _isSuccess),
              SizedBox(height: isMobile ? 10 : 12),
            ],
            _SectionCard(
              child: Column(
                children: [
                  _AuthInput(
                    controller: _emailController,
                    hintText: 'Email',
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 12),
                  _PrimaryButton(
                    label: _isSubmitting ? 'Đang xử lý...' : 'Gửi yêu cầu',
                    onTap: _isSubmitting ? null : _submit,
                  ),
                ],
              ),
            ),
            SizedBox(height: isMobile ? 10 : 16),
            TextButton(
              onPressed: () => context.goNamed(AppRouteNames.login),
              child: const Text(
                'Quay lại đăng nhập',
                style: TextStyle(
                  color: Color(0xFF1E88E5),
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submit() async {
    final email = _emailController.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      _setMessage('Vui lòng nhập email hợp lệ.', isSuccess: false);
      return;
    }
    setState(() {
      _isSubmitting = true;
      _message = null;
    });
    try {
      final result =
          await AppServices.instance.authRepository.requestPasswordReset(email);
      if (!mounted) {
        return;
      }
      _setMessage(result.message, isSuccess: true);
      if (result.debugToken != null && result.debugToken!.isNotEmpty) {
        context.goNamed(
          AppRouteNames.resetPassword,
          queryParameters: {'token': result.debugToken!},
        );
      }
    } catch (error) {
      if (!mounted) {
        return;
      }
      _setMessage(error.toString(), isSuccess: false);
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  void _setMessage(String message, {required bool isSuccess}) {
    setState(() {
      _message = message;
      _isSuccess = isSuccess;
    });
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor:
              isSuccess ? const Color(0xFF2E7D32) : const Color(0xFFE53935),
          behavior: SnackBarBehavior.floating,
        ),
      );
  }
}

class ResponsiveResetPasswordScreen extends StatefulWidget {
  const ResponsiveResetPasswordScreen({
    super.key,
    this.showTopHeader = true,
    this.initialToken,
  });

  final bool showTopHeader;
  final String? initialToken;

  @override
  State<ResponsiveResetPasswordScreen> createState() =>
      _ResponsiveResetPasswordScreenState();
}

class _ResponsiveResetPasswordScreenState
    extends State<ResponsiveResetPasswordScreen> {
  late final TextEditingController _tokenController =
      TextEditingController(text: widget.initialToken ?? '');
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  bool _isSubmitting = false;
  String? _message;
  bool _isSuccess = false;

  @override
  void dispose() {
    _tokenController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 900;
    return Align(
      alignment: Alignment.topCenter,
      child: Container(
        width: isMobile ? 390 : 760,
        padding: EdgeInsets.all(isMobile ? 12 : 24),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          border: Border.all(color: const Color(0xFF8A8A8A), width: 3),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (widget.showTopHeader)
              const PixelHeaderBar(
                rightLabel: 'đặt lại mật khẩu',
                showBack: true,
                showBrand: false,
              ),
            if (widget.showTopHeader) SizedBox(height: isMobile ? 8 : 16),
            _SectionCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Đặt lại mật khẩu',
                    style: TextStyle(
                      color: const Color(0xFF1E88E5),
                      fontSize: isMobile ? 22 : 28,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Nhập token khôi phục và mật khẩu mới. Token debug sẽ tự điền khi app chạy ở môi trường dev.',
                    style: TextStyle(
                      color: Color(0xFF6B7280),
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: isMobile ? 10 : 16),
            if (_message != null) ...[
              _StatusBanner(message: _message!, isSuccess: _isSuccess),
              SizedBox(height: isMobile ? 10 : 12),
            ],
            _SectionCard(
              child: Column(
                children: [
                  _AuthInput(
                    controller: _tokenController,
                    hintText: 'Token khôi phục',
                  ),
                  const SizedBox(height: 12),
                  _AuthInput(
                    controller: _passwordController,
                    hintText: 'Mật khẩu mới',
                    obscureText: true,
                  ),
                  const SizedBox(height: 12),
                  _AuthInput(
                    controller: _confirmPasswordController,
                    hintText: 'Nhập lại mật khẩu mới',
                    obscureText: true,
                  ),
                  const SizedBox(height: 12),
                  _PrimaryButton(
                    label: _isSubmitting
                        ? 'Đang cập nhật...'
                        : 'Đặt lại mật khẩu',
                    onTap: _isSubmitting ? null : _submit,
                  ),
                ],
              ),
            ),
            SizedBox(height: isMobile ? 10 : 16),
            TextButton(
              onPressed: () => context.goNamed(AppRouteNames.login),
              child: const Text(
                'Quay lại đăng nhập',
                style: TextStyle(
                  color: Color(0xFF1E88E5),
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submit() async {
    final token = _tokenController.text.trim();
    final newPassword = _passwordController.text;
    final confirmPassword = _confirmPasswordController.text;
    if (token.length < 16) {
      _setMessage('Token khôi phục không hợp lệ.', isSuccess: false);
      return;
    }
    if (newPassword.length < 6) {
      _setMessage('Mật khẩu mới phải có ít nhất 6 ký tự.', isSuccess: false);
      return;
    }
    if (newPassword != confirmPassword) {
      _setMessage('Mật khẩu nhập lại không khớp.', isSuccess: false);
      return;
    }
    setState(() {
      _isSubmitting = true;
      _message = null;
    });
    try {
      final message = await AppServices.instance.authRepository.resetPassword(
        token: token,
        newPassword: newPassword,
      );
      if (!mounted) {
        return;
      }
      _setMessage(message, isSuccess: true);
      context.goNamed(AppRouteNames.login);
    } catch (error) {
      if (!mounted) {
        return;
      }
      _setMessage(error.toString(), isSuccess: false);
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  void _setMessage(String message, {required bool isSuccess}) {
    setState(() {
      _message = message;
      _isSuccess = isSuccess;
    });
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor:
              isSuccess ? const Color(0xFF2E7D32) : const Color(0xFFE53935),
          behavior: SnackBarBehavior.floating,
        ),
      );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF8A8A8A), width: 2),
      ),
      child: child,
    );
  }
}

class _AuthInput extends StatelessWidget {
  const _AuthInput({
    required this.controller,
    required this.hintText,
    this.obscureText = false,
    this.keyboardType,
  });

  final TextEditingController controller;
  final String hintText;
  final bool obscureText;
  final TextInputType? keyboardType;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 46,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF8A8A8A), width: 2),
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        obscureText: obscureText,
        style: const TextStyle(
          color: Color(0xFF111827),
          fontSize: 13,
          fontWeight: FontWeight.w700,
        ),
        decoration: const InputDecoration(
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          disabledBorder: InputBorder.none,
          errorBorder: InputBorder.none,
          focusedErrorBorder: InputBorder.none,
          filled: false,
          isCollapsed: true,
          contentPadding: EdgeInsets.zero,
        ).copyWith(
          hintText: hintText,
          hintStyle: const TextStyle(
            color: Color(0xFF6B7280),
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  const _PrimaryButton({
    required this.label,
    required this.onTap,
  });

  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 48,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: onTap == null ? const Color(0xFFE5E7EB) : const Color(0xFFE53935),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFF8A8A8A), width: 2),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: onTap == null ? const Color(0xFF6B7280) : Colors.white,
            fontWeight: FontWeight.w800,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}

class _StatusBanner extends StatelessWidget {
  const _StatusBanner({
    required this.message,
    required this.isSuccess,
  });

  final String message;
  final bool isSuccess;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: (isSuccess ? const Color(0xFF2E7D32) : const Color(0xFFE53935))
            .withOpacity(0.10),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isSuccess ? const Color(0xFF2E7D32) : const Color(0xFFE53935),
        ),
      ),
      child: Text(
        message,
        style: TextStyle(
          color: isSuccess ? const Color(0xFF2E7D32) : const Color(0xFFE53935),
          fontWeight: FontWeight.w700,
          fontSize: 12,
        ),
      ),
    );
  }
}
