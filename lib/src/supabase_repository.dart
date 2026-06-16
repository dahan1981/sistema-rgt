import 'package:supabase_flutter/supabase_flutter.dart';

import 'models.dart';
import 'sample_data.dart';
import 'supabase_config.dart';

class RgtSnapshot {
  const RgtSnapshot({
    required this.employees,
    required this.unitAssignments,
    required this.cashClosings,
  });

  final List<Employee> employees;
  final List<UnitAssignment> unitAssignments;
  final List<CashClosingEntry> cashClosings;
}

class SupabaseRepository {
  SupabaseRepository({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  bool get canPersist =>
      SupabaseConfig.isConfigured && _client.auth.currentUser != null;

  Future<RgtSnapshot> fetchSnapshot() async {
    final collaboratorsRows = await _client
        .from('collaborators')
        .select('id, full_name, base_unit_id')
        .eq('active', true)
        .order('full_name');
    final employees = collaboratorsRows
        .map<Employee>(
          (row) => Employee(
            id: row['id'] as String,
            name: row['full_name'] as String,
            unit: _unitFromId(row['base_unit_id'] as String),
          ),
        )
        .toList();

    final assignmentsRows = await _client
        .from('unit_assignments')
        .select('id, collaborator_id, assigned_date, unit_id')
        .order('assigned_date', ascending: false);
    final assignments = assignmentsRows
        .map<UnitAssignment>(
          (row) => UnitAssignment(
            id: row['id'] as String,
            employeeId: row['collaborator_id'] as String,
            date: DateTime.parse(row['assigned_date'] as String),
            unit: _unitFromId(row['unit_id'] as String),
          ),
        )
        .toList();

    final employeeById = {
      for (final employee in employees) employee.id: employee,
    };
    final closingsRows = await _client
        .from('cash_closings')
        .select(
          'id, entry_date, unit_id, collaborator_id, kind, amount, description, deduct_from_payroll',
        )
        .order('entry_date', ascending: false);
    final closings = closingsRows
        .where((row) => employeeById.containsKey(row['collaborator_id']))
        .map<CashClosingEntry>(
          (row) => CashClosingEntry(
            id: row['id'] as String,
            date: DateTime.parse(row['entry_date'] as String),
            unit: _unitFromId(row['unit_id'] as String),
            employee: employeeById[row['collaborator_id']]!,
            type: _cashClosingTypeFromId(row['kind'] as String),
            amount: _number(row['amount']),
            description: row['description'] as String,
            deductFromPayroll: row['deduct_from_payroll'] as bool,
          ),
        )
        .toList();

    return RgtSnapshot(
      employees: employees,
      unitAssignments: assignments,
      cashClosings: closings,
    );
  }

  Future<MonthlyStatement> fetchStatement(Employee employee) async {
    final referenceMonth = _monthStart(DateTime.now());
    final rows = await _client
        .from('monthly_statements')
        .select()
        .eq('collaborator_id', employee.id)
        .eq('reference_month', _dateOnly(referenceMonth))
        .limit(1);

    if (rows.isEmpty) {
      return sampleStatement(employee);
    }

    final row = rows.first;
    final statementId = row['id'] as String;
    final absencesRows = await _client
        .from('absence_entries')
        .select('absence_date, as_expense')
        .eq('monthly_statement_id', statementId)
        .order('absence_date');
    final cashRows = await _client
        .from('negative_cash_entries')
        .select('entry_date, description, amount')
        .eq('monthly_statement_id', statementId)
        .order('entry_date');

    return MonthlyStatement(
      employee: employee,
      referenceMonth: DateTime.parse(row['reference_month'] as String),
      salaryForecast: _number(row['salary_forecast']),
      vouchers: _number(row['vouchers']),
      absences: absencesRows
          .map<AbsenceEntry>(
            (absence) => AbsenceEntry(
              date: DateTime.parse(absence['absence_date'] as String),
              asExpense: absence['as_expense'] as bool,
            ),
          )
          .toList(),
      attendanceScore: row['attendance_score'] as int,
      incentive: _incentiveFromScore(row['incentive_score'] as int),
      balanceBonus: _number(row['balance_bonus']),
      launchBalanceBonusAsRevenue:
          row['launch_balance_bonus_as_revenue'] as bool,
      negativeCashEntries: cashRows
          .map<CashEntry>(
            (cash) => CashEntry(
              date: DateTime.parse(cash['entry_date'] as String),
              description: cash['description'] as String,
              amount: _number(cash['amount']),
            ),
          )
          .toList(),
      launchNegativeCashAsExpense:
          row['launch_negative_cash_as_expense'] as bool,
    );
  }

  Future<void> saveEmployee(Employee employee) async {
    await _client.from('collaborators').upsert({
      'id': employee.id,
      'full_name': employee.name,
      'base_unit_id': _unitId(employee.unit),
    });
  }

  Future<void> addUnitAssignment(UnitAssignment assignment) async {
    await _client.from('unit_assignments').insert({
      'collaborator_id': assignment.employeeId,
      'assigned_date': _dateOnly(assignment.date),
      'unit_id': _unitId(assignment.unit),
    });
  }

  Future<void> addCashClosing(CashClosingEntry entry) async {
    await _client.from('cash_closings').insert({
      'entry_date': _dateOnly(entry.date),
      'unit_id': _unitId(entry.unit),
      'collaborator_id': entry.employee.id,
      'kind': _cashClosingTypeId(entry.type),
      'amount': entry.amount,
      'description': entry.description,
      'deduct_from_payroll': entry.deductFromPayroll,
    });
  }

  Future<void> saveStatement(MonthlyStatement statement) async {
    final referenceMonth = _monthStart(statement.referenceMonth);
    final statementRows = await _client
        .from('monthly_statements')
        .upsert(
          {
            'collaborator_id': statement.employee.id,
            'reference_month': _dateOnly(referenceMonth),
            'salary_forecast': statement.salaryForecast,
            'vouchers': statement.vouchers,
            'attendance_score': statement.attendanceScore,
            'incentive_score': _incentiveScore(statement.incentive),
            'incentive_amount': statement.incentive.amount,
            'balance_bonus': statement.balanceBonus,
            'launch_balance_bonus_as_revenue':
                statement.launchBalanceBonusAsRevenue,
            'launch_negative_cash_as_expense':
                statement.launchNegativeCashAsExpense,
          },
          onConflict: 'collaborator_id,reference_month',
        )
        .select('id');
    final statementId = statementRows.first['id'] as String;

    await _client
        .from('absence_entries')
        .delete()
        .eq('monthly_statement_id', statementId);
    if (statement.absences.isNotEmpty) {
      await _client.from('absence_entries').insert(
            statement.absences
                .map(
                  (absence) => {
                    'monthly_statement_id': statementId,
                    'absence_date': _dateOnly(absence.date),
                    'as_expense': absence.asExpense,
                  },
                )
                .toList(),
          );
    }

    await _client
        .from('negative_cash_entries')
        .delete()
        .eq('monthly_statement_id', statementId);
    if (statement.negativeCashEntries.isNotEmpty) {
      await _client.from('negative_cash_entries').insert(
            statement.negativeCashEntries
                .map(
                  (entry) => {
                    'monthly_statement_id': statementId,
                    'entry_date': _dateOnly(entry.date),
                    'description': entry.description,
                    'amount': entry.amount,
                  },
                )
                .toList(),
          );
    }
  }

  String _dateOnly(DateTime date) {
    final normalized = DateTime(date.year, date.month, date.day);
    return normalized.toIso8601String().split('T').first;
  }

  DateTime _monthStart(DateTime date) => DateTime(date.year, date.month);

  double _number(Object? value) {
    if (value is num) {
      return value.toDouble();
    }
    return double.parse(value.toString());
  }

  Unit _unitFromId(String id) {
    return switch (id) {
      'adm' => Unit.adm,
      'geral' => Unit.geralBanca,
      'largo_do_machado' => Unit.largoDoMachado,
      'laranj' => Unit.laranj,
      'ktt1' => Unit.ktt1,
      'ktt2' => Unit.ktt2,
      'ktt3' => Unit.ktt3,
      'ktt4' => Unit.ktt4,
      _ => Unit.geralBanca,
    };
  }

  String _unitId(Unit unit) {
    return switch (unit) {
      Unit.adm => 'adm',
      Unit.geral => 'geral',
      Unit.geralBanca => 'geral',
      Unit.largoDoMachado => 'largo_do_machado',
      Unit.laranj => 'laranj',
      Unit.ktt1 => 'ktt1',
      Unit.ktt2 => 'ktt2',
      Unit.ktt3 => 'ktt3',
      Unit.ktt4 => 'ktt4',
    };
  }

  CashClosingType _cashClosingTypeFromId(String id) {
    return id == 'negative'
        ? CashClosingType.negative
        : CashClosingType.positive;
  }

  String _cashClosingTypeId(CashClosingType type) {
    return type == CashClosingType.negative ? 'negative' : 'positive';
  }

  Incentive _incentiveFromScore(int score) {
    return switch (score) {
      2 => Incentive.score2,
      3 => Incentive.score3,
      _ => Incentive.score1,
    };
  }

  int _incentiveScore(Incentive incentive) {
    return switch (incentive) {
      Incentive.score1 => 1,
      Incentive.score2 => 2,
      Incentive.score3 => 3,
    };
  }
}
