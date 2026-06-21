import 'package:flutter/material.dart';

import 'package:bt_mobile/core/theme/bt_colors.dart';
import 'package:bt_mobile/core/theme/bt_spacing.dart';
import 'package:bt_mobile/core/theme/bt_typography.dart';
import 'package:bt_mobile/core/widgets/buttons/bt_buttons.dart';
import 'package:bt_mobile/core/widgets/inputs/bt_list_screen_header.dart';

enum RejectOrderStep { form, confirm }

Future<bool?> showRejectOrderSheet({
  required BuildContext context,
  required List<String> reasons,
}) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => _RejectOrderSheet(reasons: reasons),
  );
}

class _RejectOrderSheet extends StatefulWidget {
  const _RejectOrderSheet({required this.reasons});

  final List<String> reasons;

  @override
  State<_RejectOrderSheet> createState() => _RejectOrderSheetState();
}

class _RejectOrderSheetState extends State<_RejectOrderSheet> {
  var _step = RejectOrderStep.form;
  String? _selectedReason;
  final _commentsController = TextEditingController();

  @override
  void dispose() {
    _commentsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: Container(
        decoration: const BoxDecoration(
          color: BtColors.surface,
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(BtSpacing.radiusXl),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 52,
              height: 4,
              decoration: BoxDecoration(
                color: BtColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                BtSpacing.xl,
                BtSpacing.lg,
                BtSpacing.lg,
                BtSpacing.md,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      _step == RejectOrderStep.form
                          ? 'Reject Order'
                          : 'Confirm Rejection',
                      style: BtTypography.headingXlSemibold,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),
            if (_step == RejectOrderStep.form) ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: BtSpacing.xl),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Select reason', style: BtTypography.bodyMdMedium),
                    const SizedBox(height: BtSpacing.md),
                    for (final reason in widget.reasons)
                      Padding(
                        padding: const EdgeInsets.only(bottom: BtSpacing.sm),
                        child: BtRadioOption(
                          label: reason,
                          selected: _selectedReason == reason,
                          onTap: () => setState(() => _selectedReason = reason),
                        ),
                      ),
                    const SizedBox(height: BtSpacing.lg),
                    Text('Comments (optional)', style: BtTypography.bodyMdMedium),
                    const SizedBox(height: BtSpacing.sm),
                    TextField(
                      controller: _commentsController,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        hintText: 'Add any additional notes',
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(BtSpacing.xl),
                child: Row(
                  children: [
                    Expanded(
                      child: BtOutlineButton(
                        label: 'Cancel',
                        onPressed: () => Navigator.pop(context),
                      ),
                    ),
                    const SizedBox(width: BtSpacing.md),
                    Expanded(
                      child: BtPrimaryButton(
                        label: 'Continue',
                        onPressed: _selectedReason == null
                            ? null
                            : () => setState(() => _step = RejectOrderStep.confirm),
                      ),
                    ),
                  ],
                ),
              ),
            ] else ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: BtSpacing.xl),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'You are about to reject this order.',
                      style: BtTypography.bodyMdMedium,
                    ),
                    const SizedBox(height: BtSpacing.md),
                    _SummaryLine(label: 'Reason', value: _selectedReason!),
                    if (_commentsController.text.trim().isNotEmpty)
                      _SummaryLine(
                        label: 'Comments',
                        value: _commentsController.text.trim(),
                      ),
                    const SizedBox(height: BtSpacing.md),
                    Text(
                      'This action cannot be undone.',
                      style: BtTypography.bodySmRegular.copyWith(
                        color: BtColors.badgeRed,
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(BtSpacing.xl),
                child: Row(
                  children: [
                    Expanded(
                      child: BtOutlineButton(
                        label: 'Back',
                        onPressed: () =>
                            setState(() => _step = RejectOrderStep.form),
                      ),
                    ),
                    const SizedBox(width: BtSpacing.md),
                    Expanded(
                      child: BtPrimaryButton(
                        label: 'Reject Order',
                        onPressed: () => Navigator.pop(context, true),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _SummaryLine extends StatelessWidget {
  const _SummaryLine({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: BtSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 90,
            child: Text(label, style: BtTypography.bodySmRegular),
          ),
          Expanded(child: Text(value, style: BtTypography.bodyMdMedium)),
        ],
      ),
    );
  }
}
