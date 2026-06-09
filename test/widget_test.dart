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
    expect(find.text('Todos os funcionarios'), findsOneWidget);
    expect(find.text('Todos os colaboradores'), findsOneWidget);
  });

  testWidgets('opens cash closing page', (tester) async {
    await tester.pumpWidget(const SistemaRgtApp());

    await tester.tap(find.text('Caixa'));
    await tester.pumpAndSettle();

    expect(find.text('Fechamento de caixa'), findsOneWidget);
    expect(find.text('Caixa positivo no mes'), findsOneWidget);
    expect(find.text('Descontar em folha'), findsOneWidget);
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

    expect(find.text('8 colaborador(es) em todos os funcionarios'),
        findsOneWidget);
    expect(find.text('Ana Carolina Martins'), findsWidgets);
    await tester.scrollUntilVisible(
      find.text('Gabriel Souza'),
      400,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Gabriel Souza'), findsOneWidget);
  });

  testWidgets('shows incentive score and calculated amount', (tester) async {
    await tester.pumpWidget(const SistemaRgtApp());

    await tester.tap(find.text('Mensal'));
    await tester.pumpAndSettle();

    expect(find.text('Pontuacao de incentivo'), findsOneWidget);
    expect(find.text('Valor do incentivo'), findsOneWidget);
    expect(find.text('R\$ 100,00'), findsWidgets);
  });

  testWidgets('opens report options with cash closing choices', (tester) async {
    await tester.pumpWidget(const SistemaRgtApp());

    await tester.tap(find.byTooltip('Gerar relatorio'));
    await tester.pumpAndSettle();

    expect(find.text('Gerar relatorio'), findsOneWidget);
    expect(find.text('Fechamento de caixa geral'), findsOneWidget);
    expect(find.text('Fechamento de caixa por colaborador'), findsOneWidget);
    expect(find.text('Preparar relatorio'), findsOneWidget);
  });
}
