import 'dart:async';

import 'package:flutter/material.dart';

import 'package:bt_mobile/features/returns/repositories/returns_repository.dart';
import 'package:bt_mobile/core/theme/bt_colors.dart';
import 'package:bt_mobile/core/theme/bt_spacing.dart';
import 'package:bt_mobile/core/theme/bt_typography.dart';
import 'package:bt_mobile/features/scanner/widgets/bt_camera_preview.dart';
import 'package:bt_mobile/core/widgets/buttons/bt_buttons.dart';
import 'package:bt_mobile/features/scanner/screens/bt_barcode_scanner_screen.dart';
import 'package:bt_mobile/core/widgets/inputs/bt_input_field.dart';
import 'package:bt_mobile/features/returns/screens/qc_capture_screen.dart';
import 'package:bt_mobile/features/returns/models/returns_models.dart';

enum _QcStep { scan, recording, items, complete }

class ReturnQcScreen extends StatefulWidget {
  const ReturnQcScreen({super.key});

  @override
  State<ReturnQcScreen> createState() => _ReturnQcScreenState();
}

class _ReturnQcScreenState extends State<ReturnQcScreen> {
  final _repo = ReturnsRepository();
  final _scanController = TextEditingController();
  late Future<ReturnsQcData> _configFuture = _repo.getQcConfig();

  String? _channelId;
  QcReturnDetail? _activeReturn;
  _QcStep _step = _QcStep.scan;
  int _recordingSeconds = 0;
  int _maxRecordingSeconds = 90;
  Timer? _recordingTimer;
  bool _recordingComplete = false;
  bool _showStopConfirm = false;

  @override
  void dispose() {
    _scanController.dispose();
    _recordingTimer?.cancel();
    super.dispose();
  }

  Future<void> _scanFromCamera(ReturnsQcData config) async {
    final code = await openBarcodeScanner(context, title: 'Scan return');
    if (code != null && mounted) _loadReturn(config, code);
  }

  void _loadReturn(ReturnsQcData config, String code) {
    final returnId = config.knownBarcodes[code];
    if (returnId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Return not found')),
      );
      return;
    }
    final detail = config.returns[returnId];
    if (detail == null) return;

