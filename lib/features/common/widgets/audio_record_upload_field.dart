import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:record/record.dart';
import '../../auth/models/theme_colors.dart';
import '../providers/file_upload_provider.dart';
import '../services/app_snackbar_service.dart';
import 'custom_text_form_field.dart';

class AudioRecordUploadField extends ConsumerStatefulWidget {
  final TextEditingController controller;
  final ThemeColors colors;
  final Color primaryColor;
  final String labelText;
  final String hintText;
  final bool enabled;
  final ValidatorCallback? validator;
  final ValueChanged<String>? onUploaded;
  final ValueChanged<bool>? onUploadingChanged;

  const AudioRecordUploadField({
    super.key,
    required this.controller,
    required this.colors,
    required this.primaryColor,
    required this.labelText,
    required this.hintText,
    this.enabled = true,
    this.validator,
    this.onUploaded,
    this.onUploadingChanged,
  });

  @override
  ConsumerState<AudioRecordUploadField> createState() =>
      _AudioRecordUploadFieldState();
}

class _AudioRecordUploadFieldState extends ConsumerState<AudioRecordUploadField> {
  final AudioRecorder _recorder = AudioRecorder();
  StreamSubscription<Uint8List>? _recordStreamSubscription;
  final List<int> _recordedBytes = [];
  AudioEncoder _activeEncoder = AudioEncoder.aacLc;

  bool _isRecording = false;
  bool _isUploading = false;

  @override
  void dispose() {
    _recordStreamSubscription?.cancel();
    _recorder.dispose();
    super.dispose();
  }

  RecordConfig _buildRecordConfig() {
    return const RecordConfig(
      encoder: AudioEncoder.aacLc,
      bitRate: 128000,
      sampleRate: 44100,
    );
  }

  Future<void> _toggleRecording() async {
    if (!widget.enabled || _isUploading) return;

    if (!_isRecording) {
      final hasPermission = await _recorder.hasPermission();
      if (!hasPermission) {
        AppSnackbarService.error('Microphone permission is required.');
        return;
      }

      try {
        final config = _buildRecordConfig();
        _activeEncoder = config.encoder;
        _recordedBytes.clear();
        _recordStreamSubscription?.cancel();

        final audioStream = await _recorder.startStream(config);
        _recordStreamSubscription = audioStream.listen(
          (chunk) => _recordedBytes.addAll(chunk),
        );

        if (!mounted) return;
        setState(() => _isRecording = true);
      } catch (e) {
        AppSnackbarService.error('Unable to start recording: $e');
      }
      return;
    }

    try {
      await _recorder.stop();
      await _recordStreamSubscription?.cancel();
      _recordStreamSubscription = null;

      if (!mounted) return;
      setState(() => _isRecording = false);

      if (_recordedBytes.isEmpty) {
        AppSnackbarService.error('No recording captured.');
        return;
      }

      await _uploadRecordedAudio(Uint8List.fromList(_recordedBytes));
      _recordedBytes.clear();
    } catch (e) {
      if (!mounted) return;
      setState(() => _isRecording = false);
      AppSnackbarService.error('Unable to stop recording: $e');
    }
  }

  String _fileExtensionForEncoder(AudioEncoder encoder) {
    switch (encoder) {
      case AudioEncoder.opus:
        return 'opus';
      case AudioEncoder.wav:
        return 'wav';
      case AudioEncoder.flac:
        return 'flac';
      case AudioEncoder.amrNb:
      case AudioEncoder.amrWb:
        return '3gp';
      case AudioEncoder.pcm16bits:
        return 'pcm';
      case AudioEncoder.aacEld:
      case AudioEncoder.aacHe:
      case AudioEncoder.aacLc:
        return 'm4a';
    }
  }

  Future<void> _uploadRecordedAudio(Uint8List audioBytes) async {
    setState(() => _isUploading = true);
    widget.onUploadingChanged?.call(true);

    try {
      final uploader = ref.read(fileUploadServiceProvider);
      final now = DateTime.now().millisecondsSinceEpoch;
      final ext = _fileExtensionForEncoder(_activeEncoder);
      final metadata = await uploader.uploadFileBytes(
        fileBytes: audioBytes,
        fileName: 'audio_$now.$ext',
      );

      if (!mounted) return;

      final fileName = metadata?.fileName?.trim();
      if (fileName == null || fileName.isEmpty) {
        AppSnackbarService.error('Audio upload failed.');
        return;
      }

      widget.controller.text = fileName;
      widget.onUploaded?.call(fileName);
      AppSnackbarService.success('Audio uploaded successfully.');
    } catch (e) {
      AppSnackbarService.error('Failed to upload recorded audio: $e');
    } finally {
      if (!mounted) return;
      setState(() => _isUploading = false);
      widget.onUploadingChanged?.call(false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final iconColor = _isRecording ? Colors.red : widget.primaryColor;
    final isBusy = _isUploading;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: CustomTextFormField(
            controller: widget.controller,
            labelText: widget.labelText,
            hintText: widget.hintText,
            prefixIcon: Icons.audiotrack_outlined,
            colors: widget.colors,
            primaryColor: widget.primaryColor,
            keyboardType: TextInputType.text,
            validator: widget.validator,
          ),
        ),
        const SizedBox(width: 10),
        Padding(
          padding: const EdgeInsets.only(top: 8),
          child: IconButton(
            onPressed: (!widget.enabled || isBusy) ? null : _toggleRecording,
            tooltip: _isRecording ? 'Stop Recording' : 'Start Recording',
            icon: isBusy
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Icon(
                    _isRecording ? Icons.stop_circle_outlined : Icons.mic_none_rounded,
                    color: iconColor,
                  ),
          ),
        ),
      ],
    );
  }
}
