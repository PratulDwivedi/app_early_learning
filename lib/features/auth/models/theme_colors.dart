import 'package:flutter/material.dart';

class ThemeColors {
  final Color bgColor;
  final Color cardColor;
  final Color textColor;
  final Color hintColor;
  final Color inputFillColor;
  final Color inputTextColor;

  const ThemeColors({
    required this.bgColor,
    required this.cardColor,
    required this.textColor,
    required this.hintColor,
    required this.inputFillColor,
    required this.inputTextColor,
  });

  // Factory constructor for light theme
  factory ThemeColors.light() {
    return const ThemeColors(
      bgColor: Color(0xFFF5F5F5),
      cardColor: Colors.white,
      textColor: Colors.black,
      hintColor: Color(0xFF999999), // Colors.grey[600]
      inputFillColor: Color(0xFFF5F5F5),
      inputTextColor: Colors.black,
    );
  }

  // Factory constructor for dark theme
  factory ThemeColors.dark() {
    return const ThemeColors(
      bgColor: Color(0xFF1E1E1E),
      cardColor: Color(0xFF2D2D2D),
      textColor: Colors.white,
      hintColor: Color(0xFFBBBBBB), // Colors.grey[400]
      inputFillColor: Color(0xFF3D3D3D),
      inputTextColor: Colors.white,
    );
  }
}
