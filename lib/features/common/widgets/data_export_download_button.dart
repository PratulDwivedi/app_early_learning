import 'dart:typed_data';

import 'package:excel/excel.dart' as xls;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../utils/download_helper.dart';
import '../services/app_snackbar_service.dart';

class ExportColumn {
  final String key;
  final String header;

  const ExportColumn({
    required this.key,
    required this.header,
  });
}

class DataExportDownloadButton extends StatefulWidget {
  final Future<List<Map<String, dynamic>>> Function() loadData;
  final String fileNamePrefix;
  final List<ExportColumn>? columns;
  final String tooltip;

  const DataExportDownloadButton({
    super.key,
    required this.loadData,
    required this.fileNamePrefix,
    this.columns,
    this.tooltip = 'Download as XLS',
  });

  @override
  State<DataExportDownloadButton> createState() =>
      _DataExportDownloadButtonState();
}

class _DataExportDownloadButtonState extends State<DataExportDownloadButton> {
  bool _isDownloading = false;

  Future<void> _download() async {
    if (_isDownloading) return;
    setState(() {
      _isDownloading = true;
    });

    try {
      final data = await widget.loadData();
      if (data.isEmpty) {
        AppSnackbarService.error('No data available to download.');
        return;
      }

      final columns = widget.columns ?? _inferColumns(data);
      if (columns.isEmpty) {
        AppSnackbarService.error('No exportable columns found.');
        return;
      }

      final excel = xls.Excel.createExcel();
      final sheet = excel['Data'];

      sheet.appendRow(
        columns
            .map<xls.CellValue?>((column) => xls.TextCellValue(column.header))
            .toList(),
      );

      for (final row in data) {
        sheet.appendRow(
          columns
              .map<xls.CellValue?>(
                (column) => xls.TextCellValue(
                  _stringify(row[column.key]),
                ),
              )
              .toList(),
        );
      }

      final bytes = excel.encode();
      if (bytes == null || bytes.isEmpty) {
        AppSnackbarService.error('Failed to generate XLS file.');
        return;
      }

      final fileName = '${_safeFileName(widget.fileNamePrefix)}.xlsx';
      final downloaded = await downloadBytes(
        bytes: Uint8List.fromList(bytes),
        fileName: fileName,
        mimeType:
            'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
      );

      if (!mounted) return;
      if (downloaded) {
        AppSnackbarService.success(
          kIsWeb ? 'Download started.' : 'Share dialog opened.',
        );
      } else {
        AppSnackbarService.error('Unable to export file on this device.');
      }
    } catch (error) {
      if (!mounted) return;
      AppSnackbarService.error('Failed to download: $error');
    } finally {
      if (!mounted) return;
      setState(() {
        _isDownloading = false;
      });
    }
  }

  List<ExportColumn> _inferColumns(List<Map<String, dynamic>> data) {
    if (data.isEmpty) return const <ExportColumn>[];
    final keys = data.first.keys.toList(growable: false);
    return keys
        .map(
          (key) => ExportColumn(
            key: key,
            header: key.replaceAll('_', ' ').trim(),
          ),
        )
        .toList(growable: false);
  }

  String _stringify(dynamic value) {
    if (value == null) return '';
    if (value is String) return value;
    if (value is num || value is bool) return value.toString();
    if (value is DateTime) return value.toIso8601String();
    return value.toString();
  }

  String _safeFileName(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return 'data';
    return trimmed.replaceAll(RegExp(r'[^A-Za-z0-9_-]'), '_');
  }

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: _isDownloading
          ? const SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Icon(Icons.download_rounded, size: 18),
      tooltip: widget.tooltip,
      onPressed: _isDownloading ? null : _download,
    );
  }
}
