import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/models/checkout_models.dart';
import '../../app/routing/app_router.dart';
import '../../app/services/app_services.dart';
import '../../app/state/screen_controller.dart';
import '../shared/app_header.dart';
import 'profile_state.dart';
import '../../theme/app_theme.dart';

class ProfileColors {
  static const blue = Color(0xFF1A73E8);
  static const red = Color(0xFFE53935);
  static const green = Color(0xFF1EA55B);
  static const orange = Color(0xFFF28C28);
  static const border = Color(0xFFD2D2D2);
  static const bg = Color(0xFFF6F6F6);
  static const text = Color(0xFF333333);
  static const muted = Color(0xFF7A7A7A);
}

class ResponsiveProfileScreen extends StatefulWidget {
  const ResponsiveProfileScreen({super.key, this.showTopHeader = true});
  final bool showTopHeader;

  @override
  State<ResponsiveProfileScreen> createState() =>
      _ResponsiveProfileScreenState();
}

class _ResponsiveProfileScreenState extends State<ResponsiveProfileScreen> {
  final ProfileState _profileState = ProfileState();

  @override
  void initState() {
    super.initState();
    _profileState.load();
  }

  @override
  void dispose() {
    _profileState.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ControllerEffectListener<ProfileState, ProfileEffect>(
      controller: _profileState,
      listener: (context, effect) {
        if (effect == ProfileEffect.login) {
          context.goNamed(AppRouteNames.login);
        }
      },
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isMobile = constraints.maxWidth < 900;
          return SafeArea(
            child: isMobile
                ? MobileProfileLayout(
                    state: _profileState, showTopHeader: widget.showTopHeader)
                : WebProfileLayout(
                    state: _profileState, showTopHeader: widget.showTopHeader),
          );
        },
      ),
    );
  }
}

