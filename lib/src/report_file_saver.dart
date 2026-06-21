import 'package:file_selector/file_selector.dart';
import 'package:flutter/foundation.dart';

import 'models.dart';
import 'report_exporter.dart';

class ReportFileSaver {
  const ReportFileSaver();

  Future<String?> export(ReportData data, ReportExportFormat format) async {
    final extension = format == ReportExportFormat.pdf ? 'pdf' : 'xlsx';
    const exporter = ReportExporter();
    final bytes = format == ReportExportFormat.pdf
        ? await exporter.buildPdf(data)
        : Uint8List.fromList(exporter.buildExcel(data));
    final name = _fileName(data, extension);
    final mimeType = format == ReportExportFormat.pdf
        ? 'application/pdf'
        : 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';
    final file = XFile.fromData(bytes, mimeType: mimeType, name: name);

    if (defaultTargetPlatform == TargetPlatform.android) {
      final directory = await getDirectoryPath(
        confirmButtonText: 'Salvar relatório',
      );
      if (directory == null) {
        return null;
      }
      final path = '$directory/$name';
      await file.saveTo(path);
      return path;
    }

    final location = await getSaveLocation(
      suggestedName: name,
      acceptedTypeGroups: [
        XTypeGroup(
          label: format == ReportExportFormat.pdf ? 'PDF' : 'Excel',
          extensions: [extension],
        ),
      ],
    );
    if (location == null) {
      return null;
    }
    await file.saveTo(location.path);
    return location.path;
  }

  String _fileName(ReportData data, String extension) {
    final month = data.options.competence.month.toString().padLeft(2, '0');
    return 'relatorio-rgt-${data.options.competence.year}-$month.$extension';
  }
}
