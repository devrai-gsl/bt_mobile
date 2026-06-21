import 'package:flutter/material.dart';

import 'package:bt_mobile/features/returns/repositories/returns_repository.dart';
import 'package:bt_mobile/core/theme/bt_colors.dart';
import 'package:bt_mobile/core/theme/bt_spacing.dart';
import 'package:bt_mobile/core/theme/bt_typography.dart';
import 'package:bt_mobile/features/returns/screens/acknowledge_returns_screen.dart';
import 'package:bt_mobile/features/returns/screens/return_qc_screen.dart';
import 'package:bt_mobile/features/returns/models/returns_models.dart';
import 'package:bt_mobile/features/returns/screens/returns_screen.dart';
import 'package:bt_mobile/shared/bottom_sheets/create_return_sheet.dart';

class ReturnsHomeScreen extends StatefulWidget {
  const ReturnsHomeScreen({
    super.key,
    this.warehouseName = 'Goa Warehouse',
    this.onViewAllReturns,
  });

  final String warehouseName;
  final VoidCallback? onViewAllReturns;

  @override
  State<ReturnsHomeScreen> createState() => _ReturnsHomeScreenState();
}

class _ReturnsHomeScreenState extends State<ReturnsHomeScreen> {
  final _repo = ReturnsRepository();
  late Future<ReturnsHomeData> _future = _repo.getHome();

  Future<void> _refresh() async {
    setState(() => _future = _repo.getHome());
    await _future;
  }

  Future<void> _openTile(ReturnsHomeTile tile) async {
    switch (tile.id) {
      case 'view_all':
        if (widget.onViewAllReturns != null) {
          widget.onViewAllReturns!();
        } else {
          await Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => ReturnsScreen(warehouseName: widget.warehouseName),
            ),
          );
        }
      case 'perform_qc':
        await Navigator.of(context).push(
          MaterialPageRoute<void>(builder: (_) => const ReturnQcScreen()),
        );
        await _refresh();
      case 'acknowledge':
        await Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => const AcknowledgeReturnsScreen(),
          ),
        );
        await _refresh();
      case 'create_return':
        final created = await showCreateReturnSheet(context);
        if (created == true) await _refresh();
    }
  }

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: BtColors.screenBg,
      child: FutureBuilder<ReturnsHomeData>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError || !snapshot.hasData) {
            return Center(
              child: Text(
                'Could not load returns home',
                style: BtTypography.bodyMdRegular,
              ),
            );
          }

          final data = snapshot.data!;
          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView(
              padding: const EdgeInsets.all(BtSpacing.lg),
              children: [
                Text(data.title, style: BtTypography.headingLgSemibold),
                if (data.warehouseName.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(data.warehouseName, style: BtTypography.bodySmRegular),
                ],
                const SizedBox(height: BtSpacing.xl),
                for (final section in data.sections) ...[
                  if (section.title.isNotEmpty) ...[
                    Text(section.title, style: BtTypography.bodyMdMedium),
                    const SizedBox(height: BtSpacing.md),
                  ],
                  _SectionCard(
                    tiles: section.tiles,
                    onTap: _openTile,
                  ),
                  const SizedBox(height: BtSpacing.xl),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.tiles, required this.onTap});

  final List<ReturnsHomeTile> tiles;
  final Future<void> Function(ReturnsHomeTile tile) onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: BtColors.surface,
      borderRadius: BorderRadius.circular(BtSpacing.radiusLg),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(BtSpacing.radiusLg),
          border: Border.all(color: BtColors.border),
          boxShadow: const [
            BoxShadow(
              color: Color(0x0A000000),
              blurRadius: 4,
              offset: Offset(0, 1),
            ),
          ],
        ),
        child: Column(
          children: [
            for (var i = 0; i < tiles.length; i++) ...[
              if (i > 0) const Divider(height: 1, color: BtColors.border),
              _ReturnsHomeTileRow(tile: tiles[i], onTap: () => onTap(tiles[i])),
            ],
          ],
        ),
      ),
    );
  }
}

class _ReturnsHomeTileRow extends StatelessWidget {
  const _ReturnsHomeTileRow({required this.tile, required this.onTap});

  final ReturnsHomeTile tile;
  final VoidCallback onTap;

  IconData get _icon => switch (tile.icon) {
        'qc' => Icons.fact_check_outlined,
        'ack' => Icons.inventory_2_outlined,
        'add' => Icons.add,
        _ => Icons.list_alt_outlined,
      };

  Color? get _iconBg => switch (tile.icon) {
        'qc' => BtColors.iconGreenBg,
        'ack' => BtColors.iconGreenBg,
        _ => null,
      };

  Color? get _badgeColor => switch (tile.badgeColor) {
        'red' => BtColors.badgeRed,
        'amber' => BtColors.badgeYellow,
        'muted' => BtColors.textMuted,
        _ => BtColors.brandGreen,
      };

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(BtSpacing.radiusLg),
      child: Padding(
        padding: const EdgeInsets.all(BtSpacing.lg),
        child: Row(
          children: [
            if (_iconBg != null)
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: _iconBg,
                  borderRadius: BorderRadius.circular(BtSpacing.radiusSm),
                ),
                child: Icon(_icon, color: BtColors.brandGreen, size: 22),
              )
            else
              Icon(_icon, color: BtColors.textPrimary, size: 22),
            const SizedBox(width: BtSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(tile.title, style: BtTypography.bodyMdMedium),
                  if (tile.subtitle != null && tile.subtitle!.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(tile.subtitle!, style: BtTypography.bodySmRegular),
                  ],
                ],
              ),
            ),
            if (tile.badgeCount != null && tile.badgeCount! > 0) ...[
              Text(
                '${tile.badgeCount}',
                style: BtTypography.headingLgSemibold.copyWith(
                  color: _badgeColor,
                ),
              ),
              const SizedBox(width: BtSpacing.sm),
            ],
            const Icon(Icons.chevron_right, color: BtColors.textMuted),
          ],
        ),
      ),
    );
  }
}
