enum Unit {
  adm('Administracao'),
  geral('Todos os colaboladores'),
  largoDoMachado('LARGO DO MACHADO'),
  laranj('LARANJ'),
  ktt1('KTT1'),
  ktt2('KTT2'),
  ktt3('KTT3'),
  ktt4('KTT4');

  const Unit(this.label);

  final String label;
}

enum Incentive {
  score1('Pontuacao 1', 50),
  score2('Pontuacao 2', 100),
  score3('Pontuacao 3', 150);

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
  });

  final bool includeFinancialStatement;
  final bool includeGeneralCashClosing;
  final bool includeEmployeeCashClosing;

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
    required this.discountAbsencesAsExpense,
    required this.attendanceScore,
    required this.incentive,
    required this.sundayCompensation,
    required this.launchSundayAsRevenue,
    required this.doubleShift,
    required this.launchDoubleShiftAsRevenue,
    required this.balanceBonus,
    required this.launchBalanceBonusAsRevenue,
    required this.positiveCashEntries,
    required this.negativeCashEntries,
    required this.launchNegativeCashAsExpense,
  });

  final Employee employee;
  final DateTime referenceMonth;
  final double salaryForecast;
  final double vouchers;
  final int absences;
  final bool discountAbsencesAsExpense;
  final int attendanceScore;
  final Incentive incentive;
  final double sundayCompensation;
  final bool launchSundayAsRevenue;
  final double doubleShift;
  final bool launchDoubleShiftAsRevenue;
  final double balanceBonus;
  final bool launchBalanceBonusAsRevenue;
  final List<CashEntry> positiveCashEntries;
  final List<CashEntry> negativeCashEntries;
  final bool launchNegativeCashAsExpense;
}

class FinancialSummary {
  const FinancialSummary({
    required this.revenues,
    required this.expenses,
    required this.absenceDiscount,
    required this.positiveCash,
    required this.negativeCash,
    required this.partialCashClosing,
    required this.payrollCashDiscount,
    required this.finalLiability,
  });

  final double revenues;
  final double expenses;
  final double absenceDiscount;
  final double positiveCash;
  final double negativeCash;
  final double partialCashClosing;
  final double payrollCashDiscount;
  final double finalLiability;
}
