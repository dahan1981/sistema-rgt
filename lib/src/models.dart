enum Unit {
  adm('ADM'),
  geral('Todos os colaboradores'),
  geralBanca('Geral'),
  largoDoMachado('Largo'),
  laranj('Laranjeiras'),
  ktt1('KTT1'),
  ktt2('KTT2'),
  ktt3('KTT3'),
  ktt4('KTT4');

  const Unit(this.label);

  final String label;
}

enum Incentive {
  score1('Pontuação 1', 50),
  score2('Pontuação 2', 100),
  score3('Pontuação 3', 150);

  const Incentive(this.label, this.amount);

  final String label;
  final double amount;
}

class Employee {
  const Employee({
    required this.id,
    required this.name,
    required this.unit,
  });

  final String id;
  final String name;
  final Unit unit;

  Employee copyWith({
    String? name,
    Unit? unit,
  }) {
    return Employee(
      id: id,
      name: name ?? this.name,
      unit: unit ?? this.unit,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is Employee && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

class UnitAssignment {
  const UnitAssignment({
    required this.id,
    required this.employeeId,
    required this.date,
    required this.unit,
  });

  final String id;
  final String employeeId;
  final DateTime date;
  final Unit unit;
}

class CashEntry {
  const CashEntry({
    required this.date,
    required this.description,
    required this.amount,
  });

  final DateTime date;
  final String description;
  final double amount;
}

class AbsenceEntry {
  const AbsenceEntry({
    required this.date,
    required this.asExpense,
  });

  final DateTime date;
  final bool asExpense;
}

enum CashClosingType {
  positive('Caixa positivo'),
  negative('Caixa negativo');

  const CashClosingType(this.label);

  final String label;
}

class CashClosingEntry {
  const CashClosingEntry({
    required this.id,
    required this.date,
    required this.unit,
    required this.employee,
    required this.type,
    required this.amount,
    required this.description,
    required this.deductFromPayroll,
  });

  final String id;
  final DateTime date;
  final Unit unit;
  final Employee employee;
  final CashClosingType type;
  final double amount;
  final String description;
  final bool deductFromPayroll;
}

class CashClosingSummary {
  const CashClosingSummary({
    required this.positive,
    required this.negative,
    required this.payrollDeductions,
  });

  final double positive;
  final double negative;
  final double payrollDeductions;

  double get balance => positive - negative;
}

class ReportOptions {
  const ReportOptions({
    required this.includeFinancialStatement,
    required this.includeGeneralCashClosing,
    required this.includeEmployeeCashClosing,
    required this.selectedEmployees,
  });

  final bool includeFinancialStatement;
  final bool includeGeneralCashClosing;
  final bool includeEmployeeCashClosing;
  final List<Employee> selectedEmployees;

  bool get hasSelection =>
      includeFinancialStatement ||
      includeGeneralCashClosing ||
      includeEmployeeCashClosing;
}

class MonthlyStatement {
  const MonthlyStatement({
    required this.employee,
    required this.referenceMonth,
    required this.salaryForecast,
    required this.vouchers,
    required this.absences,
    required this.attendanceScore,
    required this.incentive,
    required this.balanceBonus,
    required this.launchBalanceBonusAsRevenue,
    required this.negativeCashEntries,
    required this.launchNegativeCashAsExpense,
  });

  final Employee employee;
  final DateTime referenceMonth;
  final double salaryForecast;
  final double vouchers;
  final List<AbsenceEntry> absences;
  final int attendanceScore;
  final Incentive incentive;
  final double balanceBonus;
  final bool launchBalanceBonusAsRevenue;
  final List<CashEntry> negativeCashEntries;
  final bool launchNegativeCashAsExpense;

  int get absenceCount => absences.length;
  int get expenseAbsenceCount =>
      absences.where((absence) => absence.asExpense).length;
}

class FinancialSummary {
  const FinancialSummary({
    required this.revenues,
    required this.expenses,
    required this.absenceDiscount,
    required this.negativeCash,
    required this.partialCashClosing,
    required this.payrollCashDiscount,
    required this.finalLiability,
  });

  final double revenues;
  final double expenses;
  final double absenceDiscount;
  final double negativeCash;
  final double partialCashClosing;
  final double payrollCashDiscount;
  final double finalLiability;
}
