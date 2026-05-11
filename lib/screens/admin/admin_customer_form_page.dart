import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/models/admin_models.dart';
import '../../app/repositories/admin_repository.dart';
import '../../app/routing/app_router.dart';
import '../../app/services/app_services.dart';

class ResponsiveAdminCustomerFormScreen extends StatefulWidget {
  const ResponsiveAdminCustomerFormScreen({
    super.key,
    required this.customerId,
    this.showTopHeader = true,
    this.returnSidebarIndex = 3,
  });

  final String customerId;
  final bool showTopHeader;
  final int returnSidebarIndex;

  @override
  State<ResponsiveAdminCustomerFormScreen> createState() =>
      _ResponsiveAdminCustomerFormScreenState();
}

class _ResponsiveAdminCustomerFormScreenState
    extends State<ResponsiveAdminCustomerFormScreen> {
  final AdminRepository _repository = AppServices.instance.adminRepository;
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();

  bool _isLoading = false;
  bool _isSaving = false;
  String? _message;
  bool _isSuccess = false;

  @override
  void initState() {
    super.initState();
    _loadCustomer();
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _loadCustomer() async {
    setState(() {
      _isLoading = true;
      _message = null;
    });
    try {
      final customer = await _repository.fetchCustomer(widget.customerId);
      final draft = AdminCustomerDraft.fromCustomer(customer);
      _fullNameController.text = draft.fullName;
      _emailController.text = draft.email;
      _phoneController.text = draft.phone ?? '';
      _addressController.text = draft.address ?? '';
      setState(() {
        _isLoading = false;
      });
    } catch (_) {
      setState(() {
        _isLoading = false;
        _message = 'Không thể tải thông tin khách hàng.';
        _isSuccess = false;
      });
    }
  }

  AdminCustomerDraft? _buildDraft() {
    final fullName = _fullNameController.text.trim();
    final email = _emailController.text.trim();
    final phone = _phoneController.text.trim();
    final address = _addressController.text.trim();

    if (fullName.isEmpty || email.isEmpty) {
      setState(() {
        _message = 'Vui lòng nhập họ tên và email.';
        _isSuccess = false;
      });
      return null;
    }

    return AdminCustomerDraft(
      fullName: fullName,
      email: email,
      phone: phone.isEmpty ? null : phone,
      address: address.isEmpty ? null : address,
    );
  }

  Future<void> _submit() async {
    final draft = _buildDraft();
    if (draft == null || _isSaving) {
      return;
    }
    setState(() {
      _isSaving = true;
      _message = null;
    });
    try {
      await _repository.updateCustomer(widget.customerId, draft);
      if (!mounted) {
        return;
      }
      context.goNamed(
        AppRouteNames.admin,
        queryParameters: {'sidebar': '${widget.returnSidebarIndex}'},
      );
    } catch (_) {
      setState(() {
        _isSaving = false;
        _message = 'Không thể cập nhật khách hàng.';
        _isSuccess = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      color: const Color(0xFFF8F8F8),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _header(context),
            const SizedBox(height: 16),
            if (_message != null) ...[
              _banner(),
              const SizedBox(height: 12),
            ],
            if (_isLoading)
              const Padding(
                padding: EdgeInsets.all(24),
                child: Center(child: CircularProgressIndicator()),
              )
            else
              _formCard(),
          ],
        ),
      ),
    );
  }

  Widget _header(BuildContext context) => Row(
        children: [
          GestureDetector(
            onTap: () => context.goNamed(
              AppRouteNames.admin,
              queryParameters: {'sidebar': '${widget.returnSidebarIndex}'},
            ),
            child: Container(
              width: 40,
              height: 40,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFCFCFCF)),
              ),
              child: const Icon(Icons.arrow_back, size: 18),
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'Sửa thông tin khách hàng',
              style: TextStyle(
                color: Color(0xFF1E88E5),
                fontSize: 24,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: _isSaving ? null : _submit,
            child: Text(_isSaving ? 'Đang lưu...' : 'Lưu'),
          ),
        ],
      );

  Widget _formCard() => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFCFCFCF)),
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isCompact = constraints.maxWidth < 720;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (isCompact) ...[
                  _field('Họ tên', _fullNameController),
                  const SizedBox(height: 12),
                  _field('Email', _emailController),
                  const SizedBox(height: 12),
                  _field('Số điện thoại', _phoneController),
                  const SizedBox(height: 12),
                  _field('Địa chỉ', _addressController, maxLines: 3),
                ] else ...[
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: _field('Họ tên', _fullNameController)),
                      const SizedBox(width: 12),
                      Expanded(child: _field('Email', _emailController)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: _field('Số điện thoại', _phoneController)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _field(
                          'Địa chỉ',
                          _addressController,
                          maxLines: 3,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            );
          },
        ),
      );

  Widget _field(String label, TextEditingController controller, {int maxLines = 1}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFF6B7280),
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          maxLines: maxLines,
          decoration: InputDecoration(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            filled: true,
            fillColor: Colors.white,
          ),
        ),
      ],
    );
  }

  Widget _banner() => Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: _isSuccess ? const Color(0xFFEFF8F1) : const Color(0xFFFCEAEA),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: _isSuccess ? const Color(0xFF2E7D32) : const Color(0xFFE53935),
          ),
        ),
        child: Text(
          _message!,
          style: TextStyle(
            color: _isSuccess ? const Color(0xFF2E7D32) : const Color(0xFFE53935),
            fontWeight: FontWeight.w700,
          ),
        ),
      );
}
