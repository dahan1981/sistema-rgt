import 'package:flutter_test/flutter_test.dart';

import 'package:sistema_rgt/src/app.dart';

void main() {
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
