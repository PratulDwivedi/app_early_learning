import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tts/flutter_tts.dart';
import '../../common/widgets/common_gradient_header_widget.dart';
import '../../common/widgets/custom_button.dart';
import '../providers/theme_provider.dart';
import '../providers/auth_service_provider.dart';

class SpeechSettingsScreen extends ConsumerStatefulWidget {
  const SpeechSettingsScreen({super.key});

  @override
  ConsumerState<SpeechSettingsScreen> createState() =>
      _SpeechSettingsScreenState();
}

class _SpeechSettingsScreenState extends ConsumerState<SpeechSettingsScreen> {
  late FlutterTts _flutterTts;
  String? _selectedLanguage = 'en-US';
  double _speechRate = 0.5;
  double _pitch = 1.0;
  double _volume = 0.8;

  @override
  void initState() {
    super.initState();
    _initializeTts();
  }

  Future<void> _initializeTts() async {
    _flutterTts = FlutterTts();

    // Initialize voices and languages
    await _flutterTts.getVoices;

    // Set default values
    await _flutterTts.setLanguage(_selectedLanguage!);
    await _flutterTts.setSpeechRate(_speechRate);
    await _flutterTts.setPitch(_pitch);
    await _flutterTts.setVolume(_volume);
  }

  Future<void> _playTestAudio() async {
    await _flutterTts.setLanguage(_selectedLanguage!);
    await _flutterTts.setSpeechRate(_speechRate);
    await _flutterTts.setPitch(_pitch);
    await _flutterTts.setVolume(_volume);

    await _flutterTts.speak(
      'This is a test of the speech settings. You can adjust the rate, pitch, and volume.',
    );
  }

  void _stopAudio() {
    _flutterTts.stop();
  }

  @override
  void dispose() {
    _flutterTts.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = ref.watch(primaryColorProvider);
    final colors = ref.watch(themeColorsProvider);

    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Gradient Header
            CommonGradientHeader(
              title: 'Speech Settings',
              onRefresh: () {
                ref.invalidate(authInitializerProvider);
              },
            ),

            // Settings Content
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Settings Container
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: colors.cardColor,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        // Language Selector
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Language',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: colors.textColor,
                              ),
                            ),
                            const SizedBox(height: 12),
                            DropdownButton<String>(
                              isExpanded: true,
                              value: _selectedLanguage,
                              style: TextStyle(color: colors.textColor),
                              dropdownColor: colors.cardColor,
                              items:
                                  [
                                        'en-US',
                                        'en-GB',
                                        'en-IN',
                                        'es-ES',
                                        'fr-FR',
                                        'de-DE',
                                        'it-IT',
                                      ]
                                      .map(
                                        (lang) => DropdownMenuItem(
                                          value: lang,
                                          child: Text(lang),
                                        ),
                                      )
                                      .toList(),
                              onChanged: (value) {
                                if (value != null) {
                                  setState(() => _selectedLanguage = value);
                                }
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),

                        // Speech Rate Slider
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Speech Rate',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: colors.textColor,
                                  ),
                                ),
                                Text(
                                  _speechRate.toStringAsFixed(2),
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: colors.hintColor,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Slider(
                              value: _speechRate,
                              min: 0.1,
                              max: 1.0,
                              divisions: 9,
                              activeColor: primaryColor,
                              inactiveColor: primaryColor.withOpacity(0.2),
                              onChanged: (value) {
                                setState(() => _speechRate = value);
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),

                        // Pitch Slider
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Pitch',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: colors.textColor,
                                  ),
                                ),
                                Text(
                                  _pitch.toStringAsFixed(2),
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: colors.hintColor,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Slider(
                              value: _pitch,
                              min: 0.5,
                              max: 2.0,
                              divisions: 15,
                              activeColor: primaryColor,
                              inactiveColor: primaryColor.withOpacity(0.2),
                              onChanged: (value) {
                                setState(() => _pitch = value);
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),

                        // Volume Slider
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Volume',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: colors.textColor,
                                  ),
                                ),
                                Text(
                                  _volume.toStringAsFixed(2),
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: colors.hintColor,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Slider(
                              value: _volume,
                              min: 0.0,
                              max: 1.0,
                              divisions: 10,
                              activeColor: primaryColor,
                              inactiveColor: primaryColor.withOpacity(0.2),
                              onChanged: (value) {
                                setState(() => _volume = value);
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Test Audio Section
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: primaryColor.withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Test Audio',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: colors.textColor,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Click the button below to test your speech settings with a sample audio.',
                          style: TextStyle(
                            fontSize: 12,
                            color: colors.hintColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Action Buttons
                  Row(
                    children: [
                      Expanded(
                        child: CustomPrimaryButton(
                          label: 'Test Audio',
                          onPressed: _playTestAudio,
                          primaryColor: primaryColor,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: CustomSecondaryButton(
                          label: 'Stop',
                          onPressed: _stopAudio,
                          primaryColor: primaryColor,
                          textColor: colors.textColor,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
