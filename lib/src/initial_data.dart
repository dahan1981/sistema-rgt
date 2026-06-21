import 'models.dart';

// Cadastro inicial real. Os dados financeiros permanecem vazios até o RH lançar.
const initialEmployees = [
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

MonthlyStatement emptyStatement(Employee employee, {DateTime? competence}) {
  final reference = competence ?? DateTime.now();
  return MonthlyStatement(
    employee: employee,
    referenceMonth: DateTime(reference.year, reference.month),
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
