import 'package:flutter/material.dart';

import 'package:bt_mobile/core/theme/bt_colors.dart';
import 'package:bt_mobile/shared/bottom_sheets/create_return_sheet.dart';

/// Full-screen entry for create return (e.g. from order detail prefill).
class CreateReturnScreen extends StatelessWidget {
  const CreateReturnScreen({super.key, this.prefillOrderId});

  final String? prefillOrderId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: BtColors.screenBg,
      appBar: AppBar(
        title: const Text('Create Return'),
        backgroundColor: BtColors.surface,
        foregroundColor: BtColors.textPrimary,
        elevation: 1,
      ),
      body: CreateReturnSheet(
        prefillOrderId: prefillOrderId,
        fullScreen: true,
      ),
    );
  }
}
