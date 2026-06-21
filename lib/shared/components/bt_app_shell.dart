import 'package:flutter/material.dart';

import 'package:bt_mobile/features/auth/providers/auth_controller.dart';
import 'package:bt_mobile/features/auth/models/user_profile.dart';
import 'package:bt_mobile/core/theme/bt_colors.dart';
import 'package:bt_mobile/core/theme/bt_typography.dart';
import 'package:bt_mobile/features/home/screens/dashboard_screen.dart';
import 'package:bt_mobile/shared/bottom_sheets/location_picker_sheet.dart';
import 'package:bt_mobile/features/more/screens/more_screen.dart';
import 'package:bt_mobile/features/notifications/screens/notification_settings_screen.dart';
import 'package:bt_mobile/features/notifications/screens/notifications_screen.dart';
import 'package:bt_mobile/features/orders/screens/orders_screen.dart';
import 'package:bt_mobile/features/returns/screens/acknowledge_returns_screen.dart';
import 'package:bt_mobile/features/returns/screens/return_qc_screen.dart';
import 'package:bt_mobile/features/returns/screens/returns_home_screen.dart';
import 'package:bt_mobile/features/returns/screens/returns_screen.dart';
import 'app_nav_id.dart';
import 'bt_bottom_nav_bar.dart';

enum _ShellOverlay {
  none,
  notifications,
  notificationSettings,
}

/// Main scaffold with bottom navigation (no drawer).
class BtAppShell extends StatefulWidget {
  const BtAppShell({
    super.key,
    required this.controller,
    this.companyAddress,
    this.companyPhone,
  });

  final AuthController controller;
  final String? companyAddress;
  final String? companyPhone;

  @override
  State<BtAppShell> createState() => _BtAppShellState();
}

class _BtAppShellState extends State<BtAppShell> {
  AppNavId _selected = AppNavId.home;
  _ShellOverlay _overlay = _ShellOverlay.none;
  int _ordersTab = 1;
  int _notificationBadgeCount = 3;
  late String _selectedLocation;

  @override
  void initState() {
    super.initState();
    _selectedLocation =
        widget.controller.session?.user.warehouseName ?? 'Goa Warehouse';
  }

  bool _canSwitchLocation(UserProfile user) =>
      user.hasFullAccess || widget.controller.isDevSkipLogin;

  String _warehouseFor(UserProfile user) {
    if (_canSwitchLocation(user)) {
      return _selectedLocation;
    }
    return user.warehouseName ?? 'Goa Warehouse';
  }

  Future<void> _openLocationPicker(UserProfile user) async {
    final result = await showLocationPickerSheet(
      context: context,
      selectedLocation: _selectedLocation,
      title: _selectedLocation == (user.warehouseName ?? 'Goa Warehouse')
          ? 'Select Location'
          : 'Switch Location',
    );
    if (result != null && mounted) {
      setState(() => _selectedLocation = result);
    }
  }

  AppNavId get _bottomNavSelected {
    if (_overlay == _ShellOverlay.notifications ||
        _overlay == _ShellOverlay.notificationSettings) {
      return AppNavId.home;
    }
    return _selected;
  }

  void _onNavSelect(AppNavId id) {
    setState(() {
      _selected = id;
      _overlay = _ShellOverlay.none;
      // Default to New tab when opening Orders from bottom nav (per spec).
      if (id == AppNavId.orders) {
        _ordersTab = 1;
      }
    });
  }

  void _openNotifications() {
    setState(() => _overlay = _ShellOverlay.notifications);
  }

  void _closeNotifications() {
    setState(() => _overlay = _ShellOverlay.none);
  }

  void _openNotificationSettings() {
    setState(() => _overlay = _ShellOverlay.notificationSettings);
  }

  void _closeNotificationSettings() {
    setState(() => _overlay = _ShellOverlay.notifications);
  }

  void _goToOrders([int? tab]) {
    setState(() {
      _selected = AppNavId.orders;
      _overlay = _ShellOverlay.none;
      _ordersTab = tab ?? 1;
    });
  }

  void _goToReturns([int? action]) {
    setState(() {
      _selected = AppNavId.returns;
      _overlay = _ShellOverlay.none;
    });
    if (action == null) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final route = switch (action) {
        0 => MaterialPageRoute<void>(
          builder: (_) => const AcknowledgeReturnsScreen(),
        ),
        1 => MaterialPageRoute<void>(
          builder: (_) => const ReturnQcScreen(),
        ),
        _ => null,
      };
      if (route != null) {
        Navigator.of(context).push(route);
      }
    });
  }

  Widget _buildBody(UserProfile user) {
    return switch (_overlay) {
      _ShellOverlay.notificationSettings => NotificationSettingsBody(
        onBack: _closeNotificationSettings,
      ),
      _ShellOverlay.notifications => NotificationsBody(
        onBack: _closeNotifications,
        onSettings: _openNotificationSettings,
        onUnreadCountChanged: (count) {
          setState(() => _notificationBadgeCount = count);
        },
      ),
      _ShellOverlay.none => switch (_selected) {
        AppNavId.home => DashboardBody(
          user: user,
          controller: widget.controller,
          onViewAllOrders: () => _goToOrders(1),
          onViewAllReturns: () => _goToReturns(),
          onOrdersTab: _goToOrders,
          onReturnsTab: _goToReturns,
          onNotificationsTap: _openNotifications,
          notificationBadgeCount: _notificationBadgeCount,
          selectedLocation: _warehouseFor(user),
          canSwitchLocation: _canSwitchLocation(user),
          onLocationTap: _canSwitchLocation(user)
              ? () => _openLocationPicker(user)
              : null,
        ),
        AppNavId.orders => OrdersScreen(
          key: ValueKey('orders-tab-$_ordersTab'),
          warehouseName: _warehouseFor(user),
          initialTab: _ordersTab,
        ),
        AppNavId.returns => ReturnsHomeScreen(
          warehouseName: _warehouseFor(user),
          onViewAllReturns: () {
            Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => ReturnsScreen(
                  warehouseName: _warehouseFor(user),
                ),
              ),
            );
          },
        ),
        AppNavId.more => MoreScreen(controller: widget.controller),
      },
    };
  }

  @override
  Widget build(BuildContext context) {
    final user = widget.controller.session?.user;
    if (user == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: BtColors.screenBg,
      body: SafeArea(
        bottom: false,
        child: _buildBody(user),
      ),
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (widget.controller.isDevSkipLogin)
            Material(
              color: BtColors.surfaceMuted,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 6, 16, 0),
                child: Text(
                  'Dev mode: auth bypassed',
                  textAlign: TextAlign.center,
                  style: BtTypography.bodySmRegular,
                ),
              ),
            ),
          BtBottomNavBar(
            selected: _bottomNavSelected,
            onSelect: _onNavSelect,
          ),
        ],
      ),
    );
  }
}
