import 'models.dart';

const sampleEmployees = [
  Employee(id: '1', name: 'Ana Carolina Martins', unit: Unit.adm),
  Employee(id: '2', name: 'Bruno Silva Rocha', unit: Unit.adm),
  Employee(id: '3', name: 'Camila Nogueira', unit: Unit.largoDoMachado),
  Employee(id: '4', name: 'Daniela Costa', unit: Unit.laranj),
  Employee(id: '5', name: 'Diego Almeida', unit: Unit.ktt1),
  Employee(id: '6', name: 'Eduardo Pereira', unit: Unit.ktt2),
  Employee(id: '7', name: 'Fernanda Lima', unit: Unit.ktt3),
  Employee(id: '8', name: 'Gabriel Souza', unit: Unit.ktt4),
];

final sampleCashClosings = [
  CashClosingEntry(
    id: 'cx-1',
    date: DateTime(2026, 6, 3),
    unit: Unit.adm,
    employee: sampleEmployees[0],
    type: CashClosingType.positive,
    amount: 84.50,
    description: 'Sobra de fechamento',
    deductFromPayroll: false,
  ),
  CashClosingEntry(
    id: 'cx-2',
    date: DateTime(2026, 6, 5),
    unit: Unit.adm,
    employee: sampleEmployees[1],
    type: CashClosingType.negative,
    amount: 42.00,
    description: 'Diferença no caixa',
    deductFromPayroll: true,
  ),
  CashClosingEntry(
    id: 'cx-3',
    date: DateTime(2026, 6, 8),
    unit: Unit.largoDoMachado,
    employee: sampleEmployees[2],
    type: CashClosingType.positive,
    amount: 31.75,
    description: 'Ajuste de conferência',
    deductFromPayroll: false,
  ),
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
    incentive: Incentive.score2,
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
        description: 'Diferença de caixa',
        amount: 35,
      ),
    ],
    launchNegativeCashAsExpense: true,
  );
}
