import 'package:supabase_flutter/supabase_flutter.dart';

import 'models.dart';
import 'initial_data.dart';
import 'supabase_config.dart';

class RgtSnapshot {
  const RgtSnapshot({
    required this.employees,
    required this.unitAssignments,
    required this.cashClosings,
    required this.statements,
  });

  final List<Employee> employees;
  final List<UnitAssignment> unitAssignments;
  final List<CashClosingEntry> cashClosings;
  final Map<String, MonthlyStatement> statements;
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
          'id, entry_date, unit_id, collaborator_id, kind, amount, description, '
          'deduct_from_payroll, canceled_at, cancellation_reason, last_correction_reason',
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
            canceledAt: row['canceled_at'] == null
                ? null
                : DateTime.parse(row['canceled_at'] as String),
            cancellationReason: row['cancellation_reason'] as String?,
            correctionReason: row['last_correction_reason'] as String?,
          ),
        )
        .toList();

    final statements = await Future.wait(
      employees.map(fetchStatement),
    );

    return RgtSnapshot(
      employees: employees,
      unitAssignments: assignments,
      cashClosings: closings,
      statements: {
        for (final statement in statements) statement.employee.id: statement,
      },
    );
  }

  Future<MonthlyStatement> fetchStatement(
    Employee employee, {
    DateTime? competence,
  }) async {
    final referenceMonth = _monthStart(competence ?? DateTime.now());
    final rows = await _client
        .from('monthly_statements')
        .select()
        .eq('collaborator_id', employee.id)
        .eq('reference_month', _dateOnly(referenceMonth))
        .limit(1);

    if (rows.isEmpty) {
      return emptyStatement(employee, competence: referenceMonth);
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
      incentive: _incentiveFromScore(row['incentive_score']),
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
    await _client.from('unit_assignments').upsert(
      {
        'collaborator_id': assignment.employeeId,
        'assigned_date': _dateOnly(assignment.date),
        'unit_id': _unitId(assignment.unit),
      },
      onConflict: 'collaborator_id,assigned_date',
    );
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

  Future<void> correctCashClosing(
    CashClosingEntry entry,
    String reason,
  ) async {
    await _client.rpc(
      'correct_cash_closing',
      params: {
        'p_cash_closing_id': entry.id,
        'p_amount': entry.amount,
        'p_description': entry.description,
        'p_deduct_from_payroll': entry.deductFromPayroll,
        'p_reason': reason,
      },
    );
  }

  Future<void> cancelCashClosing(String id, String reason) async {
    await _client.rpc(
      'cancel_cash_closing',
      params: {
        'p_cash_closing_id': id,
        'p_reason': reason,
      },
    );
  }

  Future<void> saveStatement(MonthlyStatement statement) async {
    final referenceMonth = _monthStart(statement.referenceMonth);
    await _client.rpc(
      'save_monthly_statement',
      params: {
        'p_collaborator_id': statement.employee.id,
        'p_reference_month': _dateOnly(referenceMonth),
        'p_salary_forecast': statement.salaryForecast,
        'p_vouchers': statement.vouchers,
        'p_attendance_score': statement.attendanceScore,
        'p_incentive_score': _incentiveScore(statement.incentive),
        'p_balance_bonus': statement.balanceBonus,
        'p_launch_balance_bonus_as_revenue':
            statement.launchBalanceBonusAsRevenue,
        'p_launch_negative_cash_as_expense':
            statement.launchNegativeCashAsExpense,
        'p_absences': statement.absences
            .map(
              (absence) => {
                'absence_date': _dateOnly(absence.date),
                'as_expense': absence.asExpense,
              },
            )
            .toList(),
        'p_negative_cash_entries': statement.negativeCashEntries
            .map(
              (entry) => {
                'entry_date': _dateOnly(entry.date),
                'description': entry.description,
                'amount': entry.amount,
              },
            )
            .toList(),
      },
    );
  }

  Future<ReportData> fetchReportData(ReportOptions options) async {
    final statements = await Future.wait(
      options.selectedEmployees.map(
        (employee) => fetchStatement(employee, competence: options.competence),
      ),
    );

    var query = _client
        .from('cash_closings')
        .select(
          'id, entry_date, unit_id, collaborator_id, kind, amount, description, '
          'deduct_from_payroll, canceled_at, cancellation_reason, last_correction_reason',
        )
        .gte('entry_date', _dateOnly(options.startDate))
        .lte('entry_date', _dateOnly(options.endDate))
        .isFilter('canceled_at', null);
    if (options.unit != null && options.unit != Unit.geral) {
      query = query.eq('unit_id', _unitId(options.unit!));
    }
    if (options.selectedEmployees.isNotEmpty) {
      query = query.inFilter(
        'collaborator_id',
        options.selectedEmployees.map((employee) => employee.id).toList(),
      );
    }

    final rows = await query.order('entry_date', ascending: true);
    final employeesById = {
      for (final employee in options.selectedEmployees) employee.id: employee,
    };
    final closings = rows
        .where((row) => employeesById.containsKey(row['collaborator_id']))
        .map<CashClosingEntry>(
          (row) => CashClosingEntry(
            id: row['id'] as String,
            date: DateTime.parse(row['entry_date'] as String),
            unit: _unitFromId(row['unit_id'] as String),
            employee: employeesById[row['collaborator_id']]!,
            type: _cashClosingTypeFromId(row['kind'] as String),
            amount: _number(row['amount']),
            description: row['description'] as String,
            deductFromPayroll: row['deduct_from_payroll'] as bool,
            canceledAt: row['canceled_at'] == null
                ? null
                : DateTime.parse(row['canceled_at'] as String),
            cancellationReason: row['cancellation_reason'] as String?,
            correctionReason: row['last_correction_reason'] as String?,
          ),
        )
        .toList();

    return ReportData(
      options: options,
      statements: {
        for (final statement in statements) statement.employee.id: statement,
      },
      cashClosings: closings,
      generatedAt: DateTime.now(),
    );
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

  Incentive? _incentiveFromScore(Object? score) {
    return switch (score) {
      2 => Incentive.score2,
      3 => Incentive.score3,
      1 => Incentive.score1,
      _ => null,
    };
  }

  int? _incentiveScore(Incentive? incentive) {
    return switch (incentive) {
      Incentive.score1 => 1,
      Incentive.score2 => 2,
      Incentive.score3 => 3,
      null => null,
    };
  }
}
