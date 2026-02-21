import 'package:flutter/material.dart';

/// Helper widget to load PNG images from assets
class AssetImage extends StatelessWidget {
  final String assetPath;
  final double? width;
  final double? height;
  final BoxFit fit;
  final Color? color;
  final BlendMode? colorBlendMode;

  const AssetImage(
    this.assetPath, {
    super.key,
    this.width,
    this.height,
    this.fit = BoxFit.contain,
    this.color,
    this.colorBlendMode,
  });

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      assetPath,
      width: width,
      height: height,
      fit: fit,
      color: color,
      colorBlendMode: colorBlendMode,
    );
  }
}

/// Extended Image widget with additional features
class AppImage extends StatelessWidget {
  final String assetPath;
  final double? width;
  final double? height;
  final BoxFit fit;
  final BorderRadius? borderRadius;
  final double elevation;
  final Color? shadowColor;

  const AppImage(
    this.assetPath, {
    super.key,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius,
    this.elevation = 0,
    this.shadowColor,
  });

  @override
  Widget build(BuildContext context) {
    final imageWidget = Image.asset(
      assetPath,
      width: width,
      height: height,
      fit: fit,
    );

    if (borderRadius != null) {
      return ClipRRect(
        borderRadius: borderRadius!,
        child: imageWidget,
      );
    }

    if (elevation > 0) {
      return Card(
        elevation: elevation,
        shadowColor: shadowColor,
        child: ClipRRect(
          borderRadius: borderRadius ?? BorderRadius.zero,
          child: imageWidget,
        ),
      );
    }

    return imageWidget;
  }
}
