import 'dart:convert';
import 'dart:typed_data';
import 'package:excel/excel.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../common/models/question_model.dart';
import '../../common/models/screen_args_model.dart';
import '../../common/providers/student_provider.dart';
import '../../common/services/app_snackbar_service.dart';
import '../../common/widgets/common_gradient_header_widget.dart';
import '../../common/widgets/custom_button.dart';
import '../providers/auth_service_provider.dart';
import '../providers/theme_provider.dart';

class UploadQuestionsScreen extends ConsumerStatefulWidget {
  final ScreenArgsModel args;

  const UploadQuestionsScreen({required this.args, super.key});

  @override
  ConsumerState<UploadQuestionsScreen> createState() =>
      _UploadQuestionsScreenState();
}

class _UploadQuestionsScreenState extends ConsumerState<UploadQuestionsScreen> {
  bool _isParsing = false;
  bool _isSubmitting = false;
  String? _fileName;
  List<String> _headers = [];
  List<Map<String, String>> _rows = [];

  @override
  Widget build(BuildContext context) {
    final colors = ref.watch(themeColorsProvider);
    final primaryColor = ref.watch(primaryColorProvider);
    final isAdminUser = ref.watch(authProvider)?.data.isAdmin == true;

    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            CommonGradientHeader(title: widget.args.name),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                  //border: Border.all(color: Colors.orange.withOpacity(0.4)),
                ),
                child: const Text(
                  'Staging Feature: Bulk upload is under construction. Current version supports CSV and basic Excel preview/import.',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ),
            if (!isAdminUser)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: colors.cardColor,
                    borderRadius: BorderRadius.circular(12),
                    //border: Border.all(color: Colors.red.withOpacity(0.4)),
                  ),
                  child: Text(
                    'You do not have permission to upload questions. Admin access is required.',
                    style: TextStyle(color: colors.textColor),
                  ),
                ),
              ),
            if (isAdminUser) ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: colors.cardColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Accepted columns',
                        style: TextStyle(
                          color: colors.textColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'question_text (required), question_mode, options_csv, correct_answer, display_letter, hint, difficulty, sort_order, question_set_id',
                        style: TextStyle(color: colors.hintColor, fontSize: 12),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: CustomPrimaryButton(
                              label: _isParsing ? 'Parsing...' : 'Select File',
                              onPressed: (_isParsing || _isSubmitting)
                                  ? null
                                  : _pickAndParseFile,
                              isLoading: _isParsing,
                              primaryColor: primaryColor,
                              height: 48,
                            ),
                          ),
                          const SizedBox(width: 12),
                          SizedBox(
                            width: 120,
                            child: CustomSecondaryButton(
                              label: 'Clear',
                              onPressed: (_isParsing || _isSubmitting)
                                  ? null
                                  : _clearData,
                              primaryColor: primaryColor,
                              textColor: colors.textColor,
                              height: 48,
                            ),
                          ),
                        ],
                      ),
                      if (_fileName != null) ...[
                        const SizedBox(height: 12),
                        Text(
                          'Selected: $_fileName',
                          style: TextStyle(
                            color: colors.textColor,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              if (_rows.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: colors.cardColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Preview (${_rows.length} rows)',
                          style: TextStyle(
                            color: colors.textColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 10),
                        SizedBox(
                          height: 340,
                          child: Scrollbar(
                            thumbVisibility: true,
                            child: SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: SingleChildScrollView(
                                child: DataTable(
                                  columns: _headers
                                      .map((header) => DataColumn(
                                            label: Text(
                                              header,
                                              style: TextStyle(
                                                color: colors.textColor,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ))
                                      .toList(),
                                  rows: _rows
                                      .map(
                                        (row) => DataRow(
                                          cells: _headers
                                              .map(
                                                (header) => DataCell(
                                                  SizedBox(
                                                    width: 180,
                                                    child: Text(
                                                      row[header] ?? '',
                                                      maxLines: 2,
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                      style: TextStyle(
                                                        color: colors.textColor,
                                                        fontSize: 12,
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              )
                                              .toList(),
                                        ),
                                      )
                                      .toList(),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              if (_rows.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: CustomPrimaryButton(
                    label: _isSubmitting
                        ? 'Submitting...'
                        : 'Submit Question Paper',
                    onPressed: _isSubmitting ? null : _submitQuestions,
                    isLoading: _isSubmitting,
                    primaryColor: primaryColor,
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _pickAndParseFile() async {
    setState(() => _isParsing = true);
    try {
      final picked = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv', 'xlsx', 'xls'],
        withData: true,
      );

      if (picked == null || picked.files.isEmpty) {
        return;
      }

      final file = picked.files.single;
      final fileBytes = file.bytes;
      final extension = (file.extension ?? '').toLowerCase();

      if (fileBytes == null) {
        AppSnackbarService.error('Could not read file bytes.');
        return;
      }

      ParsedTable parsed;
      if (extension == 'csv') {
        parsed = _parseCsv(Uint8List.fromList(fileBytes));
      } else if (extension == 'xlsx' || extension == 'xls') {
        parsed = _parseExcel(Uint8List.fromList(fileBytes));
      } else {
        AppSnackbarService.error('Unsupported format. Use CSV or Excel.');
        return;
      }

      if (parsed.headers.isEmpty || parsed.rows.isEmpty) {
        AppSnackbarService.error(
          'No valid rows found. Ensure required column `question_text` is present.',
        );
        return;
      }

      setState(() {
        _fileName = file.name;
        _headers = parsed.headers;
        _rows = parsed.rows;
      });
      AppSnackbarService.success('Parsed ${parsed.rows.length} rows.');
    } catch (e) {
      AppSnackbarService.error('Failed to parse file: $e');
    } finally {
      if (mounted) {
        setState(() => _isParsing = false);
      }
    }
  }

  ParsedTable _parseCsv(Uint8List bytes) {
    final text = utf8.decode(bytes, allowMalformed: true);
    final lines = const LineSplitter()
        .convert(text)
        .where((line) => line.trim().isNotEmpty)
        .toList();

    if (lines.isEmpty) {
      return const ParsedTable(headers: [], rows: []);
    }

    final headers = _parseCsvLine(lines.first)
        .map(_normalizeHeader)
        .where((h) => h.isNotEmpty)
        .toList();

    final rows = <Map<String, String>>[];
    for (int i = 1; i < lines.length; i++) {
      final fields = _parseCsvLine(lines[i]);
      if (fields.every((e) => e.trim().isEmpty)) {
        continue;
      }

      final row = <String, String>{};
      for (int j = 0; j < headers.length; j++) {
        row[headers[j]] = j < fields.length ? fields[j].trim() : '';
      }
      if ((row['question_text'] ?? '').trim().isNotEmpty) {
        rows.add(row);
      }
    }

    return ParsedTable(headers: headers, rows: rows);
  }

  List<String> _parseCsvLine(String line) {
    final out = <String>[];
    final current = StringBuffer();
    bool inQuotes = false;

    for (int i = 0; i < line.length; i++) {
      final char = line[i];
      if (char == '"') {
        if (inQuotes && i + 1 < line.length && line[i + 1] == '"') {
          current.write('"');
          i++;
        } else {
          inQuotes = !inQuotes;
        }
      } else if (char == ',' && !inQuotes) {
        out.add(current.toString());
        current.clear();
      } else {
        current.write(char);
      }
    }
    out.add(current.toString());
    return out;
  }

  ParsedTable _parseExcel(Uint8List bytes) {
    final excel = Excel.decodeBytes(bytes);
    if (excel.tables.isEmpty) {
      return const ParsedTable(headers: [], rows: []);
    }

    final sheet = excel.tables.values.first;
    if (sheet == null || sheet.rows.isEmpty) {
      return const ParsedTable(headers: [], rows: []);
    }

    final headers = sheet.rows.first
        .map((cell) => _normalizeHeader(cell?.value?.toString() ?? ''))
        .where((h) => h.isNotEmpty)
        .toList();

    final rows = <Map<String, String>>[];
    for (int i = 1; i < sheet.rows.length; i++) {
      final excelRow = sheet.rows[i];
      final row = <String, String>{};
      for (int j = 0; j < headers.length; j++) {
        row[headers[j]] =
            j < excelRow.length ? (excelRow[j]?.value?.toString() ?? '') : '';
      }
      if ((row['question_text'] ?? '').trim().isNotEmpty) {
        rows.add(row);
      }
    }

    return ParsedTable(headers: headers, rows: rows);
  }

  String _normalizeHeader(String header) {
    return header.trim().toLowerCase().replaceAll(' ', '_');
  }

  Future<void> _submitQuestions() async {
    if (_rows.isEmpty) {
      AppSnackbarService.error('No data to submit.');
      return;
    }

    setState(() => _isSubmitting = true);
    int successCount = 0;
    int failCount = 0;
    String? firstError;

    try {
      final service = ref.read(eduServiceProvider);
      for (final row in _rows) {
        final question = Question(
          questionText: (row['question_text'] ?? '').trim(),
          questionMode:
              (row['question_mode'] ?? 'LETTER_SOUND_MCQ').trim().isEmpty
                  ? 'LETTER_SOUND_MCQ'
                  : (row['question_mode'] ?? 'LETTER_SOUND_MCQ').trim(),
          optionsCsv: (row['options_csv'] ?? '').trim().isEmpty
              ? null
              : row['options_csv']!.trim(),
          correctAnswer: (row['correct_answer'] ?? '').trim().isEmpty
              ? null
              : row['correct_answer']!.trim(),
          displayLetter: (row['display_letter'] ?? '').trim().isEmpty
              ? null
              : row['display_letter']!.trim(),
          hint: (row['hint'] ?? '').trim().isEmpty ? null : row['hint']!.trim(),
          difficulty: int.tryParse((row['difficulty'] ?? '1').trim()) ?? 1,
          sortOrder: int.tryParse((row['sort_order'] ?? '0').trim()) ?? 0,
          questionSetId: int.tryParse((row['question_set_id'] ?? '').trim()),
        );

        final response = await service.saveQuestion(question);
        if (response.isSuccess) {
          successCount++;
        } else {
          failCount++;
          firstError ??= response.message;
        }
      }

      if (failCount == 0) {
        AppSnackbarService.success(
          'Uploaded $successCount questions successfully.',
        );
      } else {
        AppSnackbarService.error(
          'Uploaded: $successCount, Failed: $failCount. ${firstError ?? ''}',
        );
      }
    } catch (e) {
      AppSnackbarService.error('Submit failed: $e');
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  void _clearData() {
    setState(() {
      _fileName = null;
      _headers = [];
      _rows = [];
    });
  }
}

class ParsedTable {
  final List<String> headers;
  final List<Map<String, String>> rows;

  const ParsedTable({required this.headers, required this.rows});
}
