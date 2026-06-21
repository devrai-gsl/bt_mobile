import 'package:flutter/material.dart';

import 'package:bt_mobile/core/theme/bt_colors.dart';
import 'package:bt_mobile/core/theme/bt_spacing.dart';
import 'package:bt_mobile/core/theme/bt_typography.dart';

class NotificationSettingsBody extends StatefulWidget {
  const NotificationSettingsBody({
    super.key,
    required this.onBack,
  });

  final VoidCallback onBack;

  @override
  State<NotificationSettingsBody> createState() =>
      _NotificationSettingsBodyState();
}

class _NotificationSettingsBodyState extends State<NotificationSettingsBody> {
  var _newOrders = false;
  var _cancelled = false;
  var _autoRejectWarning = false;
  var _autoRejected = false;
  var _muteNotifications = true;
  TimeOfDay _muteFrom = const TimeOfDay(hour: 22, minute: 0);
  TimeOfDay _muteTo = const TimeOfDay(hour: 7, minute: 0);

  Future<void> _pickTime({
    required TimeOfDay initial,
    required ValueChanged<TimeOfDay> onPicked,
  }) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: initial,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: BtColors.brandGreen,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => onPicked(picked));
    }
  }

  String _formatTime(TimeOfDay time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: BtColors.screenBg,
      child: Column(
        children: [
          _SettingsHeader(onBack: widget.onBack),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(BtSpacing.lg),
              children: [
                _SettingsSection(
                  title: 'Push Notifications',
                  children: [
                    _SettingsToggle(
                      title: 'New Order Received',
                      subtitle: 'Alert me when a new order is received',
                      value: _newOrders,
                      onChanged: (v) => setState(() => _newOrders = v),
                    ),
                    const Divider(height: 1, indent: 16, endIndent: 16),
                    _SettingsToggle(
                      title: 'Order Cancelled',
                      subtitle: 'Alert me when an order is cancelled',
                      value: _cancelled,
                      onChanged: (v) => setState(() => _cancelled = v),
                    ),
                    const Divider(height: 1, indent: 16, endIndent: 16),
                    _SettingsToggle(
                      title: 'Auto-Reject Warning',
                      subtitle: 'Alert me before an order is auto-rejected',
                      value: _autoRejectWarning,
                      onChanged: (v) => setState(() => _autoRejectWarning = v),
                    ),
                    const Divider(height: 1, indent: 16, endIndent: 16),
                    _SettingsToggle(
                      title: 'Order Auto-Rejected',
                      subtitle: 'Alert me when an order is auto-rejected',
                      value: _autoRejected,
                      onChanged: (v) => setState(() => _autoRejected = v),
                    ),
                  ],
                ),
                const SizedBox(height: BtSpacing.xl),
                _SettingsSection(
                  title: 'Quiet Hours',
                  children: [
                    _SettingsToggle(
                      title: 'Mute notifications',
                      subtitle: 'No alerts during specific hours',
                      value: _muteNotifications,
                      onChanged: (v) => setState(() => _muteNotifications = v),
                    ),
                    if (_muteNotifications) ...[
                      const Divider(height: 1, indent: 16, endIndent: 16),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                        child: Row(
                          children: [
                            Expanded(
                              child: _TimeField(
                                label: 'From',
                                value: _formatTime(_muteFrom),
                                onTap: () => _pickTime(
                                  initial: _muteFrom,
                                  onPicked: (t) => _muteFrom = t,
                                ),
                              ),
                            ),
                            const SizedBox(width: BtSpacing.md),
                            Expanded(
                              child: _TimeField(
                                label: 'To',
                                value: _formatTime(_muteTo),
                                onTap: () => _pickTime(
                                  initial: _muteTo,
                                  onPicked: (t) => _muteTo = t,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingsHeader extends StatelessWidget {
  const _SettingsHeader({required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: BtColors.surface,
      elevation: 2,
      shadowColor: Colors.black.withValues(alpha: 0.08),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 8, 16, 16),
        child: Row(
          children: [
            IconButton(
              onPressed: onBack,
              icon: const Icon(Icons.arrow_back),
            ),
            Expanded(
              child: Text(
                'Notification Settings',
                style: BtTypography.headingLgSemibold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TimeField extends StatelessWidget {
  const _TimeField({
    required this.label,
    required this.value,
    required this.onTap,
  });

  final String label;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(label, style: BtTypography.bodyMdMedium),
        const SizedBox(height: 6),
        Material(
          color: BtColors.surface,
          borderRadius: BorderRadius.circular(BtSpacing.radiusSm),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(BtSpacing.radiusSm),
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: BtSpacing.inputPaddingH,
                vertical: BtSpacing.inputPaddingV,
              ),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(BtSpacing.radiusSm),
                border: Border.all(color: BtColors.borderInput),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(value, style: BtTypography.bodyBaseRegular),
                  ),
                  const Icon(
                    Icons.schedule,
                    size: 16,
                    color: BtColors.textMuted,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _SettingsSection extends StatelessWidget {
  const _SettingsSection({
    required this.title,
    required this.children,
  });

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: BtTypography.bodyMdMedium),
        const SizedBox(height: BtSpacing.md),
        Container(
          decoration: BoxDecoration(
            color: BtColors.surface,
            borderRadius: BorderRadius.circular(BtSpacing.radiusLg),
            border: Border.all(color: BtColors.border),
            boxShadow: [
              BoxShadow(
                color: BtColors.brandGreen.withValues(alpha: 0.05),
                blurRadius: 2,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: Column(children: children),
        ),
      ],
    );
  }
}

class _SettingsToggle extends StatelessWidget {
  const _SettingsToggle({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: BtTypography.bodyMdMedium),
                const SizedBox(height: 2),
                Text(subtitle, style: BtTypography.bodySmRegular),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: BtColors.surface,
            activeTrackColor: BtColors.brandGreen,
          ),
        ],
      ),
    );
  }
}
