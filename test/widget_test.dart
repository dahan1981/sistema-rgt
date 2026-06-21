import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:sistema_rgt/src/calculator.dart';
import 'package:sistema_rgt/src/app.dart';
import 'package:sistema_rgt/src/models.dart';
import 'package:sistema_rgt/src/initial_data.dart';
import 'package:sistema_rgt/src/report_exporter.dart';

MonthlyStatement _filledStatement(Employee employee) {
  return MonthlyStatement(
    employee: employee,
    referenceMonth: DateTime(2026, 6),
    salaryForecast: 2450,
    vouchers: 180,
    absences: [
      AbsenceEntry(date: DateTime(2026, 6, 10), asExpense: true),
    ],
    attendanceScore: 94,
    incentive: Incentive.score2,
    balanceBonus: 70,
    launchBalanceBonusAsRevenue: true,
    negativeCashEntries: const [],
    launchNegativeCashAsExpense: false,
  );
}

final _testCashClosings = [
  CashClosingEntry(
    id: 'cx-1',
    date: DateTime(2026, 6, 3),
    unit: Unit.laranj,
    employee: initialEmployees[0],
    type: CashClosingType.positive,
    amount: 84.50,
    description: 'Sobra de fechamento',
    deductFromPayroll: false,
  ),
  CashClosingEntry(
    id: 'cx-2',
    date: DateTime(2026, 6, 5),
    unit: Unit.laranj,
    employee: initialEmployees[1],
    type: CashClosingType.negative,
    amount: 42,
    description: 'Diferença no caixa',
    deductFromPayroll: true,
  ),
  CashClosingEntry(
    id: 'cx-3',
    date: DateTime(2026, 6, 8),
    unit: Unit.largoDoMachado,
    employee: initialEmployees[2],
    type: CashClosingType.positive,
    amount: 31.75,
    description: 'Ajuste de conferência',
    deductFromPayroll: false,
  ),
];

