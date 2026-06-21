import 'dart:convert';
import 'dart:typed_data';

import 'calculator.dart';
import 'models.dart';

enum ReportExportFormat { pdf, excel }

class ReportExporter {
  const ReportExporter();

  Future<Uint8List> buildPdf(ReportData data) async {
    final options = data.options;
    const calculator = RgtCalculator();
    final lines = <_PdfLine>[
      const _PdfLine('SISTEMA RGT', size: 18, bold: true, gapAfter: 5),
      const _PdfLine('Relatório financeiro', size: 13, bold: true),
      _PdfLine('Competência: ${_monthLabel(options.competence)}'),
      _PdfLine(
        'Período: ${_dateLabel(options.startDate)} a ${_dateLabel(options.endDate)}',
      ),
      _PdfLine('Banca: ${options.unit?.label ?? 'Todas as bancas'}'),
      _PdfLine('Gerado em: ${_dateTimeLabel(data.generatedAt)}', gapAfter: 8),
    ];

    if (options.includeGeneralCashClosing) {
      final closing = _closingSummary(data.cashClosings);
      lines.addAll([
        const _PdfLine('FECHAMENTO DE CAIXA GERAL',
            size: 12, bold: true, gapBefore: 5),
        _PdfLine('Caixa positivo: ${_currency(closing.positive)}'),
        _PdfLine('Caixa negativo: ${_currency(closing.negative)}'),
        _PdfLine('Fechamento parcial: ${_currency(closing.balance)}'),
        _PdfLine(
          'Desconto em folha: ${_currency(closing.payrollDeductions)}',
          gapAfter: 7,
        ),
      ]);
    }

    if (options.includeFinancialStatement) {
      lines.add(const _PdfLine('DEMONSTRATIVOS MENSAIS',
          size: 12, bold: true, gapBefore: 5));
      for (final employee in options.selectedEmployees) {
        final statement = data.statements[employee.id] ??
            _emptyForReport(employee, options.competence);
        final summary = calculator.calculate(
          statement,
          cashClosings: data.cashClosings,
          startDate: options.startDate,
          today: options.endDate,
          restrictCashClosingsToStatementUnit: false,
        );
        lines.addAll([
          _PdfLine('${employee.name} - ${employee.unit.label}',
              bold: true, gapBefore: 5),
          _PdfLine('Receitas: ${_currency(summary.revenues)}'),
          _PdfLine('Despesas: ${_currency(summary.expenses)}'),
          _PdfLine(
              'Desconto por faltas: ${_currency(summary.absenceDiscount)}'),
          _PdfLine(
            'Fechamento parcial: ${_currency(summary.partialCashClosing)}',
          ),
          _PdfLine('Passivo final: ${_currency(summary.finalLiability)}',
              bold: true, gapAfter: 5),
        ]);
      }
    }

    if (options.includeEmployeeCashClosing) {
      lines.add(const _PdfLine('FECHAMENTOS POR COLABORADOR',
          size: 12, bold: true, gapBefore: 7));
      for (final employee in options.selectedEmployees) {
        final entries = data.cashClosings
            .where((entry) => entry.employee.id == employee.id)
            .toList();
        lines.add(_PdfLine('${employee.name} - ${employee.unit.label}',
            bold: true, gapBefore: 5));
        if (entries.isEmpty) {
          lines.add(const _PdfLine('Nenhum fechamento no período.'));
        } else {
          for (final entry in entries) {
            lines.addAll(
              _wrapPdfLine(
                '${_dateLabel(entry.date)} | ${entry.type.label} | '
                '${_currency(entry.amount)} | ${entry.description}',
              ),
            );
          }
        }
      }
    }

    return _SimplePdfBuilder(lines).build();
  }

