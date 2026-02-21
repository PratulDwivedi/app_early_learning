import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeNotifier extends StateNotifier<ThemeState> {
  ThemeNotifier() : super(const ThemeState()) {
    _loadTheme();
  }

  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final isDarkMode = prefs.getBool('isDarkMode') ?? false;
    final primaryColorIndex = prefs.getInt('primaryColorIndex') ?? 0;

    state = state.copyWith(
      isDarkMode: isDarkMode,
      primaryColorIndex: primaryColorIndex,
    );
  }

  Future<void> toggleTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final newDarkMode = !state.isDarkMode;
    await prefs.setBool('isDarkMode', newDarkMode);

    state = state.copyWith(isDarkMode: newDarkMode);
  }

  Future<void> setPrimaryColor(int colorIndex) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('primaryColorIndex', colorIndex);

    state = state.copyWith(primaryColorIndex: colorIndex);
  }

  Color get primaryColor => primaryColors[state.primaryColorIndex];

  static const List<Color> primaryColors = [
    Colors.blue,
    Colors.green,
    Colors.purple,
    Colors.orange,
    Colors.red,
    Colors.teal,
    Colors.indigo,
    Colors.pink,
  ];
}

class ThemeState {
  final bool isDarkMode;
  final int primaryColorIndex;

  const ThemeState({
    this.isDarkMode = false,
    this.primaryColorIndex = 0,
  });

  ThemeState copyWith({
    bool? isDarkMode,
    int? primaryColorIndex,
  }) {
    return ThemeState(
      isDarkMode: isDarkMode ?? this.isDarkMode,
      primaryColorIndex: primaryColorIndex ?? this.primaryColorIndex,
    );
  }
}

final themeProvider = StateNotifierProvider<ThemeNotifier, ThemeState>((ref) {
  return ThemeNotifier();
});

// Convenience providers
final isDarkModeProvider = Provider<bool>((ref) {
  return ref.watch(themeProvider).isDarkMode;
});

final primaryColorProvider = Provider<Color>((ref) {
  final index =
      ref.watch(themeProvider.select((value) => value.primaryColorIndex));
  return ThemeNotifier.primaryColors[index];
});

final primaryColorIndexProvider = Provider<int>((ref) {
  return ref.watch(themeProvider).primaryColorIndex;
});