    setState(() {
      _activeReturn = detail;
      if (config.mediaMode == 'video_auto_off') {
        _step = _QcStep.items;
        _recordingComplete = false;
      } else if (config.mediaMode == 'video_auto_on') {
        _step = _QcStep.recording;
        _startRecording(config);
      } else {
        _step = _QcStep.items;
        _recordingComplete = true;
      }
    });
  }

  void _startRecording(ReturnsQcData config) {
    final countdown = config.countdownSeconds;
    _maxRecordingSeconds = config.maxRecordingSeconds(_activeReturn);
    _recordingSeconds = -countdown;
    _showStopConfirm = false;
    _recordingTimer?.cancel();
    _recordingTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() => _recordingSeconds++);
      if (_recordingSeconds >= _maxRecordingSeconds) {
        timer.cancel();
        setState(() {
          _recordingComplete = true;
          _step = _QcStep.items;
          _showStopConfirm = false;
        });
      }
    });
  }

  void _requestStopRecording() {
    if (_recordingSeconds < 0) return;
    setState(() => _showStopConfirm = true);
  }

  void _continueRecording() {
    setState(() => _showStopConfirm = false);
  }

  void _confirmStopRecording() {
    _recordingTimer?.cancel();
    setState(() {
      _showStopConfirm = false;
      _recordingComplete = true;
      _step = _QcStep.items;
    });
  }

  String _formatClock(int totalSeconds) {
    final safe = totalSeconds < 0 ? 0 : totalSeconds;
    final minutes = safe ~/ 60;
    final seconds = safe % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  void _updateItem(String itemId, String status, {String? reason}) {
    if (_activeReturn == null) return;
    final items = _activeReturn!.items.map((item) {
      if (item.id != itemId) return item;
      return item.copyWith(qcStatus: status, badConditionReason: reason);
    }).toList();
    setState(() => _activeReturn = _activeReturn!.copyWith(items: items));
  }

  int get _reviewedCount =>
      _activeReturn?.items.where((i) => i.qcStatus != 'pending').length ?? 0;

  bool get _allReviewed =>
      _activeReturn != null && _reviewedCount == _activeReturn!.items.length;

  void _completeQc() {
    setState(() => _step = _QcStep.complete);
  }

  void _markCompleteAndExit() {
    setState(() {
      _activeReturn = null;
      _step = _QcStep.scan;
      _recordingComplete = false;
      _recordingSeconds = 0;
      _showStopConfirm = false;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('QC submitted successfully')),
    );
  }

  Future<void> _markBad(
    BuildContext context,
    String itemId,
    String reason,
    String itemName,
  ) async {
    final captured = await Navigator.of(context).push<int>(
      MaterialPageRoute<int>(
        builder: (_) => QcCaptureScreen(itemName: itemName, badReason: reason),
      ),
    );
    if (captured != null && captured > 0) {
      _updateItem(itemId, 'failed', reason: reason);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: BtColors.screenBg,
      appBar: AppBar(
        title: const Text('Return QC'),
        backgroundColor: BtColors.surface,
        foregroundColor: BtColors.textPrimary,
        elevation: 1,
      ),
      body: FutureBuilder<ReturnsQcData>(
        future: _configFuture,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final config = snapshot.data!;

          if (_step == _QcStep.recording && _activeReturn != null) {
            return _RecordingView(
              returnRef: _activeReturn!.channelReturnRef,
              seconds: _recordingSeconds,
              maxSeconds: _maxRecordingSeconds,
              showStopConfirm: _showStopConfirm,
              onStop: _requestStopRecording,
              onContinueRecording: _continueRecording,
              onConfirmStop: _confirmStopRecording,
              formatClock: _formatClock,
            );
          }

          if (_step == _QcStep.items && _activeReturn != null) {
            return _ItemsView(
              detail: _activeReturn!,
              reviewed: _reviewedCount,
              recordingRequired: config.mediaMode == 'video_auto_off',
              recordingComplete: _recordingComplete,
              badReasons: config.badConditionReasons,
              onStartRecording: () {
                setState(() => _step = _QcStep.recording);
                _startRecording(config);
              },
              onDecision: _updateItem,
              onBadCapture: (itemId, reason, itemName) =>
                  _markBad(context, itemId, reason, itemName),
              onComplete: _allReviewed ? _completeQc : null,
              onBack: () => setState(() {
                _activeReturn = null;
                _step = _QcStep.scan;
              }),
            );
          }

          if (_step == _QcStep.complete && _activeReturn != null) {
            return _CompleteView(
              detail: _activeReturn!,
              onMarkComplete: _markCompleteAndExit,
              onBack: () => setState(() => _step = _QcStep.items),
            );
          }

          return ListView(
            padding: const EdgeInsets.all(BtSpacing.lg),
            children: [
              Text(config.warehouseName, style: BtTypography.bodySmRegular),
              const SizedBox(height: BtSpacing.md),
              DropdownButtonFormField<String>(
                value: _channelId ?? config.channels.first.id,
                decoration: const InputDecoration(labelText: 'Channel (optional)'),
                items: config.channels
                    .map((c) => DropdownMenuItem(value: c.id, child: Text(c.name)))
                    .toList(),
                onChanged: (v) => setState(() => _channelId = v),
              ),
              const SizedBox(height: BtSpacing.xl),
              Text('Scan return', style: BtTypography.bodyMdMedium),
              const SizedBox(height: BtSpacing.md),
              Row(
                children: [
                  Expanded(
                    child: BtSearchField(
                      hint: 'Order ID or AWB',
                      controller: _scanController,
                      onSubmitted: (v) => _loadReturn(config, v.trim()),
                    ),
                  ),
                  const SizedBox(width: BtSpacing.sm),
                  Material(
                    color: BtColors.surfaceMuted,
                    borderRadius: BorderRadius.circular(BtSpacing.radiusSm),
                    child: InkWell(
                      onTap: () => _scanFromCamera(config),
                      child: const Padding(
                        padding: EdgeInsets.all(12),
                        child: Icon(Icons.qr_code_scanner),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}

class _RecordingView extends StatelessWidget {
  const _RecordingView({
    required this.returnRef,
    required this.seconds,
    required this.maxSeconds,
    required this.showStopConfirm,
    required this.onStop,
    required this.onContinueRecording,
    required this.onConfirmStop,
    required this.formatClock,
  });

  final String returnRef;
  final int seconds;
  final int maxSeconds;
  final bool showStopConfirm;
  final VoidCallback onStop;
  final VoidCallback onContinueRecording;
  final VoidCallback onConfirmStop;
  final String Function(int totalSeconds) formatClock;

  bool get _isCountdown => seconds < 0;
  int get _elapsed => seconds < 0 ? 0 : seconds;
  int get _remaining => (maxSeconds - _elapsed).clamp(0, maxSeconds);

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        ColoredBox(
          color: Colors.black,
          child: Stack(
            fit: StackFit.expand,
            children: [
              const BtCameraPreview(),
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.35),
                      Colors.black.withValues(alpha: 0.1),
                      Colors.black.withValues(alpha: 0.75),
                    ],
                  ),
                ),
              ),
              SafeArea(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(
                        BtSpacing.lg,
                        BtSpacing.md,
                        BtSpacing.lg,
                        BtSpacing.lg,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _isCountdown
                                ? 'Starting in ${-seconds}s'
                                : '${formatClock(_remaining)} Time Left',
                            style: BtTypography.headingLgSemibold.copyWith(
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            returnRef,
                            style: BtTypography.bodyMdMedium.copyWith(
                              color: Colors.white70,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),
                    if (!_isCountdown)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(
                          BtSpacing.lg,
                          BtSpacing.lg,
                          BtSpacing.lg,
                          BtSpacing.xl,
                        ),
                        child: Material(
                          color: BtColors.badgeRed,
                          borderRadius: BorderRadius.circular(BtSpacing.radiusMd),
                          child: InkWell(
                            onTap: onStop,
                            borderRadius: BorderRadius.circular(BtSpacing.radiusMd),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: BtSpacing.xl,
                                vertical: BtSpacing.lg,
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(
                                    Icons.stop_circle_outlined,
                                    color: Colors.white,
                                  ),
                                  const SizedBox(width: BtSpacing.sm),
                                  Text(
                                    'Stop Recording',
                                    style: BtTypography.bodyBaseSemibold.copyWith(
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
        if (showStopConfirm)
          _StopRecordingSheet(
            recordedLabel: '${formatClock(_elapsed)} recorded so far',
            onContinueRecording: onContinueRecording,
            onConfirmStop: onConfirmStop,
          ),
      ],
    );
  }
}

class _StopRecordingSheet extends StatelessWidget {
  const _StopRecordingSheet({
    required this.recordedLabel,
    required this.onContinueRecording,
    required this.onConfirmStop,
  });

  final String recordedLabel;
  final VoidCallback onContinueRecording;
  final VoidCallback onConfirmStop;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Colors.black.withValues(alpha: 0.5),
      child: Align(
        alignment: Alignment.bottomCenter,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(
            BtSpacing.xl,
            BtSpacing.lg,
            BtSpacing.xl,
            BtSpacing.xl,
          ),
          decoration: const BoxDecoration(
            color: BtColors.surface,
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(BtSpacing.radiusXl),
            ),
          ),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 52,
                    height: 4,
                    decoration: BoxDecoration(
                      color: BtColors.border,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: BtSpacing.xl),
                Text('Stop Recording?', style: BtTypography.headingXlSemibold),
                const SizedBox(height: BtSpacing.sm),
                Text(
                  'The recording will be saved and attached to this return. '
                  'You cannot resume once it is stopped.',
                  style: BtTypography.bodyMdRegular,
                ),
                const SizedBox(height: BtSpacing.xl),
                Container(
                  padding: const EdgeInsets.all(BtSpacing.lg),
                  decoration: BoxDecoration(
                    color: BtColors.chipBg,
                    borderRadius: BorderRadius.circular(BtSpacing.radiusMd),
                    border: Border.all(color: BtColors.brandGreen.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 10,
                        height: 10,
                        decoration: const BoxDecoration(
                          color: BtColors.brandGreen,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: BtSpacing.md),
                      Expanded(
                        child: Text(
                          recordedLabel,
                          style: BtTypography.bodyBaseMedium,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: BtSpacing.xl),
                BtPrimaryButton(
                  label: 'Stop & Save Recording',
                  onPressed: onConfirmStop,
                ),
                const SizedBox(height: BtSpacing.md),
                BtOutlineButton(
                  label: 'Continue Recording',
                  onPressed: onContinueRecording,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ItemsView extends StatelessWidget {
  const _ItemsView({
    required this.detail,
    required this.reviewed,
    required this.recordingRequired,
    required this.recordingComplete,
    required this.badReasons,
    required this.onStartRecording,
    required this.onDecision,
    required this.onBadCapture,
    required this.onComplete,
    required this.onBack,
  });

  final QcReturnDetail detail;
  final int reviewed;
  final bool recordingRequired;
  final bool recordingComplete;
  final List<String> badReasons;
  final VoidCallback onStartRecording;
  final void Function(String itemId, String status, {String? reason}) onDecision;
  final void Function(String itemId, String reason, String itemName) onBadCapture;
  final VoidCallback? onComplete;
  final VoidCallback onBack;

  bool get _qcEnabled => !recordingRequired || recordingComplete;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(BtSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  IconButton(onPressed: onBack, icon: const Icon(Icons.arrow_back)),
                  Expanded(
                    child: Text(detail.channelReturnRef, style: BtTypography.headingLgSemibold),
                  ),
                ],
              ),
              Text('${detail.channel} · ${detail.awb}', style: BtTypography.bodySmRegular),
              Text('Progress: $reviewed of ${detail.items.length}', style: BtTypography.bodyMdMedium),
              if (recordingRequired && !recordingComplete) ...[
                const SizedBox(height: BtSpacing.md),
                BtPrimaryButton(
                  label: 'Start Recording',
                  onPressed: onStartRecording,
                  expand: false,
                ),
              ],
            ],
          ),
        ),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: BtSpacing.lg),
            itemCount: detail.items.length,
            separatorBuilder: (_, _) => const SizedBox(height: BtSpacing.md),
            itemBuilder: (context, index) {
              final item = detail.items[index];
              return _QcItemCard(
                item: item,
                enabled: _qcEnabled,
                badReasons: badReasons,
                onDecision: onDecision,
                onBadCapture: onBadCapture,
              );
            },
          ),
        ),
        if (onComplete != null)
          Padding(
            padding: const EdgeInsets.all(BtSpacing.lg),
            child: BtPrimaryButton(label: 'Review & Complete', onPressed: onComplete),
          ),
      ],
    );
  }
}

class _CompleteView extends StatelessWidget {
  const _CompleteView({
    required this.detail,
    required this.onMarkComplete,
    required this.onBack,
  });

  final QcReturnDetail detail;
  final VoidCallback onMarkComplete;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final passed = detail.items.where((i) => i.qcStatus == 'passed').length;
    final failed = detail.items.where((i) => i.qcStatus == 'failed').length;
    final missing = detail.items.where((i) => i.qcStatus == 'missing').length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.all(BtSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  IconButton(onPressed: onBack, icon: const Icon(Icons.arrow_back)),
                  Expanded(
                    child: Text('Scan & QC Return', style: BtTypography.headingLgSemibold),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.all(BtSpacing.lg),
                decoration: BoxDecoration(
                  color: BtColors.surface,
                  borderRadius: BorderRadius.circular(BtSpacing.radiusLg),
                  border: Border.all(color: BtColors.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${detail.channel} · Order Ref: ${detail.orderRef}',
                      style: BtTypography.bodyMdRegular,
                    ),
                    Text('Return Ref: ${detail.channelReturnRef}'),
                    if (detail.returnReason != null)
                      Text('Return Reason: ${detail.returnReason}'),
                  ],
                ),
              ),
              const SizedBox(height: BtSpacing.lg),
              Row(
                children: [
                  Text(
                    '${detail.items.length} of ${detail.items.length}',
                    style: BtTypography.bodyMdMedium,
                  ),
                  const SizedBox(width: BtSpacing.sm),
                  Text('completed', style: BtTypography.bodyMdRegular),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: BtSpacing.md,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: BtColors.chipBg,
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: BtColors.brandGreen),
                    ),
                    child: Text(
                      'QC Complete',
                      style: BtTypography.bodySmSemibold.copyWith(
                        color: BtColors.brandGreen,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: BtSpacing.sm),
              Text(
                'Good: $passed · Bad: $failed · Not received: $missing',
                style: BtTypography.bodySmRegular,
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: BtSpacing.lg),
            itemCount: detail.items.length,
            separatorBuilder: (_, _) => const SizedBox(height: BtSpacing.md),
            itemBuilder: (context, index) {
              final item = detail.items[index];
              return ListTile(
                tileColor: BtColors.surface,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(BtSpacing.radiusMd),
                  side: const BorderSide(color: BtColors.border),
                ),
                title: Text(item.name),
                subtitle: Text(item.qcStatus.toUpperCase()),
              );
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(BtSpacing.lg),
          child: BtPrimaryButton(label: 'Mark Complete', onPressed: onMarkComplete),
        ),
      ],
    );
  }
}

class _QcItemCard extends StatelessWidget {
  const _QcItemCard({
    required this.item,
    required this.enabled,
    required this.badReasons,
    required this.onDecision,
    required this.onBadCapture,
  });

  final QcReturnItem item;
  final bool enabled;
  final List<String> badReasons;
  final void Function(String itemId, String status, {String? reason}) onDecision;
  final void Function(String itemId, String reason, String itemName) onBadCapture;

  Color get _statusColor => switch (item.qcStatus) {
        'passed' => BtColors.brandGreen,
        'failed' => BtColors.badgeRed,
        'missing' => BtColors.badgeYellow,
        _ => BtColors.textMuted,
      };

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(BtSpacing.lg),
      decoration: BoxDecoration(
        color: BtColors.surface,
        borderRadius: BorderRadius.circular(BtSpacing.radiusLg),
        border: Border.all(color: BtColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(item.name, style: BtTypography.bodyBaseSemibold)),
              Text(item.qcStatus.toUpperCase(), style: BtTypography.bodySmSemibold.copyWith(color: _statusColor)),
            ],
          ),
          Text('${item.sku} · ${item.colour} · ${item.size}', style: BtTypography.bodySmRegular),
          if (!enabled)
            Padding(
              padding: const EdgeInsets.only(top: BtSpacing.sm),
              child: Text(
                'Start recording before QC',
                style: BtTypography.bodySmRegular.copyWith(color: BtColors.badgeYellow),
              ),
            ),
          if (enabled && item.qcStatus == 'pending') ...[
            const SizedBox(height: BtSpacing.md),
            Wrap(
              spacing: 8,
              children: [
                ActionChip(
                  label: const Text('Good'),
                  onPressed: () => onDecision(item.id, 'passed'),
                ),
                ActionChip(
                  label: const Text('Bad'),
                  onPressed: () => _pickBadReason(context),
                ),
                ActionChip(
                  label: const Text('Not Received'),
                  onPressed: () => onDecision(item.id, 'missing'),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _pickBadReason(BuildContext context) async {
    final reason = await showModalBottomSheet<String>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(BtSpacing.lg),
              child: Text('Bad condition reason', style: BtTypography.bodyMdMedium),
            ),
            for (final r in badReasons)
              ListTile(title: Text(r), onTap: () => Navigator.pop(context, r)),
          ],
        ),
      ),
    );
    if (reason != null) onBadCapture(item.id, reason, item.name);
  }
}