void main() {
  test('new monthly statements start without financial data', () {
    final statement = emptyStatement(
      initialEmployees.first,
      competence: DateTime(2026, 7),
    );

    expect(statement.salaryForecast, 0);
    expect(statement.vouchers, 0);
    expect(statement.absences, isEmpty);
    expect(statement.incentive, isNull);
    expect(statement.negativeCashEntries, isEmpty);
  });

  test('exports the same report data to PDF and Excel', () async {
    final employee = initialEmployees.first;
    final options = ReportOptions(
      includeFinancialStatement: true,
      includeGeneralCashClosing: true,
      includeEmployeeCashClosing: true,
      selectedEmployees: [employee],
      competence: DateTime(2026, 6),
      startDate: DateTime(2026, 6),
      endDate: DateTime(2026, 6, 30),
      unit: employee.unit,
    );
    final data = ReportData(
      options: options,
      statements: {employee.id: _filledStatement(employee)},
      cashClosings: [_testCashClosings.first],
      generatedAt: DateTime(2026, 6, 30, 12),
    );
    const exporter = ReportExporter();

    final pdf = await exporter.buildPdf(data);
    final excel = exporter.buildExcel(data);

    expect(String.fromCharCodes(pdf.take(4)), '%PDF');
    expect(latin1.decode(pdf, allowInvalid: true), contains('%%EOF'));
    expect(excel.take(2), [0x50, 0x4B]);
    expect(
      utf8.decode(excel, allowMalformed: true),
      allOf(contains('[Content_Types].xml'), contains('Demonstrativos')),
    );
  });

  test('cash closings feed financial summary', () {
    final employee = initialEmployees.first;
    final statement = _filledStatement(employee);
    final summary = const RgtCalculator().calculate(
      statement,
      today: DateTime(2026, 6, 8),
      cashClosings: [
        CashClosingEntry(
          id: 'positive',
          date: DateTime(2026, 6, 8),
          unit: employee.unit,
          employee: employee,
          type: CashClosingType.positive,
          amount: 200,
          description: 'Sobra',
          deductFromPayroll: false,
        ),
        CashClosingEntry(
          id: 'negative',
          date: DateTime(2026, 6, 8),
          unit: employee.unit,
          employee: employee,
          type: CashClosingType.negative,
          amount: 600,
          description: 'Falta',
          deductFromPayroll: true,
        ),
      ],
    );

    expect(summary.partialCashClosing, -400);
    expect(summary.payrollCashDiscount, 600);
  });

  test('cash closing calculation respects the selected report period', () {
    final employee = initialEmployees.first;
    final entries = [
      CashClosingEntry(
        id: 'inside',
        date: DateTime(2026, 5, 20),
        unit: employee.unit,
        employee: employee,
        type: CashClosingType.positive,
        amount: 90,
        description: 'No período',
        deductFromPayroll: false,
      ),
      CashClosingEntry(
        id: 'outside',
        date: DateTime(2026, 6, 1),
        unit: employee.unit,
        employee: employee,
        type: CashClosingType.positive,
        amount: 50,
        description: 'Fora do período',
        deductFromPayroll: false,
      ),
    ];

    final summary = const RgtCalculator().calculateCashClosingSummary(
      entries,
      employee: employee,
      startDate: DateTime(2026, 5, 1),
      today: DateTime(2026, 5, 31),
    );

    expect(summary.positive, 90);
  });

  testWidgets('renders RGT dashboard shell', (tester) async {
    await tester.pumpWidget(const SistemaRgtApp());

    expect(find.text('Sistema de RGT'), findsOneWidget);
    expect(find.text('Painel global'), findsOneWidget);
    expect(find.text('Filtro de banca'), findsOneWidget);
    expect(find.text('Filtro de colaborador'), findsOneWidget);
    expect(find.text('Passivo global'), findsOneWidget);
    expect(find.text('Todos os colaboradores'), findsWidgets);
  });

  testWidgets('monthly statement includes cash closing section',
      (tester) async {
    await tester.pumpWidget(const SistemaRgtApp());

    await tester.tap(find.text('Mensal'));
    await tester.pumpAndSettle();

    expect(find.text('Caixa'), findsNothing);
    await tester.scrollUntilVisible(
      find.text('Fechamento de caixa'),
      500,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Fechamento de caixa'), findsOneWidget);
    expect(find.text('Caixa positivo no mês'), findsOneWidget);
    expect(find.text('Descontar em folha'), findsOneWidget);
  });

  testWidgets('global cash closing page renders all collaborators',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CashClosingPage(
            employees: initialEmployees,
            entries: _testCashClosings,
            selectedUnit: Unit.geral,
            selectedEmployee: initialEmployees.first,
            onUnitSelected: (_) {},
            onEmployeeSelected: (_) {},
            effectiveUnitForDate: (employee, _) => employee.unit,
            onEntryAdded: (_) async {},
          ),
        ),
      ),
    );

    expect(find.text('Fechamento de caixa'), findsOneWidget);
    expect(find.text('Todos os colaboradores'), findsOneWidget);
    expect(find.text('Todos'), findsOneWidget);
    expect(find.text('R\$ 116,25'), findsOneWidget);
    expect(find.text('R\$ 42,00'), findsWidgets);
  });

  testWidgets('general collaborator filter shows all employees',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: EmployeesPage(
            employees: initialEmployees,
            unitAssignments: const [],
            selectedUnit: Unit.geral,
            selectedEmployee: initialEmployees.first,
            effectiveUnitForDate: (employee, _) => employee.unit,
            onUnitSelected: (_) {},
            onEmployeeSelected: (_) {},
            onEmployeeSaved: (_) async {},
            onUnitAssignmentAdded: (_) async {},
          ),
        ),
      ),
    );

    await tester.scrollUntilVisible(
      find.text('22 colaboradores em todos os colaboradores'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    expect(
      find.text('22 colaboradores em todos os colaboradores'),
      findsOneWidget,
    );
    expect(find.text('Daniele'), findsWidgets);
    await tester.scrollUntilVisible(
      find.text('Thais'),
      400,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Thais'), findsOneWidget);
  });

  testWidgets('collaborator page exposes editing and temporary unit history',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: EmployeesPage(
            employees: initialEmployees,
            unitAssignments: [
              UnitAssignment(
                id: 'temp-1',
                employeeId: initialEmployees.first.id,
                date: DateTime(2026, 6, 15),
                unit: Unit.ktt1,
              ),
            ],
            selectedUnit: Unit.geral,
            selectedEmployee: initialEmployees.first,
            effectiveUnitForDate: (employee, _) {
              return employee.id == initialEmployees.first.id
                  ? Unit.ktt1
                  : employee.unit;
            },
            onUnitSelected: (_) {},
            onEmployeeSelected: (_) {},
            onEmployeeSaved: (_) async {},
            onUnitAssignmentAdded: (_) async {},
          ),
        ),
      ),
    );

    expect(find.text('Cadastro do colaborador'), findsOneWidget);
    expect(find.text('Nome do colaborador'), findsOneWidget);
    expect(find.text('Banca efetiva hoje: KTT1'), findsOneWidget);
    expect(find.text('Lançar banca temporária'), findsOneWidget);
    expect(find.text('15/06/2026 - KTT1'), findsOneWidget);
  });

  testWidgets('selecting collaborator explains monthly navigation',
      (tester) async {
    await tester.pumpWidget(const SistemaRgtApp());

    await tester.tap(find.text('Equipe'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Kethelyn'),
      500,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Kethelyn').last);
    await tester.pumpAndSettle();

    expect(find.text('Demonstrativo mensal'), findsOneWidget);
    expect(
      find.text('Demonstrativo mensal aberto para Kethelyn.'),
      findsOneWidget,
    );
  });

  testWidgets('shows incentive score and calculated amount', (tester) async {
    await tester.pumpWidget(const SistemaRgtApp());

    await tester.tap(find.text('Mensal'));
    await tester.pumpAndSettle();

    expect(find.text('Pontuação de incentivo'), findsOneWidget);
    expect(find.text('Valor do incentivo'), findsOneWidget);
    expect(find.text('Selecione a pontuação'), findsOneWidget);
    expect(find.text('R\$ 0,00'), findsWidgets);
  });

  testWidgets('monthly statement omits removed compensation fields',
      (tester) async {
    await tester.pumpWidget(const SistemaRgtApp());

    await tester.tap(find.text('Mensal'));
    await tester.pumpAndSettle();

    expect(find.text('Domingo compensatório'), findsNothing);
    expect(find.text('Dobra'), findsNothing);
    expect(find.text('Caixa positivo'), findsNothing);
    expect(find.text('Bonificação e caixa'), findsOneWidget);
  });

  testWidgets('shows absence history with dates', (tester) async {
    await tester.pumpWidget(const SistemaRgtApp());

    await tester.tap(find.text('Mensal'));
    await tester.pumpAndSettle();

    expect(find.text('0 faltas registradas'), findsOneWidget);
    expect(find.text('Nenhuma falta lançada.'), findsOneWidget);
    expect(find.text('Lançar falta'), findsOneWidget);
    expect(find.text('Lançar esta falta como despesa'), findsOneWidget);
  });

  testWidgets('opens report options with cash closing choices', (tester) async {
    await tester.pumpWidget(const SistemaRgtApp());

    await tester.tap(find.byTooltip('Gerar relatório'));
    await tester.pumpAndSettle();

    expect(find.text('Gerar relatório'), findsOneWidget);
    expect(find.text('Todos os colaboradores'), findsWidgets);
    expect(find.text('Daniele'), findsWidgets);
    expect(find.text('Kethelyn'), findsWidgets);
    expect(find.text('Fechamento de caixa geral'), findsOneWidget);
    expect(find.text('Fechamento de caixa por colaborador'), findsOneWidget);
    expect(find.textContaining('Competência'), findsOneWidget);
    expect(find.text('Preparar relatório'), findsOneWidget);
  });
  testWidgets('report preview shows calculated totals', (tester) async {
    await tester.pumpWidget(const SistemaRgtApp());

    await tester.tap(find.byTooltip('Gerar relatório'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Preparar relatório'));
    await tester.pumpAndSettle();

    expect(find.text('Relatório gerado'), findsOneWidget);
    expect(find.text('Demonstrativos mensais'), findsOneWidget);
    expect(find.text('Caixa positivo no mês'), findsOneWidget);
    expect(find.text('Fechamento de caixa parcial'), findsWidgets);
    expect(find.text('R\$ 0,00'), findsWidgets);
    expect(find.text('Exportar Excel'), findsOneWidget);
    expect(find.text('Exportar PDF'), findsOneWidget);
  });

  testWidgets('login page exposes account creation fields', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: LoginPage(),
      ),
    );

    await tester.tap(find.text('Não tenho conta de login'));
    await tester.pumpAndSettle();

    expect(find.text('Nome'), findsOneWidget);
    expect(find.text('Telefone'), findsOneWidget);
    expect(find.text('CPF'), findsOneWidget);
    expect(find.text('Confirmar senha'), findsOneWidget);
    expect(find.text('Criar conta'), findsOneWidget);
  });

  testWidgets('profile page is available from app shell', (tester) async {
    await tester.pumpWidget(const SistemaRgtApp());

    await tester.tap(find.text('Perfil'));
    await tester.pumpAndSettle();

    expect(find.text('Perfil'), findsWidgets);
    expect(
      find.text('Entre no Supabase para gerenciar sua conta.'),
      findsOneWidget,
    );
  });

  testWidgets('audit page is available from app shell', (tester) async {
    await tester.pumpWidget(const SistemaRgtApp());

    await tester.tap(find.text('Auditoria'));
    await tester.pumpAndSettle();

    expect(find.text('Auditoria'), findsWidgets);
    expect(find.text('Eventos recentes'), findsOneWidget);
    expect(
      find.text('Nenhum evento de auditoria encontrado para esta sessão.'),
      findsOneWidget,
    );
  });
}