  List<int> buildExcel(ReportData data) {
    final options = data.options;
    const calculator = RgtCalculator();
    final closing = _closingSummary(data.cashClosings);
    final summaryRows = <List<_ExcelCell>>[
      [_ExcelCell.text('SISTEMA RGT - RELATÓRIO FINANCEIRO', style: 3)],
      [
        _ExcelCell.text('Competência', style: 1),
        _ExcelCell.text(_monthLabel(options.competence))
      ],
      [
        _ExcelCell.text('Período', style: 1),
        _ExcelCell.text(
            '${_dateLabel(options.startDate)} a ${_dateLabel(options.endDate)}'),
      ],
      [
        _ExcelCell.text('Banca', style: 1),
        _ExcelCell.text(options.unit?.label ?? 'Todas as bancas')
      ],
      [
        _ExcelCell.text('Gerado em', style: 1),
        _ExcelCell.text(_dateTimeLabel(data.generatedAt))
      ],
      const [],
      [
        _ExcelCell.text('Indicador', style: 1),
        _ExcelCell.text('Valor', style: 1)
      ],
      [
        _ExcelCell.text('Caixa positivo'),
        _ExcelCell.number(closing.positive, style: 2)
      ],
      [
        _ExcelCell.text('Caixa negativo'),
        _ExcelCell.number(closing.negative, style: 2)
      ],
      [
        _ExcelCell.text('Fechamento parcial'),
        _ExcelCell.number(closing.balance, style: 2)
      ],
      [
        _ExcelCell.text('Desconto em folha'),
        _ExcelCell.number(closing.payrollDeductions, style: 2)
      ],
    ];

    final statementRows = <List<_ExcelCell>>[
      [
        for (final title in const [
          'Competência',
          'Colaborador',
          'Banca',
          'Previsão de lançamento',
          'Vales',
          'Faltas com despesa',
          'Pontuação de assiduidade',
          'Incentivo',
          'Receitas',
          'Despesas',
          'Fechamento parcial',
          'Passivo final',
        ])
          _ExcelCell.text(title, style: 1),
      ],
    ];
    for (final employee in options.selectedEmployees) {
      final statement = data.statements[employee.id] ??
          _emptyForReport(employee, options.competence);
      final summary = calculator.calculate(
        statement,
        cashClosings: data.cashClosings,
        startDate: options.startDate,
        today: options.endDate,
        restrictCashClosingsToStatementUnit: false,
      );
      statementRows.add([
        _ExcelCell.text(_monthLabel(options.competence)),
        _ExcelCell.text(employee.name),
        _ExcelCell.text(employee.unit.label),
        _ExcelCell.number(statement.salaryForecast, style: 2),
        _ExcelCell.number(statement.vouchers, style: 2),
        _ExcelCell.number(statement.expenseAbsenceCount.toDouble()),
        _ExcelCell.number(statement.attendanceScore.toDouble()),
        _ExcelCell.number(statement.incentive?.amount ?? 0, style: 2),
        _ExcelCell.number(summary.revenues, style: 2),
        _ExcelCell.number(summary.expenses, style: 2),
        _ExcelCell.number(summary.partialCashClosing, style: 2),
        _ExcelCell.number(summary.finalLiability, style: 2),
      ]);
    }

    final closingRows = <List<_ExcelCell>>[
      [
        for (final title in const [
          'Data',
          'Banca',
          'Colaborador',
          'Tipo',
          'Valor',
          'Descrição',
          'Desconto em folha',
        ])
          _ExcelCell.text(title, style: 1),
      ],
      for (final entry in data.cashClosings)
        [
          _ExcelCell.text(_dateLabel(entry.date)),
          _ExcelCell.text(entry.unit.label),
          _ExcelCell.text(entry.employee.name),
          _ExcelCell.text(entry.type.label),
          _ExcelCell.number(entry.amount, style: 2),
          _ExcelCell.text(entry.description),
          _ExcelCell.text(entry.deductFromPayroll ? 'Sim' : 'Não'),
        ],
    ];

    return _SimpleXlsxBuilder([
      _ExcelSheet('Resumo', summaryRows),
      _ExcelSheet('Demonstrativos', statementRows),
      _ExcelSheet('Fechamentos', closingRows),
    ]).build();
  }

