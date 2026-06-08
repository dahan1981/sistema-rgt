import 'models.dart';

const sampleEmployees = [
  Employee(id: '1', name: 'Ana Carolina Martins', unit: Unit.adm),
  Employee(id: '2', name: 'Bruno Silva Rocha', unit: Unit.geral),
  Employee(id: '3', name: 'Camila Nogueira', unit: Unit.largoDoMachado),
  Employee(id: '4', name: 'Diego Almeida', unit: Unit.ktt1),
  Employee(id: '5', name: 'Fernanda Lima', unit: Unit.ktt3),
];

MonthlyStatement sampleStatement(Employee employee) {
  return MonthlyStatement(
    employee: employee,
    referenceMonth: DateTime(2026, 6),
    salaryForecast: 2450,
    vouchers: 180,
    absences: 1,
    discountAbsencesAsExpense: true,
    attendanceScore: 94,
    incentive: Incentive.level1,
    sundayCompensation: 80,
    launchSundayAsRevenue: true,
    doubleShift: 120,
    launchDoubleShiftAsRevenue: true,
    balanceBonus: 70,
    launchBalanceBonusAsRevenue: true,
    positiveCashEntries: [
      CashEntry(
        date: DateTime(2026, 6, 8),
        description: 'Ajuste caixa positivo',
        amount: 45,
      ),
    ],
    negativeCashEntries: [
      CashEntry(
        date: DateTime(2026, 6, 12),
        description: 'Diferenca caixa',
        amount: 35,
      ),
    ],
    launchNegativeCashAsExpense: true,
  );
}
