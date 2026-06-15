import 'models.dart';

const sampleEmployees = [
  Employee(id: 'lar-1', name: 'Daniele', unit: Unit.laranj),
  Employee(id: 'lar-2', name: 'Kethelyn', unit: Unit.laranj),
  Employee(id: 'lar-3', name: 'Priscila', unit: Unit.largoDoMachado),
  Employee(id: 'lar-4', name: 'Flávia', unit: Unit.largoDoMachado),
  Employee(id: 'ger-1', name: 'Denis', unit: Unit.geralBanca),
  Employee(id: 'ktt1-1', name: 'Anna', unit: Unit.ktt1),
  Employee(id: 'ktt1-2', name: 'Rafaela', unit: Unit.ktt1),
  Employee(id: 'ktt2-1', name: 'Patrick', unit: Unit.ktt2),
  Employee(id: 'ktt2-2', name: 'Breno', unit: Unit.ktt2),
  Employee(id: 'ktt2-3', name: 'Danilo', unit: Unit.ktt2),
  Employee(id: 'ktt3-1', name: 'Cainã', unit: Unit.ktt3),
  Employee(id: 'ktt3-2', name: 'Gabriela', unit: Unit.ktt3),
  Employee(id: 'ktt4-1', name: 'Brenda', unit: Unit.ktt4),
  Employee(id: 'ktt4-2', name: 'Dimas', unit: Unit.ktt4),
  Employee(id: 'ktt4-3', name: 'Brendel', unit: Unit.ktt4),
  Employee(id: 'adm-1', name: 'Luiz', unit: Unit.adm),
  Employee(id: 'adm-2', name: 'Fabiana', unit: Unit.adm),
  Employee(id: 'adm-3', name: 'Wesley', unit: Unit.adm),
  Employee(id: 'adm-4', name: 'Jean', unit: Unit.adm),
  Employee(id: 'adm-5', name: 'João', unit: Unit.adm),
  Employee(id: 'adm-6', name: 'Nise', unit: Unit.adm),
  Employee(id: 'adm-7', name: 'Thais', unit: Unit.adm),
];

final sampleCashClosings = [
  CashClosingEntry(
    id: 'cx-1',
    date: DateTime(2026, 6, 3),
    unit: Unit.laranj,
    employee: sampleEmployees[0],
    type: CashClosingType.positive,
    amount: 84.50,
    description: 'Sobra de fechamento',
    deductFromPayroll: false,
  ),
  CashClosingEntry(
    id: 'cx-2',
    date: DateTime(2026, 6, 5),
    unit: Unit.laranj,
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
    absences: [
      AbsenceEntry(date: DateTime(2026, 6, 10), asExpense: true),
    ],
    attendanceScore: 94,
    incentive: Incentive.score2,
    balanceBonus: 70,
    launchBalanceBonusAsRevenue: true,
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
