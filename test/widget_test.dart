import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:sistema_rgt/src/calculator.dart';
import 'package:sistema_rgt/src/app.dart';
import 'package:sistema_rgt/src/models.dart';
import 'package:sistema_rgt/src/sample_data.dart';

void main() {
  test('cash closings feed financial summary', () {
    final employee = sampleEmployees.first;
    final statement = sampleStatement(employee);
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
            employees: sampleEmployees,
            entries: sampleCashClosings,
            selectedUnit: Unit.geral,
            selectedEmployee: sampleEmployees.first,
            onUnitSelected: (_) {},
            onEmployeeSelected: (_) {},
            effectiveUnitForDate: (employee, _) => employee.unit,
            onEntryAdded: (_) {},
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
            employees: sampleEmployees,
            unitAssignments: const [],
            selectedUnit: Unit.geral,
            selectedEmployee: sampleEmployees.first,
            effectiveUnitForDate: (employee, _) => employee.unit,
            onUnitSelected: (_) {},
            onEmployeeSelected: (_) {},
            onEmployeeSaved: (_) {},
            onUnitAssignmentAdded: (_) {},
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
            employees: sampleEmployees,
            unitAssignments: [
              UnitAssignment(
                id: 'temp-1',
                employeeId: sampleEmployees.first.id,
                date: DateTime(2026, 6, 15),
                unit: Unit.ktt1,
              ),
            ],
            selectedUnit: Unit.geral,
            selectedEmployee: sampleEmployees.first,
            effectiveUnitForDate: (employee, _) {
              return employee.id == sampleEmployees.first.id
                  ? Unit.ktt1
                  : employee.unit;
            },
            onUnitSelected: (_) {},
            onEmployeeSelected: (_) {},
            onEmployeeSaved: (_) {},
            onUnitAssignmentAdded: (_) {},
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
    expect(find.text('R\$ 100,00'), findsWidgets);
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

    expect(find.text('1 falta registrada'), findsOneWidget);
    expect(find.text('10/06/2026'), findsOneWidget);
    expect(find.text('Lançar falta'), findsOneWidget);
    expect(find.text('Lançar esta falta como despesa'), findsOneWidget);
    expect(find.text('Despesa'), findsOneWidget);
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
    expect(find.text('Preparar relatório'), findsOneWidget);
  });
}
