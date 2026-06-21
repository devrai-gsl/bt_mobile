import 'package:flutter/material.dart';

import 'package:bt_mobile/core/constants/asset_paths.dart';

class BtLogo extends StatelessWidget {
  const BtLogo({
    super.key,
    this.size = 56,
    this.fit = BoxFit.contain,
  });

  final double size;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      BtAssets.browntapeLogo,
      width: size,
      height: size,
      fit: fit,
      filterQuality: FilterQuality.high,
    );
  }
}
