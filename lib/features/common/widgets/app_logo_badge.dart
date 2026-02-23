import 'package:flutter/material.dart' hide AssetImage;
import '../../../config/app_assets.dart';
import 'asset_image.dart';

class AppLogoBadge extends StatelessWidget {
  final Color backgroundColor;
  final double size;
  final double logoSize;

  const AppLogoBadge({
    super.key,
    required this.backgroundColor,
    this.size = 108,
    this.logoSize = 72,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: backgroundColor,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Center(
        child: AssetImage(
          AppAssets.logo,
          width: logoSize,
          height: logoSize,
          fit: BoxFit.contain,
        ),
      ),
    );
  }
}
