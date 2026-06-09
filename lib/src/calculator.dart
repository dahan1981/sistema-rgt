import 'models.dart';

class RgtCalculator {
  const RgtCalculator();

  FinancialSummary calculate(
    MonthlyStatement statement, {
    List<CashClosingEntry> cashClosings = const [],
    DateTime? today,
  }) {
    final positiveCash = statement.positiveCashEntries.fold<double>(
      0,
      (total, entry) => total + entry.amount,
    );
    final negativeCash = statement.negativeCashEntries.fold<double>(
      0,
      (total, entry) => total + entry.amount,
    );
    final closingSummary = calculateCashClosingSummary(
      cashClosings,
      unit: statement.employee.unit,
      employee: statement.employee,
      today: today,
    );

    final absenceDiscount = statement.discountAbsencesAsExpense
        ? statement.salaryForecast / 30 * statement.absences
        : 0.0;

    final revenues = statement.incentive.amount +
        (statement.launchSundayAsRevenue ? statement.sundayCompensation : 0) +
        (statement.launchDoubleShiftAsRevenue ? statement.doubleShift : 0) +
        (statement.launchBalanceBonusAsRevenue ? statement.balanceBonus : 0) +
        positiveCash +
        closingSummary.positive;

    final expenses = statement.vouchers +
        absenceDiscount +
        (statement.launchNegativeCashAsExpense ? negativeCash : 0) +
        closingSummary.payrollDeductions;

    return FinancialSummary(
      revenues: revenues,
      expenses: expenses,
      absenceDiscount: absenceDiscount,
      positiveCash: positiveCash,
      negativeCash: negativeCash,
      partialCashClosing: closingSummary.balance,
      payrollCashDiscount: closingSummary.payrollDeductions,
      finalLiability: statement.salaryForecast + revenues - expenses,
    );
  }

  CashClosingSummary calculateCashClosingSummary(
    List<CashClosingEntry> entries, {
    required Unit unit,
    required Employee employee,
    DateTime? today,
  }) {
    final currentDate = today ?? DateTime.now();
    var positive = 0.0;
    var negative = 0.0;
    var payrollDeductions = 0.0;

    for (final entry in entries) {
      final sameMonth = entry.date.year == currentDate.year &&
          entry.date.month == currentDate.month;
      final untilToday = !entry.date.isAfter(currentDate);
      final sameContext =
          entry.unit == unit && entry.employee.id == employee.id;

      if (!sameMonth || !untilToday || !sameContext) {
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
