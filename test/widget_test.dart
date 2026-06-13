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

  testWidgets('opens cash closing page', (tester) async {
    await tester.pumpWidget(const SistemaRgtApp());

    await tester.tap(find.text('Caixa'));
    await tester.pumpAndSettle();

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
            selectedUnit: Unit.geral,
            selectedEmployee: sampleEmployees.first,
            onUnitSelected: (_) {},
            onEmployeeSelected: (_) {},
          ),
        ),
      ),
    );

    expect(
        find.text('8 colaboradores em todos os colaboradores'), findsOneWidget);
    expect(find.text('Ana Carolina Martins'), findsWidgets);
    await tester.scrollUntilVisible(
      find.text('Gabriel Souza'),
      400,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Gabriel Souza'), findsOneWidget);
  });

  testWidgets('selecting collaborator explains monthly navigation',
      (tester) async {
    await tester.pumpWidget(const SistemaRgtApp());

    await tester.tap(find.text('Equipe'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Ana Carolina Martins').last);
    await tester.pumpAndSettle();

    expect(find.text('Demonstrativo mensal'), findsOneWidget);
    expect(
      find.text('Demonstrativo mensal aberto para Ana Carolina Martins.'),
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

  testWidgets('shows absence history with dates', (tester) async {
    await tester.pumpWidget(const SistemaRgtApp());

    await tester.tap(find.text('Mensal'));
    await tester.pumpAndSettle();

    expect(find.text('1 falta registrada'), findsOneWidget);
    expect(find.text('10/06/2026'), findsOneWidget);
    expect(find.text('Adicionar falta'), findsOneWidget);
  });

  testWidgets('opens report options with cash closing choices', (tester) async {
    await tester.pumpWidget(const SistemaRgtApp());

    await tester.tap(find.byTooltip('Gerar relatório'));
    await tester.pumpAndSettle();

    expect(find.text('Gerar relatório'), findsOneWidget);
    expect(find.text('Todos os colaboradores'), findsWidgets);
    expect(find.text('Ana Carolina Martins'), findsWidgets);
    expect(find.text('Bruno Silva Rocha'), findsWidgets);
    expect(find.text('Fechamento de caixa geral'), findsOneWidget);
    expect(find.text('Fechamento de caixa por colaborador'), findsOneWidget);
    expect(find.text('Preparar relatório'), findsOneWidget);
  });
}