  static List<_PdfLine> _wrapPdfLine(String text) {
    const maxLength = 92;
    if (text.length <= maxLength) {
      return [_PdfLine(text)];
    }
    final words = text.split(' ');
    final lines = <_PdfLine>[];
    var current = '';
    for (final word in words) {
      final next = current.isEmpty ? word : '$current $word';
      if (next.length > maxLength && current.isNotEmpty) {
        lines.add(_PdfLine(current));
        current = word;
      } else {
        current = next;
      }
    }
    if (current.isNotEmpty) {
      lines.add(_PdfLine(current));
    }
    return lines;
  }

  static CashClosingSummary _closingSummary(
    List<CashClosingEntry> entries,
  ) {
    var positive = 0.0;
    var negative = 0.0;
    var deductions = 0.0;
    for (final entry in entries) {
      if (entry.type == CashClosingType.positive) {
        positive += entry.amount;
      } else {
        negative += entry.amount;
        if (entry.deductFromPayroll) {
          deductions += entry.amount;
        }
      }
    }
    return CashClosingSummary(
      positive: positive,
      negative: negative,
      payrollDeductions: deductions,
    );
  }

  static MonthlyStatement _emptyForReport(
    Employee employee,
    DateTime competence,
  ) {
    return MonthlyStatement(
      employee: employee,
      referenceMonth: DateTime(competence.year, competence.month),
      salaryForecast: 0,
      vouchers: 0,
      absences: const [],
      attendanceScore: 0,
      incentive: null,
      balanceBonus: 0,
      launchBalanceBonusAsRevenue: false,
      negativeCashEntries: const [],
      launchNegativeCashAsExpense: false,
    );
  }

  static String _currency(double value) => formatCurrency(value);
  static String _dateLabel(DateTime value) => formatDate(value);
  static String _monthLabel(DateTime value) =>
      '${value.month.toString().padLeft(2, '0')}/${value.year}';

  static String _dateTimeLabel(DateTime value) {
    final hour = value.hour.toString().padLeft(2, '0');
    final minute = value.minute.toString().padLeft(2, '0');
    return '${_dateLabel(value)} às $hour:$minute';
  }
}

class _PdfLine {
  const _PdfLine(
    this.text, {
    this.size = 10,
    this.bold = false,
    this.gapBefore = 0,
    this.gapAfter = 2,
  });

  final String text;
  final double size;
  final bool bold;
  final double gapBefore;
  final double gapAfter;
}

class _SimplePdfBuilder {
  const _SimplePdfBuilder(this.lines);

  final List<_PdfLine> lines;

