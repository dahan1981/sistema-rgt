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
    expect(find.text('Passivo final'), findsOneWidget);
    expect(find.text('Receitas'), findsOneWidget);
  });

  testWidgets('opens cash closing page', (tester) async {
    await tester.pumpWidget(const SistemaRgtApp());

    await tester.tap(find.text('Caixa'));
    await tester.pumpAndSettle();

    expect(find.text('Fechamento de caixa'), findsOneWidget);
    expect(find.text('Caixa positivo no mes'), findsOneWidget);
    expect(find.text('Descontar em folha'), findsOneWidget);
  });
}
