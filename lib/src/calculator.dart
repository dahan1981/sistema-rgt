import 'models.dart';

class RgtCalculator {
  const RgtCalculator();

  FinancialSummary calculate(
    MonthlyStatement statement, {
    List<CashClosingEntry> cashClosings = const [],
    DateTime? startDate,
    DateTime? today,
    bool restrictCashClosingsToStatementUnit = true,
  }) {
    final negativeCash = statement.negativeCashEntries.fold<double>(
      0,
      (total, entry) => total + entry.amount,
    );
    final closingSummary = calculateCashClosingSummary(
      cashClosings,
      unit:
          restrictCashClosingsToStatementUnit ? statement.employee.unit : null,
      employee: statement.employee,
      startDate: startDate,
      today: today,
    );

    final absenceDiscount =
        statement.salaryForecast / 30 * statement.expenseAbsenceCount;

    final revenues = (statement.incentive?.amount ?? 0) +
        (statement.launchBalanceBonusAsRevenue ? statement.balanceBonus : 0) +
        closingSummary.positive;

    final expenses = statement.vouchers +
        absenceDiscount +
        (statement.launchNegativeCashAsExpense ? negativeCash : 0) +
        closingSummary.payrollDeductions;

    return FinancialSummary(
      revenues: revenues,
      expenses: expenses,
      absenceDiscount: absenceDiscount,
      negativeCash: negativeCash,
      partialCashClosing: closingSummary.balance,
      payrollCashDiscount: closingSummary.payrollDeductions,
      finalLiability: statement.salaryForecast + revenues - expenses,
    );
  }

  CashClosingSummary calculateCashClosingSummary(
    List<CashClosingEntry> entries, {
    Unit? unit,
    required Employee employee,
    DateTime? startDate,
    DateTime? today,
  }) {
    final currentDate = today ?? DateTime.now();
    final periodStart =
        startDate ?? DateTime(currentDate.year, currentDate.month, 1);
    var positive = 0.0;
    var negative = 0.0;
    var payrollDeductions = 0.0;

    for (final entry in entries) {
      if (entry.isCanceled) {
        continue;
      }
      final inPeriod = !entry.date.isBefore(periodStart);
      final untilToday = !entry.date.isAfter(currentDate);
      final sameContext = entry.employee.id == employee.id &&
          (unit == null || entry.unit == unit);

      if (!inPeriod || !untilToday || !sameContext) {
        continue;
      }

      if (entry.type == CashClosingType.positive) {
        positive += entry.amount;
      } else {
        negative += entry.amount;
        if (entry.deductFromPayroll) {
          payrollDeductions += entry.amount;
        }
      }
    }

    return CashClosingSummary(
      positive: positive,
      negative: negative,
      payrollDeductions: payrollDeductions,
    );
  }
}

String formatCurrency(double value) {
  final normalized = value.toStringAsFixed(2).replaceAll('.', ',');
  final parts = normalized.split(',');
  final digits = parts.first;
  final buffer = StringBuffer();

  for (var index = 0; index < digits.length; index++) {
    final reverseIndex = digits.length - index;
    buffer.write(digits[index]);
    if (reverseIndex > 1 && reverseIndex % 3 == 1) {
      buffer.write('.');
    }
  }

  return 'R\$ ${buffer.toString()},${parts.last}';
}

String formatDate(DateTime value) {
  final day = value.day.toString().padLeft(2, '0');
  final month = value.month.toString().padLeft(2, '0');
  return '$day/$month/${value.year}';
}