class WebProfileLayout extends StatelessWidget {
  final ProfileState state;
  final bool showTopHeader;
  const WebProfileLayout(
      {super.key, required this.state, this.showTopHeader = true});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 1200,
      height: double.infinity,
      child: Container(
        padding: const EdgeInsets.all(24),
        color: ProfileColors.bg,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (showTopHeader)
              const PixelHeaderBar(
                  rightLabel: 'hồ sơ', showBack: true, showBrand: false),
            if (showTopHeader) const SizedBox(height: 12),
            Expanded(
              child: SingleChildScrollView(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 34,
                      child: Column(
                        children: [
                          _WebPersonalCard(state: state),
                          const SizedBox(height: 12),
                          _WebAddressCard(state: state),
                          const SizedBox(height: 12),
                          _WebSecurityCard(state: state),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 66,
                      child: Column(
                        children: [
                          _WebOrdersCard(state: state),
                          const SizedBox(height: 12),
                          const _WishlistEntryCard(),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WebPersonalCard extends StatelessWidget {
  const _WebPersonalCard({required this.state});

  final ProfileState state;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: state,
      builder: (context, _) {
        final user = state.user;
        return _section(
          title: 'Thông tin cá nhân',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Họ tên: ${user?.fullName ?? 'Chưa đăng nhập'}',
                  style: _lineStyle),
              const SizedBox(height: 6),
              Text('Email: ${user?.email ?? '-'}', style: _lineStyle),
              const SizedBox(height: 6),
              Text('SĐT: ${user?.phone ?? '-'}', style: _lineStyle),
              if (state.errorMessage != null) ...[
                const SizedBox(height: 8),
                Text(
                  state.errorMessage!,
                  style: const TextStyle(
                    color: ProfileColors.red,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
              const SizedBox(height: 10),
              GestureDetector(
                onTap: state.logout,
                child: SizedBox(
                  width: double.infinity,
                  height: 28,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: ProfileColors.red,
                      borderRadius: BorderRadius.circular(5),
                    ),
                    child: const Center(
                      child: Text(
                        'Đăng xuất',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _WebAddressCard extends StatefulWidget {
  const _WebAddressCard({required this.state});

  final ProfileState state;

  @override
  State<_WebAddressCard> createState() => _WebAddressCardState();
}

class _WebAddressCardState extends State<_WebAddressCard> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
      text: widget.state.user?.address ?? '',
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.state,
      builder: (context, _) {
        final user = widget.state.user;
        final address = user?.address?.trim() ?? '';
        if (_controller.text.trim().isEmpty && address.isNotEmpty) {
          _controller.text = address;
        }
        final hasAddress = address.isNotEmpty;
        return _section(
          title: 'Địa chỉ mặc định',
          minHeight: 120,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (hasAddress)
                Text(address, style: _lineStyle)
              else
                const Text(
                  'Bạn chưa có địa chỉ mặc định.',
                  style: TextStyle(
                    fontSize: 10,
                    height: 1.2,
                    color: ProfileColors.muted,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              const SizedBox(height: 8),
              _ProfileTextField(
                controller: _controller,
                hintText: 'Nhập địa chỉ giao hàng',
                maxLines: 2,
              ),
              const SizedBox(height: 8),
              _ActionButton(
                label: hasAddress ? 'Cập nhật địa chỉ' : 'Thêm địa chỉ',
                color: ProfileColors.blue,
                isLoading: widget.state.isUpdatingAddress,
                onTap: () => widget.state.updateAddress(_controller.text),
              ),
              if (widget.state.addressMessage != null) ...[
                const SizedBox(height: 8),
                _StatusMessage(
                  message: widget.state.addressMessage!,
                  isSuccess: widget.state.isAddressSuccess,
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _WebSecurityCard extends StatefulWidget {
  const _WebSecurityCard({required this.state});

  final ProfileState state;

  @override
  State<_WebSecurityCard> createState() => _WebSecurityCardState();
}

class _WebSecurityCardState extends State<_WebSecurityCard> {
  final TextEditingController _currentPasswordController =
      TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.state,
      builder: (context, _) => _section(
        title: 'Bảo mật',
        child: Column(
          children: [
            _ProfileTextField(
              controller: _currentPasswordController,
              hintText: 'Mật khẩu hiện tại',
              obscureText: true,
            ),
            const SizedBox(height: 6),
            _ProfileTextField(
              controller: _newPasswordController,
              hintText: 'Mật khẩu mới',
              obscureText: true,
            ),
            const SizedBox(height: 6),
            _ProfileTextField(
              controller: _confirmPasswordController,
              hintText: 'Nhập lại mật khẩu mới',
              obscureText: true,
            ),
            const SizedBox(height: 8),
            _ActionButton(
              label: 'Cập nhật mật khẩu',
              color: ProfileColors.green,
              isLoading: widget.state.isUpdatingPassword,
              onTap: () async {
                await widget.state.changePassword(
                  currentPassword: _currentPasswordController.text,
                  newPassword: _newPasswordController.text,
                  confirmPassword: _confirmPasswordController.text,
                );
                if (widget.state.isPasswordSuccess) {
                  _currentPasswordController.clear();
                  _newPasswordController.clear();
                  _confirmPasswordController.clear();
                }
              },
            ),
            if (widget.state.passwordMessage != null) ...[
              const SizedBox(height: 8),
              _StatusMessage(
                message: widget.state.passwordMessage!,
                isSuccess: widget.state.isPasswordSuccess,
              ),
            ],
            const SizedBox(height: 10),
            ValueListenableBuilder<ThemeMode>(
              valueListenable: AppThemeController.instance.themeMode,
              builder: (context, mode, _) => Container(
                height: 28,
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                decoration: _box(),
                child: Row(
                  children: [
                    const Text('Dark mode',
                        style:
                            TextStyle(fontSize: 10, color: ProfileColors.text)),
                    const Spacer(),
                    Switch(
                      value: mode == ThemeMode.dark,
                      onChanged: AppThemeController.instance.setDarkMode,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WebOrdersCard extends StatelessWidget {
  const _WebOrdersCard({required this.state});

  final ProfileState state;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: state,
      builder: (context, _) => _section(
        title: 'Lịch sử đơn hàng',
        minHeight: 190,
        child: _OrdersList(
          orders: state.orders,
          emptyLabel: 'Bạn chưa có đơn hàng nào.',
        ),
      ),
    );
  }
}

class _WishlistEntryCard extends StatelessWidget {
  const _WishlistEntryCard();

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: AppServices.instance.wishlistSession,
      builder: (context, _) {
        final count = AppServices.instance.wishlistSession.itemCount;
        final helperText = count == 0
            ? 'Bạn chưa lưu sản phẩm nào. Hãy thêm món bạn thích để quay lại nhanh hơn.'
            : 'Bạn đang lưu $count sản phẩm trong danh sách yêu thích.';
        return _section(
          title: 'Sản phẩm yêu thích',
          minHeight: 110,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF1F1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: ProfileColors.border, width: 1),
                    ),
                    child: const Icon(
                      Icons.favorite,
                      size: 18,
                      color: ProfileColors.red,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(child: Text(helperText, style: _lineStyle)),
                ],
              ),
              const SizedBox(height: 10),
              _ActionButton(
                label: count == 0
                    ? 'Mở danh sách yêu thích'
                    : 'Xem wishlist của tôi',
                color: ProfileColors.orange,
                onTap: () => context.goNamed(AppRouteNames.wishlist),
              ),
            ],
          ),
        );
      },
    );
  }
}

class MobileProfileLayout extends StatelessWidget {
  final ProfileState state;
  final bool showTopHeader;
  const MobileProfileLayout(
      {super.key, required this.state, this.showTopHeader = true});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 390,
      height: double.infinity,
      child: Container(
        color: ProfileColors.bg,
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (showTopHeader)
              const PixelHeaderBar(
                  rightLabel: 'hồ sơ', showBack: true, showBrand: false),
            if (showTopHeader) const SizedBox(height: 6),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _mobilePersonal(),
                    const SizedBox(height: 6),
                    _mobileAddress(context),
                    const SizedBox(height: 6),
                    _mobileOrders(),
                    const SizedBox(height: 6),
                    const _WishlistEntryCard(),
                    const SizedBox(height: 6),
                    _mobileSecurity(context),
                    const SizedBox(height: 6),
                    _mobileBottomTabs(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _mobilePersonal() {
    return AnimatedBuilder(
      animation: state,
      builder: (context, _) {
        final user = state.user;
        return _section(
          title: 'Thông tin cá nhân',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(user?.fullName ?? 'Chưa đăng nhập', style: _lineStyle),
              const SizedBox(height: 4),
              Text(user?.email ?? '-', style: _lineStyle),
              const SizedBox(height: 4),
              Text(user?.phone ?? '-', style: _lineStyle),
              if (state.errorMessage != null) ...[
                const SizedBox(height: 6),
                Text(
                  state.errorMessage!,
                  style: const TextStyle(
                    color: ProfileColors.red,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
              const SizedBox(height: 8),
              GestureDetector(
                onTap: state.logout,
                child: Container(
                  width: double.infinity,
                  height: 30,
                  decoration: BoxDecoration(
                    color: ProfileColors.red,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Center(
                    child: Text(
                      'Đăng xuất',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _mobileAddress(BuildContext context) {
    return _MobileAddressCard(state: state);
  }

  Widget _mobileOrders() {
    return AnimatedBuilder(
      animation: state,
      builder: (context, _) => _section(
        title: 'Đơn gần đây',
        minHeight: 140,
        child: _OrdersList(
          orders: state.orders,
          emptyLabel: 'Chưa có đơn hàng gần đây.',
          compact: true,
        ),
      ),
    );
  }

  Widget _mobileSecurity(BuildContext context) {
    return _MobileSecurityCard(state: state);
  }

  Widget _mobileBottomTabs() {
    const tabs = ['Hồ sơ', 'Đơn', 'Voucher', 'Cài đặt'];
    return AnimatedBuilder(
      animation: state,
      builder: (context, _) => Container(
        height: 30,
        decoration: _box(),
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(tabs.length, (index) {
            final active = state.selectedTabIndex == index;
            return GestureDetector(
              onTap: () => state.selectTab(index),
              child: Text(
                tabs[index],
                style: TextStyle(
                    color: active ? ProfileColors.blue : ProfileColors.muted,
                    fontSize: 10),
              ),
            );
          }),
        ),
      ),
    );
  }
}

class _OrderItem extends StatelessWidget {
  final String code;
  final String value;
  final Color color;
  final VoidCallback? onTap;

  const _OrderItem({
    required this.code,
    required this.value,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        height: 24,
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        decoration: _box(),
        child: Row(
          children: [
            Text(code,
                style:
                    const TextStyle(fontSize: 10, color: ProfileColors.text)),
            const Spacer(),
            Text(
              value,
              style: TextStyle(
                  fontSize: 10, color: color, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}

class _OrdersList extends StatelessWidget {
  const _OrdersList({
    required this.orders,
    required this.emptyLabel,
    this.compact = false,
  });

  final List<OrderSummaryModel> orders;
  final String emptyLabel;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    if (orders.isEmpty) {
      return Text(
        emptyLabel,
        style: const TextStyle(
          fontSize: 10,
          height: 1.3,
          color: ProfileColors.muted,
          fontWeight: FontWeight.w600,
        ),
      );
    }

    final visibleOrders = orders.take(compact ? 3 : 5).toList(growable: false);
    return Column(
      children: [
        for (var index = 0; index < visibleOrders.length; index++) ...[
          _OrderItem(
            code: '#${visibleOrders[index].orderId}',
            value:
                '${_orderStatusLabel(visibleOrders[index].status)} ${_formatCurrency(visibleOrders[index].total)}',
            color: _orderStatusColor(visibleOrders[index].status),
            onTap: () => context.goNamed(
              AppRouteNames.ordersDetail,
              queryParameters: {
                'id': visibleOrders[index].orderId,
              },
            ),
          ),
          if (index != visibleOrders.length - 1) const SizedBox(height: 6),
        ],
      ],
    );
  }
}

class _MobileAddressCard extends StatefulWidget {
  const _MobileAddressCard({required this.state});

  final ProfileState state;

  @override
  State<_MobileAddressCard> createState() => _MobileAddressCardState();
}

class _MobileAddressCardState extends State<_MobileAddressCard> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
      text: widget.state.user?.address ?? '',
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.state,
      builder: (context, _) {
        final address = widget.state.user?.address?.trim() ?? '';
        if (_controller.text.trim().isEmpty && address.isNotEmpty) {
          _controller.text = address;
        }
        final hasAddress = address.isNotEmpty;
        return _section(
          title: 'Địa chỉ',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                hasAddress ? address : 'Bạn chưa có địa chỉ mặc định.',
                style: TextStyle(
                  fontSize: 10,
                  height: 1.2,
                  color: hasAddress ? ProfileColors.text : ProfileColors.muted,
                  fontWeight: hasAddress ? FontWeight.w400 : FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              _ProfileTextField(
                controller: _controller,
                hintText: 'Nhập địa chỉ giao hàng',
                maxLines: 2,
                height: 56,
              ),
              const SizedBox(height: 8),
              _ActionButton(
                label: hasAddress ? 'Cập nhật địa chỉ' : 'Thêm địa chỉ',
                color: ProfileColors.blue,
                isLoading: widget.state.isUpdatingAddress,
                onTap: () => widget.state.updateAddress(_controller.text),
              ),
              if (widget.state.addressMessage != null) ...[
                const SizedBox(height: 8),
                _StatusMessage(
                  message: widget.state.addressMessage!,
                  isSuccess: widget.state.isAddressSuccess,
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _MobileSecurityCard extends StatefulWidget {
  const _MobileSecurityCard({required this.state});

  final ProfileState state;

  @override
  State<_MobileSecurityCard> createState() => _MobileSecurityCardState();
}

class _MobileSecurityCardState extends State<_MobileSecurityCard> {
  final TextEditingController _currentPasswordController =
      TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.state,
      builder: (context, _) => _section(
        title: 'Bảo mật',
        child: Column(
          children: [
            _ProfileTextField(
              controller: _currentPasswordController,
              hintText: 'Mật khẩu hiện tại',
              obscureText: true,
            ),
            const SizedBox(height: 6),
            _ProfileTextField(
              controller: _newPasswordController,
              hintText: 'Mật khẩu mới',
              obscureText: true,
            ),
            const SizedBox(height: 6),
            _ProfileTextField(
              controller: _confirmPasswordController,
              hintText: 'Nhập lại mật khẩu mới',
              obscureText: true,
            ),
            const SizedBox(height: 8),
            _ActionButton(
              label: 'Cập nhật mật khẩu',
              color: ProfileColors.green,
              isLoading: widget.state.isUpdatingPassword,
              onTap: () async {
                await widget.state.changePassword(
                  currentPassword: _currentPasswordController.text,
                  newPassword: _newPasswordController.text,
                  confirmPassword: _confirmPasswordController.text,
                );
                if (widget.state.isPasswordSuccess) {
                  _currentPasswordController.clear();
                  _newPasswordController.clear();
                  _confirmPasswordController.clear();
                }
              },
            ),
            if (widget.state.passwordMessage != null) ...[
              const SizedBox(height: 8),
              _StatusMessage(
                message: widget.state.passwordMessage!,
                isSuccess: widget.state.isPasswordSuccess,
              ),
            ],
            const SizedBox(height: 6),
            ValueListenableBuilder<ThemeMode>(
              valueListenable: AppThemeController.instance.themeMode,
              builder: (context, mode, _) => Container(
                height: 24,
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                alignment: Alignment.centerLeft,
                decoration: _box(),
                child: Row(
                  children: [
                    const Text('Dark mode',
                        style: TextStyle(
                            fontSize: 10, color: ProfileColors.muted)),
                    const Spacer(),
                    Transform.scale(
                      scale: 0.8,
                      child: Switch(
                        value: mode == ThemeMode.dark,
                        onChanged: AppThemeController.instance.setDarkMode,
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileTextField extends StatelessWidget {
  const _ProfileTextField({
    required this.controller,
    required this.hintText,
    this.obscureText = false,
    this.maxLines = 1,
    this.height = 36,
  });

  final TextEditingController controller;
  final String hintText;
  final bool obscureText;
  final int maxLines;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(minHeight: height),
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: _box(),
      child: TextField(
        controller: controller,
        obscureText: obscureText,
        maxLines: obscureText ? 1 : maxLines,
        minLines: obscureText ? 1 : maxLines,
        style: TextStyle(
          fontSize: 11,
          color: Theme.of(context).colorScheme.onSurface,
          fontWeight: FontWeight.w600,
        ),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: TextStyle(
            fontSize: 10,
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.62),
            fontWeight: FontWeight.w600,
          ),
          border: InputBorder.none,
          isCollapsed: true,
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.label,
    required this.color,
    required this.onTap,
    this.isLoading = false,
  });

  final String label;
  final Color color;
  final VoidCallback onTap;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isLoading ? null : onTap,
      child: Container(
        width: double.infinity,
        height: 30,
        decoration: BoxDecoration(
          color: isLoading ? color.withOpacity(0.6) : color,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Center(
          child: Text(
            isLoading ? 'Đang xử lý...' : label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}

class _StatusMessage extends StatelessWidget {
  const _StatusMessage({
    required this.message,
    required this.isSuccess,
  });

  final String message;
  final bool isSuccess;

  @override
  Widget build(BuildContext context) {
    return Text(
      message,
      style: TextStyle(
        color: isSuccess ? ProfileColors.green : ProfileColors.red,
        fontSize: 10,
        fontWeight: FontWeight.w700,
        height: 1.3,
      ),
    );
  }
}

Widget _section({
  required String title,
  required Widget child,
  double? minHeight,
}) {
  return Container(
    width: double.infinity,
    constraints:
        minHeight != null ? BoxConstraints(minHeight: minHeight) : null,
    decoration: _box(),
    padding: const EdgeInsets.all(8),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: ProfileColors.blue,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        child,
      ],
    ),
  );
}

BoxDecoration _box() {
  return BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(6),
    border: Border.all(color: ProfileColors.border, width: 1),
  );
}

Color _orderStatusColor(String status) {
  switch (status.trim().toLowerCase()) {
    case 'paid':
    case 'completed':
    case 'delivered':
      return ProfileColors.green;
    case 'shipping':
    case 'pending':
    case 'processing':
      return ProfileColors.orange;
    case 'cancelled':
    case 'failed':
      return ProfileColors.red;
    default:
      return ProfileColors.blue;
  }
}

String _orderStatusLabel(String status) {
  switch (status.trim().toLowerCase()) {
    case 'paid':
      return 'Đã thanh toán';
    case 'completed':
    case 'delivered':
      return 'Đã giao';
    case 'shipping':
      return 'Đang giao';
    case 'processing':
      return 'Đang xử lý';
    case 'pending':
      return 'Chờ xử lý';
    case 'cancelled':
      return 'Đã hủy';
    case 'failed':
      return 'Thất bại';
    default:
      return status.isEmpty ? 'Đang xử lý' : status;
  }
}

String _formatCurrency(int amount) {
  final digits = amount.abs().toString();
  final buffer = StringBuffer();
  for (var index = 0; index < digits.length; index++) {
    final reverseIndex = digits.length - index;
    buffer.write(digits[index]);
    if (reverseIndex > 1 && reverseIndex % 3 == 1) {
      buffer.write(',');
    }
  }
  final formatted = buffer.toString();
  return '${amount < 0 ? '-' : ''}$formattedđ';
}

const _lineStyle = TextStyle(
  fontSize: 10,
  height: 1.2,
  color: ProfileColors.text,
);
