import 'models.dart';

class RgtCalculator {
  const RgtCalculator();

  FinancialSummary calculate(MonthlyStatement statement) {
    final positiveCash = statement.positiveCashEntries.fold<double>(
      0,
      (total, entry) => total + entry.amount,
    );
    final negativeCash = statement.negativeCashEntries.fold<double>(
      0,
      (total, entry) => total + entry.amount,
    );

    final absenceDiscount = statement.discountAbsencesAsExpense
        ? statement.salaryForecast / 30 * statement.absences
        : 0.0;

    final revenues = statement.incentive.amount +
        (statement.launchSundayAsRevenue ? statement.sundayCompensation : 0) +
        (statement.launchDoubleShiftAsRevenue ? statement.doubleShift : 0) +
        (statement.launchBalanceBonusAsRevenue ? statement.balanceBonus : 0) +
        positiveCash;

    final expenses = statement.vouchers +
        absenceDiscount +
        (statement.launchNegativeCashAsExpense ? negativeCash : 0);

    return FinancialSummary(
      revenues: revenues,
      expenses: expenses,
      absenceDiscount: absenceDiscount,
      positiveCash: positiveCash,
      negativeCash: negativeCash,
      finalLiability: statement.salaryForecast + revenues - expenses,
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
