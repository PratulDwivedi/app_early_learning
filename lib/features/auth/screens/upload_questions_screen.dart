import 'dart:convert';
import 'dart:typed_data';
import 'package:excel/excel.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
            const SizedBox(height: 10),
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
                        'name or question_text (required), question_type_id, name_audio_prompt, options/options_csv, options_audio_prompt, correct_answer, hint, image_url, sort_order, difficulty, points',
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
                                      .map(
                                        (header) => DataColumn(
                                          label: Text(
                                            header,
                                            style: TextStyle(
                                              color: colors.textColor,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      )
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
          'No valid rows found. Ensure `name` or `question_text` is present.',
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

    final headers = _parseCsvLine(
      lines.first,
    ).map(_normalizeHeader).where((h) => h.isNotEmpty).toList();

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
      if (_rowHasQuestionText(row)) {
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
    if (sheet.rows.isEmpty) {
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
        row[headers[j]] = j < excelRow.length
            ? (excelRow[j]?.value?.toString() ?? '')
            : '';
      }
      if (_rowHasQuestionText(row)) {
        rows.add(row);
      }
    }

    return ParsedTable(headers: headers, rows: rows);
  }

  String _normalizeHeader(String header) {
    return header.trim().toLowerCase().replaceAll(' ', '_');
  }

  bool _rowHasQuestionText(Map<String, String> row) {
    return (row['name'] ?? '').trim().isNotEmpty ||
        (row['question_text'] ?? '').trim().isNotEmpty;
  }

  int _parseIntOrDefault(String? value, int defaultValue) {
    return int.tryParse((value ?? '').trim()) ?? defaultValue;
  }

  String? _readNonEmpty(Map<String, String> row, List<String> keys) {
    for (final key in keys) {
      final value = (row[key] ?? '').trim();
      if (value.isNotEmpty) {
        return value;
      }
    }
    return null;
  }

  Map<String, dynamic> _toRpcQuestion(Map<String, String> row, int index) {
    final name =
        _readNonEmpty(row, ['name', 'question_text', 'question']) ?? '';
    final options =
        _readNonEmpty(row, ['options', 'options_csv', 'choices']) ?? '';
    final difficulty =
        _readNonEmpty(row, ['difficulty'])?.toLowerCase() ?? 'easy';
    final points = _parseIntOrDefault(row['points'], 10);
    final sortOrder = _parseIntOrDefault(row['sort_order'], index + 1);
    final questionTypeId = _parseIntOrDefault(row['question_type_id'], 1);
    final nameAudioPrompt = _readNonEmpty(row, ['name_audio_prompt']);
    final optionsAudioPrompt = _readNonEmpty(row, ['options_audio_prompt']);
    final correctAnswer = _readNonEmpty(row, ['correct_answer']) ?? '';
    final hint = _readNonEmpty(row, ['hint']);
    final imageUrl = _readNonEmpty(row, ['image_url']);

    return {
      'question_type_id': questionTypeId,
      'name': name,
      if (nameAudioPrompt != null) 'name_audio_prompt': nameAudioPrompt,
      'options': options,
      if (optionsAudioPrompt != null)
        'options_audio_prompt': optionsAudioPrompt,
      'correct_answer': correctAnswer,
      if (hint != null) 'hint': hint,
      if (imageUrl != null) 'image_url': imageUrl,
      'sort_order': sortOrder,
      'data': {'difficulty': difficulty, 'points': points},
    };
  }

  Future<void> _submitQuestions() async {
    if (_rows.isEmpty) {
      AppSnackbarService.error('No data to submit.');
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      final service = ref.read(eduServiceProvider);
      final rpcQuestions = <Map<String, dynamic>>[];
      for (int i = 0; i < _rows.length; i++) {
        if (_rowHasQuestionText(_rows[i])) {
          rpcQuestions.add(_toRpcQuestion(_rows[i], i));
        }
      }

      if (rpcQuestions.isEmpty) {
        AppSnackbarService.error(
          'No valid questions found. Ensure each row has `name` or `question_text`.',
        );
        return;
      }

      final response = await service.saveQuestions(rpcQuestions);
      if (response.isSuccess) {
        AppSnackbarService.success(
          'Uploaded ${rpcQuestions.length} questions successfully.',
        );
      } else {
        AppSnackbarService.error('Upload failed: ${response.message}');
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