  Uint8List build() {
    final pages = <List<_PdfLine>>[];
    var page = <_PdfLine>[];
    var usedHeight = 0.0;
    for (final line in lines) {
      final height = line.gapBefore + line.size + line.gapAfter + 3;
      if (usedHeight + height > 700 && page.isNotEmpty) {
        pages.add(page);
        page = <_PdfLine>[];
        usedHeight = 0;
      }
      page.add(line);
      usedHeight += height;
    }
    if (page.isNotEmpty || pages.isEmpty) {
      pages.add(page);
    }

    final objects = <int, List<int>>{};
    final pageObjectIds = <int>[];
    for (var index = 0; index < pages.length; index++) {
      pageObjectIds.add(5 + index * 2);
    }
    objects[1] = _latin1('<< /Type /Catalog /Pages 2 0 R >>');
    objects[2] = _latin1(
      '<< /Type /Pages /Count ${pages.length} /Kids '
      '[${pageObjectIds.map((id) => '$id 0 R').join(' ')}] >>',
    );
    objects[3] = _latin1(
      '<< /Type /Font /Subtype /Type1 /BaseFont /Helvetica '
      '/Encoding /WinAnsiEncoding >>',
    );
    objects[4] = _latin1(
      '<< /Type /Font /Subtype /Type1 /BaseFont /Helvetica-Bold '
      '/Encoding /WinAnsiEncoding >>',
    );

    for (var index = 0; index < pages.length; index++) {
      final pageId = pageObjectIds[index];
      final contentId = pageId + 1;
      final content = _pageContent(pages[index], index + 1, pages.length);
      objects[pageId] = _latin1(
        '<< /Type /Page /Parent 2 0 R /MediaBox [0 0 595 842] '
        '/Resources << /Font << /F1 3 0 R /F2 4 0 R >> >> '
        '/Contents $contentId 0 R >>',
      );
      objects[contentId] = [
        ..._latin1('<< /Length ${content.length} >>\nstream\n'),
        ...content,
        ..._latin1('\nendstream'),
      ];
    }

    final output = BytesBuilder();
    output.add(_latin1('%PDF-1.4\n%âãÏÓ\n'));
    final offsets = <int>[0];
    final objectCount = objects.length;
    for (var id = 1; id <= objectCount; id++) {
      offsets.add(output.length);
      output.add(_latin1('$id 0 obj\n'));
      output.add(objects[id]!);
      output.add(_latin1('\nendobj\n'));
    }
    final xrefOffset = output.length;
    output.add(_latin1('xref\n0 ${objectCount + 1}\n'));
    output.add(_latin1('0000000000 65535 f \n'));
    for (var id = 1; id <= objectCount; id++) {
      output.add(
          _latin1('${offsets[id].toString().padLeft(10, '0')} 00000 n \n'));
    }
    output.add(_latin1(
      'trailer\n<< /Size ${objectCount + 1} /Root 1 0 R >>\n'
      'startxref\n$xrefOffset\n%%EOF\n',
    ));
    return output.takeBytes();
  }

  List<int> _pageContent(List<_PdfLine> page, int number, int total) {
    final buffer = StringBuffer();
    var y = 800.0;
    for (final line in page) {
      y -= line.gapBefore;
      final font = line.bold ? 'F2' : 'F1';
      buffer
        ..write('BT /$font ${line.size.toStringAsFixed(1)} Tf ')
        ..write('1 0 0 1 48 ${y.toStringAsFixed(1)} Tm ')
        ..write('(${_pdfEscape(line.text)}) Tj ET\n');
      y -= line.size + line.gapAfter + 3;
    }
    buffer.write(
      'BT /F1 8 Tf 1 0 0 1 470 24 Tm '
      '(Página $number de $total) Tj ET\n',
    );
    return _latin1(buffer.toString());
  }

  static String _pdfEscape(String value) {
    return value
        .replaceAll('\\', '\\\\')
        .replaceAll('(', '\\(')
        .replaceAll(')', '\\)');
  }

  static List<int> _latin1(String value) {
    return latin1.encode(
      value.replaceAllMapped(
        RegExp(r'[^\x00-\xFF]'),
        (_) => '?',
      ),
    );
  }
}

class _ExcelSheet {
  const _ExcelSheet(this.name, this.rows);

  final String name;
  final List<List<_ExcelCell>> rows;
}

class _ExcelCell {
  const _ExcelCell._(this.value, this.numeric, this.style);

  factory _ExcelCell.text(String value, {int style = 0}) =>
      _ExcelCell._(value, false, style);
  factory _ExcelCell.number(double value, {int style = 0}) =>
      _ExcelCell._(value, true, style);

  final Object value;
  final bool numeric;
  final int style;
}

class _SimpleXlsxBuilder {
  const _SimpleXlsxBuilder(this.sheets);

  final List<_ExcelSheet> sheets;

