import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/providers/theme_provider.dart';

class ThemeSelector extends ConsumerWidget {
  const ThemeSelector({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeState = ref.watch(themeProvider);
    final isDarkMode = themeState.isDarkMode;
    final primaryColor = ref.watch(primaryColorProvider);
    final primaryColorIndex = themeState.primaryColorIndex;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF1a1a2e) : Colors.white,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Customize Theme',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isDarkMode ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 16),
          // Theme Toggle
          _buildThemeToggle(context, ref, isDarkMode, primaryColor),
          const SizedBox(height: 16),
          // Color Picker
          _buildColorPicker(context, ref, isDarkMode, primaryColorIndex),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildThemeToggle(BuildContext context, WidgetRef ref, bool isDarkMode,
      Color primaryColor) {
    return Container(
      decoration: BoxDecoration(
        color: isDarkMode
            ? Colors.white.withOpacity(0.2)
            : Colors.grey.withOpacity(0.2),
        borderRadius: BorderRadius.circular(25),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildThemeButton(
              context, ref, 'Light', Icons.light_mode, !isDarkMode),
          _buildThemeButton(context, ref, 'Dark', Icons.dark_mode, isDarkMode),
        ],
      ),
    );
  }

  Widget _buildThemeButton(BuildContext context, WidgetRef ref, String text,
      IconData icon, bool isSelected) {
    final primaryColor = ref.watch(primaryColorProvider);
    return GestureDetector(
      onTap: () {
        if (!isSelected) {
          ref.read(themeProvider.notifier).toggleTheme();
          HapticFeedback.lightImpact();
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? primaryColor : Colors.transparent,
          borderRadius: BorderRadius.circular(25),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 18,
              color: isSelected ? Colors.white : Colors.grey,
            ),
            const SizedBox(width: 8),
            Text(
              text,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: isSelected ? Colors.white : Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildColorPicker(
      BuildContext context, WidgetRef ref, bool isDarkMode, int selectedIndex) {
    final themeNotifier = ref.read(themeProvider.notifier);
    const colors = ThemeNotifier.primaryColors;

    return Wrap(
      spacing: 16,
      runSpacing: 16,
      children: colors.asMap().entries.map((entry) {
        final index = entry.key;
        final color = entry.value;
        bool isSelected = index == selectedIndex;

        return GestureDetector(
          onTap: () {
            themeNotifier.setPrimaryColor(index);
            HapticFeedback.lightImpact();
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              border: Border.all(
                color: isSelected
                    ? (isDarkMode ? Colors.white : Colors.black)
                    : Colors.transparent,
                width: 3,
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: color.withOpacity(0.5),
                        blurRadius: 8,
                        spreadRadius: 2,
                      ),
                    ]
                  : null,
            ),
            child: isSelected
                ? const Icon(Icons.check, color: Colors.white, size: 20)
                : null,
          ),
        );
      }).toList(),
    );
  }
}
