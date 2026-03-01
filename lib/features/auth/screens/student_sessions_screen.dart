import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../config/app_constants.dart';
import '../providers/auth_service_provider.dart';
import '../../common/models/screen_args_model.dart';
import '../../common/providers/question_provider.dart';
import '../../common/services/app_snackbar_service.dart';
import '../../common/services/navigation_service.dart';
import '../../common/widgets/common_gradient_header_widget.dart';
import '../providers/theme_provider.dart';

class StudentSessionsScreen extends ConsumerStatefulWidget {
  final ScreenArgsModel? args;

  const StudentSessionsScreen({super.key, this.args});

  @override
  ConsumerState<StudentSessionsScreen> createState() =>
      _StudentSessionsScreenState();
}

class _StudentSessionsScreenState extends ConsumerState<StudentSessionsScreen> {
  bool _isStarting = false;

  int get _studentId {
    final raw = widget.args?.data['id'] ?? widget.args?.data['student_id'];
    if (raw is int) return raw;
    return int.tryParse(raw?.toString() ?? '') ?? 0;
  }

  String get _studentName {
    final firstName = (widget.args?.data['first_name'] ?? '').toString().trim();
    final lastName = (widget.args?.data['last_name'] ?? '').toString().trim();
    final fullName = '$firstName $lastName'.trim();
    return fullName.isEmpty ? 'Student' : fullName;
  }

  int _toInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  String _twoDigits(int value) => value.toString().padLeft(2, '0');

  String _formatDateTime(String rawValue, String? formatPattern) {
    if (rawValue.trim().isEmpty) return '';
    final parsed = DateTime.tryParse(rawValue);
    if (parsed == null) return rawValue;

    final local = parsed.toLocal();
    final format = (formatPattern == null || formatPattern.trim().isEmpty)
        ? 'dd/mm/yyyy hh:mm:ss'
        : formatPattern.toLowerCase();

    final parts = format.split(' ');
    final datePattern = parts.isNotEmpty ? parts.first : 'dd/mm/yyyy';
    final timePattern = parts.length > 1 ? parts.sublist(1).join(' ') : '';

    final dateText = datePattern
        .replaceAll('yyyy', local.year.toString().padLeft(4, '0'))
        .replaceAll('yy', (local.year % 100).toString().padLeft(2, '0'))
        .replaceAll('dd', _twoDigits(local.day))
        .replaceAll('mm', _twoDigits(local.month));

    if (timePattern.isEmpty) return dateText;

    final timeText = timePattern
        .replaceAll('hh', _twoDigits(local.hour))
        .replaceAll('mm', _twoDigits(local.minute))
        .replaceAll('ss', _twoDigits(local.second));

    return '$dateText $timeText';
  }

  Future<void> _startAndOpenEvaluation({int? sessionId}) async {
    if (_studentId <= 0) {
      AppSnackbarService.error('Invalid student.');
      return;
    }

    setState(() {
      _isStarting = true;
    });

    try {
      final response = await ref.read(
        startSessionProvider(
          StartSessionArgs(
            studentId: _studentId,
            sessionId: sessionId,
          ),
        ).future,
      );

      if (!response.isSuccess) {
        AppSnackbarService.error(response.message);
        return;
      }

      final sessionPayload = response.firstOrNull;
      final args = ScreenArgsModel(
        routeName: AppPageRoute.evaluation,
        name: 'Evaluation',
        data: {
          ...?widget.args?.data,
          'session_payload': sessionPayload,
        },
      );

      final result = await NavigationService.navigateTo(
        args.routeName,
        arguments: args,
      );

      if (result == true) {
        ref.invalidate(getStudentSessionsProvider(_studentId));
      }
    } catch (error) {
      AppSnackbarService.error('Failed to start session: $error');
    } finally {
      if (!mounted) return;
      setState(() {
        _isStarting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = ref.watch(themeColorsProvider);
    final primaryColor = ref.watch(primaryColorProvider);
    final userDateTimeFormat = ref.watch(authProvider)?.data.datetimeFormat;
    if (_studentId <= 0) {
      return Scaffold(
        body: Column(
          children: [
            CommonGradientHeader(
              title: 'Student Sessions',
              onRefresh: () {},
            ),
            const Expanded(
              child: Center(
                child: Text('Invalid student selected.'),
              ),
            ),
          ],
        ),
      );
    }

    final sessionsAsync = ref.watch(getStudentSessionsProvider(_studentId));

    return Scaffold(
      body: Column(
        children: [
          CommonGradientHeader(
            title: 'Student Sessions',
            onRefresh: () {
              ref.invalidate(getStudentSessionsProvider(_studentId));
            },
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: colors.cardColor,
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
                          'Start New Session',
                          style: TextStyle(
                            color: colors.hintColor,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                _studentName,
                                style: TextStyle(
                                  color: colors.textColor,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 10),
                            ElevatedButton.icon(
                              onPressed:
                                  _isStarting
                                      ? null
                                      : () => _startAndOpenEvaluation(),
                              icon: _isStarting
                                  ? const SizedBox(
                                      width: 14,
                                      height: 14,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Icon(Icons.play_arrow),
                              label: const Text('Start'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Previous Sessions',
                    style: TextStyle(
                      color: colors.textColor,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 10),
                  sessionsAsync.when(
                    loading: () => const Center(
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: CircularProgressIndicator(),
                      ),
                    ),
                    error: (error, stack) => Text(
                      'Failed to load sessions: $error',
                      style: const TextStyle(color: Colors.red),
                    ),
                    data: (response) {
                      if (!response.isSuccess) {
                        return Text(
                          response.message,
                          style: const TextStyle(color: Colors.red),
                        );
                      }

                      if (response.data.isEmpty) {
                        return Text(
                          'No sessions found.',
                          style: TextStyle(color: colors.hintColor),
                        );
                      }

                      return Column(
                        children: response.data.map((session) {
                          final status =
                              (session['status'] ?? 'UNKNOWN').toString();
                          final attempted = _toInt(session['attempted']);
                          final correct = _toInt(session['correct']);
                          final incorrect = _toInt(session['incorrect']);
                          final skipped = _toInt(session['skipped']);
                          final total = _toInt(session['total_questions']);
                          final createdAt =
                              (session['created_at'] ?? '').toString();
                          final createdAtText =
                              _formatDateTime(createdAt, userDateTimeFormat);
                          final sessionId = _toInt(session['id']);
                          final canRestart = status != 'COMPLETED';

                          return Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: colors.cardColor,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: primaryColor.withOpacity(0.3),
                                width: 1,
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        'Status: $status',
                                        style: TextStyle(
                                          color: colors.textColor,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    if (canRestart)
                                      TextButton.icon(
                                        onPressed: _isStarting
                                            ? null
                                            : () => _startAndOpenEvaluation(
                                                  sessionId: sessionId,
                                                ),
                                        icon: const Icon(Icons.restart_alt),
                                        label: const Text('Restart'),
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  'Attempted: $attempted/$total  |  Correct: $correct  |  Incorrect: $incorrect  |  Skipped: $skipped',
                                  style: TextStyle(
                                    color: colors.hintColor,
                                    fontSize: 12,
                                  ),
                                ),
                                if (createdAtText.isNotEmpty) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    'Created: $createdAtText',
                                    style: TextStyle(
                                      color: colors.hintColor,
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          );
                        }).toList(),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