  List<int> build() {
    final files = <String, List<int>>{
      '[Content_Types].xml': utf8.encode(_contentTypes()),
      '_rels/.rels': utf8.encode(_rootRelationships),
      'xl/workbook.xml': utf8.encode(_workbook()),
      'xl/_rels/workbook.xml.rels': utf8.encode(_workbookRelationships()),
      'xl/styles.xml': utf8.encode(_styles),
    };
    for (var index = 0; index < sheets.length; index++) {
      files['xl/worksheets/sheet${index + 1}.xml'] =
          utf8.encode(_worksheet(sheets[index]));
    }
    return _ZipStore(files).build();
  }

  String _contentTypes() {
    final sheetsXml = List.generate(
      sheets.length,
      (index) => '<Override PartName="/xl/worksheets/sheet${index + 1}.xml" '
          'ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.worksheet+xml"/>',
    ).join();
    return '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
        '<Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">'
        '<Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/>'
        '<Default Extension="xml" ContentType="application/xml"/>'
        '<Override PartName="/xl/workbook.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.sheet.main+xml"/>'
        '<Override PartName="/xl/styles.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.styles+xml"/>'
        '$sheetsXml</Types>';
  }

  String _workbook() {
    final sheetXml = List.generate(
      sheets.length,
      (index) =>
          '<sheet name="${_xmlEscape(sheets[index].name)}" sheetId="${index + 1}" r:id="rId${index + 2}"/>',
    ).join();
    return '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
        '<workbook xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main" '
        'xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships">'
        '<sheets>$sheetXml</sheets></workbook>';
  }

  String _workbookRelationships() {
    final sheetRelationships = List.generate(
      sheets.length,
      (index) => '<Relationship Id="rId${index + 2}" '
          'Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/worksheet" '
          'Target="worksheets/sheet${index + 1}.xml"/>',
    ).join();
    return '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
        '<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">'
        '<Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/styles" Target="styles.xml"/>'
        '$sheetRelationships</Relationships>';
  }

  String _worksheet(_ExcelSheet sheet) {
    final rows = StringBuffer();
    for (var rowIndex = 0; rowIndex < sheet.rows.length; rowIndex++) {
      final rowNumber = rowIndex + 1;
      rows.write('<row r="$rowNumber">');
      final row = sheet.rows[rowIndex];
      for (var columnIndex = 0; columnIndex < row.length; columnIndex++) {
        final cell = row[columnIndex];
        final reference = '${_columnName(columnIndex)}$rowNumber';
        if (cell.numeric) {
          rows.write(
            '<c r="$reference" s="${cell.style}"><v>${cell.value}</v></c>',
          );
        } else {
          rows.write(
            '<c r="$reference" t="inlineStr" s="${cell.style}"><is><t xml:space="preserve">'
            '${_xmlEscape(cell.value.toString())}</t></is></c>',
          );
        }
      }
      rows.write('</row>');
    }
    return '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
        '<worksheet xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main">'
        '<cols><col min="1" max="20" width="22" customWidth="1"/></cols>'
        '<sheetData>$rows</sheetData></worksheet>';
  }

  static String _columnName(int index) {
    var value = index + 1;
    var result = '';
    while (value > 0) {
      final remainder = (value - 1) % 26;
      result = String.fromCharCode(65 + remainder) + result;
      value = (value - 1) ~/ 26;
    }
    return result;
  }

  static String _xmlEscape(String value) {
    return value
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;')
        .replaceAll("'", '&apos;');
  }

  static const _rootRelationships =
      '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
      '<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">'
      '<Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument" Target="xl/workbook.xml"/>'
      '</Relationships>';

  static const _styles =
      '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
      '<styleSheet xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main">'
      '<numFmts count="1"><numFmt numFmtId="164" formatCode="R\$ #,##0.00;[Red]-R\$ #,##0.00"/></numFmts>'
      '<fonts count="2"><font><sz val="11"/><name val="Calibri"/></font>'
      '<font><b/><color rgb="FFFFFFFF"/><sz val="11"/><name val="Calibri"/></font></fonts>'
      '<fills count="3"><fill><patternFill patternType="none"/></fill>'
      '<fill><patternFill patternType="gray125"/></fill>'
      '<fill><patternFill patternType="solid"><fgColor rgb="FF245B57"/><bgColor indexed="64"/></patternFill></fill></fills>'
      '<borders count="1"><border><left/><right/><top/><bottom/><diagonal/></border></borders>'
      '<cellStyleXfs count="1"><xf numFmtId="0" fontId="0" fillId="0" borderId="0"/></cellStyleXfs>'
      '<cellXfs count="4">'
      '<xf numFmtId="0" fontId="0" fillId="0" borderId="0" xfId="0"/>'
      '<xf numFmtId="0" fontId="1" fillId="2" borderId="0" xfId="0" applyFill="1" applyFont="1"/>'
      '<xf numFmtId="164" fontId="0" fillId="0" borderId="0" xfId="0" applyNumberFormat="1"/>'
      '<xf numFmtId="0" fontId="1" fillId="2" borderId="0" xfId="0" applyFill="1" applyFont="1"/>'
      '</cellXfs>'
      '<cellStyles count="1"><cellStyle name="Normal" xfId="0" builtinId="0"/></cellStyles>'
      '<dxfs count="0"/>'
      '<tableStyles count="0" defaultTableStyle="TableStyleMedium2" defaultPivotStyle="PivotStyleLight16"/>'
      '</styleSheet>';
}

class _ZipStore {
  const _ZipStore(this.files);

  final Map<String, List<int>> files;

  List<int> build() {
    final output = BytesBuilder();
    final records = <_ZipRecord>[];
    for (final entry in files.entries) {
      final name = utf8.encode(entry.key);
      final data = entry.value;
      final crc = _crc32(data);
      final offset = output.length;
      output.add(_littleEndian([
        [0x04034B50, 4],
        [20, 2],
        [0, 2],
        [0, 2],
        [0, 2],
        [0, 2],
        [crc, 4],
        [data.length, 4],
        [data.length, 4],
        [name.length, 2],
        [0, 2],
      ]));
      output.add(name);
      output.add(data);
      records.add(_ZipRecord(name, data.length, crc, offset));
    }

    final centralOffset = output.length;
    for (final record in records) {
      output.add(_littleEndian([
        [0x02014B50, 4],
        [20, 2],
        [20, 2],
        [0, 2],
        [0, 2],
        [0, 2],
        [0, 2],
        [record.crc, 4],
        [record.size, 4],
        [record.size, 4],
        [record.name.length, 2],
        [0, 2],
        [0, 2],
        [0, 2],
        [0, 2],
        [0, 4],
        [record.offset, 4],
      ]));
      output.add(record.name);
    }
    final centralSize = output.length - centralOffset;
    output.add(_littleEndian([
      [0x06054B50, 4],
      [0, 2],
      [0, 2],
      [records.length, 2],
      [records.length, 2],
      [centralSize, 4],
      [centralOffset, 4],
      [0, 2],
    ]));
    return output.takeBytes();
  }

  static List<int> _littleEndian(List<List<int>> values) {
    final bytes = BytesBuilder();
    for (final value in values) {
      final number = value[0];
      final width = value[1];
      for (var index = 0; index < width; index++) {
        bytes.addByte((number >> (8 * index)) & 0xFF);
      }
    }
    return bytes.takeBytes();
  }

  static int _crc32(List<int> data) {
    var crc = 0xFFFFFFFF;
    for (final byte in data) {
      crc ^= byte;
      for (var bit = 0; bit < 8; bit++) {
        crc = (crc & 1) != 0 ? (crc >> 1) ^ 0xEDB88320 : crc >> 1;
      }
    }
    return (crc ^ 0xFFFFFFFF) & 0xFFFFFFFF;
  }
}

class _ZipRecord {
  const _ZipRecord(this.name, this.size, this.crc, this.offset);

  final List<int> name;
  final int size;
  final int crc;
  final int offset;
}
