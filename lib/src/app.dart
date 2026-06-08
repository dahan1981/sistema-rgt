import 'package:flutter/material.dart';

import 'calculator.dart';
import 'models.dart';
import 'sample_data.dart';

class SistemaRgtApp extends StatelessWidget {
  const SistemaRgtApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sistema RGT',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF245B57),
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: const Color(0xFFF6F7F4),
        fontFamily: 'Arial',
      ),
      home: const RgtHomePage(),
    );
  }
}

class RgtHomePage extends StatefulWidget {
  const RgtHomePage({super.key});

  @override
  State<RgtHomePage> createState() => _RgtHomePageState();
}

class _RgtHomePageState extends State<RgtHomePage> {
  final _calculator = const RgtCalculator();
  var _selectedIndex = 0;
  var _selectedEmployee = sampleEmployees.first;
  late MonthlyStatement _statement = sampleStatement(_selectedEmployee);

  void _selectEmployee(Employee employee) {
    setState(() {
      _selectedEmployee = employee;
      _statement = sampleStatement(employee);
      _selectedIndex = 2;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.sizeOf(context).width >= 900;
    final summary = _calculator.calculate(_statement);

    final pages = [
      DashboardPage(statement: _statement, summary: summary),
      EmployeesPage(
        employees: sampleEmployees,
        selectedEmployee: _selectedEmployee,
        onEmployeeSelected: _selectEmployee,
      ),
      StatementPage(
        statement: _statement,
        summary: summary,
        onChanged: (statement) => setState(() => _statement = statement),
      ),
    ];

    return Scaffold(
      body: Row(
        children: [
          if (isDesktop)
            RgtSideNav(
              selectedIndex: _selectedIndex,
              onChanged: (index) => setState(() => _selectedIndex = index),
            ),
          Expanded(
            child: SafeArea(
              child: Column(
                children: [
                  const AppHeader(),
                  Expanded(child: pages[_selectedIndex]),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: isDesktop
          ? null
          : NavigationBar(
              selectedIndex: _selectedIndex,
              onDestinationSelected: (index) {
                setState(() => _selectedIndex = index);
              },
              destinations: const [
                NavigationDestination(
                  icon: Icon(Icons.bar_chart_outlined),
                  selectedIcon: Icon(Icons.bar_chart),
                  label: 'Painel',
                ),
                NavigationDestination(
                  icon: Icon(Icons.groups_outlined),
                  selectedIcon: Icon(Icons.groups),
                  label: 'Equipe',
                ),
                NavigationDestination(
                  icon: Icon(Icons.receipt_long_outlined),
                  selectedIcon: Icon(Icons.receipt_long),
                  label: 'Mensal',
                ),
              ],
            ),
    );
  }
}

class AppHeader extends StatelessWidget {
  const AppHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 12),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: const Color(0xFF245B57),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Text(
              'RGT',
              style: TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Sistema de RGT',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
                ),
                Text(
                  'Demonstrativo mensal de entradas e saidas',
                  style: TextStyle(color: Color(0xFF5E6762)),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Exportar relatorio',
            onPressed: () {},
            icon: const Icon(Icons.picture_as_pdf_outlined),
          ),
        ],
      ),
    );
  }
}

class RgtSideNav extends StatelessWidget {
  const RgtSideNav({
    required this.selectedIndex,
    required this.onChanged,
    super.key,
  });

  final int selectedIndex;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 248,
      color: const Color(0xFF17201D),
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'RGT RH',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 28),
          NavButton(
            icon: Icons.bar_chart_outlined,
            label: 'Painel',
            selected: selectedIndex == 0,
            onTap: () => onChanged(0),
          ),
          NavButton(
            icon: Icons.groups_outlined,
            label: 'Colaboradores',
            selected: selectedIndex == 1,
            onTap: () => onChanged(1),
          ),
          NavButton(
            icon: Icons.receipt_long_outlined,
            label: 'Demonstrativo mensal',
            selected: selectedIndex == 2,
            onTap: () => onChanged(2),
          ),
          const Spacer(),
          const Text(
            'Supabase pendente',
            style: TextStyle(color: Color(0xFFB7C3BD), fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class NavButton extends StatelessWidget {
  const NavButton({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
    super.key,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: selected ? const Color(0xFF245B57) : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            child: Row(
              children: [
                Icon(icon, color: Colors.white, size: 20),
                const SizedBox(width: 12),
                Text(label, style: const TextStyle(color: Colors.white)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class DashboardPage extends StatelessWidget {
  const DashboardPage({
    required this.statement,
    required this.summary,
    super.key,
  });

  final MonthlyStatement statement;
  final FinancialSummary summary;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        ResponsiveGrid(
          children: [
            MetricCard(
              title: 'Passivo final',
              value: formatCurrency(summary.finalLiability),
              icon: Icons.account_balance_wallet_outlined,
            ),
            MetricCard(
              title: 'Receitas',
              value: formatCurrency(summary.revenues),
              icon: Icons.trending_up,
            ),
            MetricCard(
              title: 'Despesas',
              value: formatCurrency(summary.expenses),
              icon: Icons.trending_down,
            ),
            MetricCard(
              title: 'Assiduidade',
              value: '${statement.attendanceScore} pts',
              icon: Icons.fact_check_outlined,
            ),
          ],
        ),
        const SizedBox(height: 20),
        SectionPanel(
          title: 'Colaborador em acompanhamento',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                statement.employee.name,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Text('Unidade: ${statement.employee.unit.label}'),
              Text('Referencia: ${statement.referenceMonth.month}/'
                  '${statement.referenceMonth.year}'),
            ],
          ),
        ),
      ],
    );
  }
}

class EmployeesPage extends StatelessWidget {
  const EmployeesPage({
    required this.employees,
    required this.selectedEmployee,
    required this.onEmployeeSelected,
    super.key,
  });

  final List<Employee> employees;
  final Employee selectedEmployee;
  final ValueChanged<Employee> onEmployeeSelected;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const PageTitle(
          title: 'Colaboradores',
          subtitle: 'Base inicial para vincular demonstrativos por unidade.',
        ),
        const SizedBox(height: 16),
        for (final employee in employees)
          EmployeeRow(
            employee: employee,
            selected: employee.id == selectedEmployee.id,
            onTap: () => onEmployeeSelected(employee),
          ),
      ],
    );
  }
}

class EmployeeRow extends StatelessWidget {
  const EmployeeRow({
    required this.employee,
    required this.selected,
    required this.onTap,
    super.key,
  });

  final Employee employee;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: selected ? const Color(0xFFE3EFEB) : Colors.white,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: const Color(0xFF245B57),
                  foregroundColor: Colors.white,
                  child: Text(employee.name.characters.first),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        employee.name,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      Text(employee.unit.label),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class StatementPage extends StatelessWidget {
  const StatementPage({
    required this.statement,
    required this.summary,
    required this.onChanged,
    super.key,
  });

  final MonthlyStatement statement;
  final FinancialSummary summary;
  final ValueChanged<MonthlyStatement> onChanged;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        PageTitle(
          title: 'Demonstrativo mensal',
          subtitle: statement.employee.name,
        ),
        const SizedBox(height: 16),
        ResponsiveGrid(
          children: [
            SectionPanel(
              title: 'Previsao e descontos',
              child: Column(
                children: [
                  MoneyField(
                    label: 'Previsao de salario',
                    value: statement.salaryForecast,
                    onChanged: (value) => onChanged(
                      statement.copyWith(salaryForecast: value),
                    ),
                  ),
                  MoneyField(
                    label: 'Vales',
                    value: statement.vouchers,
                    onChanged: (value) => onChanged(
                      statement.copyWith(vouchers: value),
                    ),
                  ),
                  NumberStepper(
                    label: 'Faltas',
                    value: statement.absences,
                    onChanged: (value) => onChanged(
                      statement.copyWith(absences: value),
                    ),
                  ),
                  SwitchRow(
                    label: 'Lancar faltas como despesa',
                    value: statement.discountAbsencesAsExpense,
                    onChanged: (value) => onChanged(
                      statement.copyWith(discountAbsencesAsExpense: value),
                    ),
                  ),
                ],
              ),
            ),
            SectionPanel(
              title: 'Assiduidade e receitas',
              child: Column(
                children: [
                  NumberStepper(
                    label: 'Pontuacao de assiduidade',
                    value: statement.attendanceScore,
                    onChanged: (value) => onChanged(
                      statement.copyWith(attendanceScore: value),
                    ),
                  ),
                  DropdownButtonFormField<Incentive>(
                    value: statement.incentive,
                    decoration: const InputDecoration(labelText: 'Incentivo'),
                    items: Incentive.values
                        .map(
                          (item) => DropdownMenuItem(
                            value: item,
                            child: Text(
                              '${item.label} - ${formatCurrency(item.amount)}',
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value != null) {
                        onChanged(statement.copyWith(incentive: value));
                      }
                    },
                  ),
                  MoneyField(
                    label: 'Domingo compensatorio',
                    value: statement.sundayCompensation,
                    onChanged: (value) => onChanged(
                      statement.copyWith(sundayCompensation: value),
                    ),
                  ),
                  SwitchRow(
                    label: 'Lancar domingo em receita',
                    value: statement.launchSundayAsRevenue,
                    onChanged: (value) => onChanged(
                      statement.copyWith(launchSundayAsRevenue: value),
                    ),
                  ),
                ],
              ),
            ),
            SectionPanel(
              title: 'Dobra e caixa',
              child: Column(
                children: [
                  MoneyField(
                    label: 'Dobra',
                    value: statement.doubleShift,
                    onChanged: (value) => onChanged(
                      statement.copyWith(doubleShift: value),
                    ),
                  ),
                  SwitchRow(
                    label: 'Lancar dobra em receita',
                    value: statement.launchDoubleShiftAsRevenue,
                    onChanged: (value) => onChanged(
                      statement.copyWith(launchDoubleShiftAsRevenue: value),
                    ),
                  ),
                  MoneyField(
                    label: 'Bonificacao de balanco',
                    value: statement.balanceBonus,
                    onChanged: (value) => onChanged(
                      statement.copyWith(balanceBonus: value),
                    ),
                  ),
                  SwitchRow(
                    label: 'Lancar bonificacao em receita',
                    value: statement.launchBalanceBonusAsRevenue,
                    onChanged: (value) => onChanged(
                      statement.copyWith(launchBalanceBonusAsRevenue: value),
                    ),
                  ),
                  SwitchRow(
                    label: 'Lancar caixa negativo como despesa',
                    value: statement.launchNegativeCashAsExpense,
                    onChanged: (value) => onChanged(
                      statement.copyWith(launchNegativeCashAsExpense: value),
                    ),
                  ),
                ],
              ),
            ),
            SectionPanel(
              title: 'Resumo financeiro',
              child: SummaryTable(summary: summary),
            ),
          ],
        ),
      ],
    );
  }
}

class MetricCard extends StatelessWidget {
  const MetricCard({
    required this.title,
    required this.value,
    required this.icon,
    super.key,
  });

  final String title;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE1E5DF)),
      ),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF245B57)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(color: Color(0xFF5E6762))),
                const SizedBox(height: 6),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class SectionPanel extends StatelessWidget {
  const SectionPanel({
    required this.title,
    required this.child,
    super.key,
  });

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE1E5DF)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

class PageTitle extends StatelessWidget {
  const PageTitle({
    required this.title,
    required this.subtitle,
    super.key,
  });

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 4),
        Text(subtitle, style: const TextStyle(color: Color(0xFF5E6762))),
      ],
    );
  }
}

class ResponsiveGrid extends StatelessWidget {
  const ResponsiveGrid({required this.children, super.key});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final columns = width >= 1100 ? 2 : 1;

    return LayoutBuilder(
      builder: (context, constraints) {
        final itemWidth = (constraints.maxWidth - (columns - 1) * 16) / columns;
        return Wrap(
          spacing: 16,
          runSpacing: 16,
          children: [
            for (final child in children)
              SizedBox(width: itemWidth, child: child),
          ],
        );
      },
    );
  }
}

class MoneyField extends StatefulWidget {
  const MoneyField({
    required this.label,
    required this.value,
    required this.onChanged,
    super.key,
  });

  final String label;
  final double value;
  final ValueChanged<double> onChanged;

  @override
  State<MoneyField> createState() => _MoneyFieldState();
}

class _MoneyFieldState extends State<MoneyField> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.value.toStringAsFixed(2));
  }

  @override
  void didUpdateWidget(MoneyField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value &&
        double.tryParse(_controller.text.replaceAll(',', '.')) !=
            widget.value) {
      _controller.text = widget.value.toStringAsFixed(2);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: _controller,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        decoration: InputDecoration(
          labelText: widget.label,
          prefixText: 'R\$ ',
          border: const OutlineInputBorder(),
        ),
        onChanged: (text) {
          final value = double.tryParse(text.replaceAll(',', '.'));
          if (value != null) {
            widget.onChanged(value);
          }
        },
      ),
    );
  }
}

class NumberStepper extends StatelessWidget {
  const NumberStepper({
    required this.label,
    required this.value,
    required this.onChanged,
    super.key,
  });

  final String label;
  final int value;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Expanded(child: Text(label)),
          IconButton(
            tooltip: 'Diminuir',
            onPressed: value > 0 ? () => onChanged(value - 1) : null,
            icon: const Icon(Icons.remove_circle_outline),
          ),
          SizedBox(
            width: 48,
            child: Text(
              '$value',
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
          IconButton(
            tooltip: 'Aumentar',
            onPressed: () => onChanged(value + 1),
            icon: const Icon(Icons.add_circle_outline),
          ),
        ],
      ),
    );
  }
}

class SwitchRow extends StatelessWidget {
  const SwitchRow({
    required this.label,
    required this.value,
    required this.onChanged,
    super.key,
  });

  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return SwitchListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(label),
      value: value,
      onChanged: onChanged,
    );
  }
}

class SummaryTable extends StatelessWidget {
  const SummaryTable({required this.summary, super.key});

  final FinancialSummary summary;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SummaryRow(label: 'Receitas', value: summary.revenues),
        SummaryRow(label: 'Despesas', value: summary.expenses),
        SummaryRow(
            label: 'Desconto por faltas', value: summary.absenceDiscount),
        SummaryRow(label: 'Caixa positivo', value: summary.positiveCash),
        SummaryRow(label: 'Caixa negativo', value: summary.negativeCash),
        const Divider(height: 28),
        SummaryRow(
          label: 'Passivo circulante final',
          value: summary.finalLiability,
          emphasized: true,
        ),
      ],
    );
  }
}

class SummaryRow extends StatelessWidget {
  const SummaryRow({
    required this.label,
    required this.value,
    this.emphasized = false,
    super.key,
  });

  final String label;
  final double value;
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontWeight: emphasized ? FontWeight.w700 : FontWeight.w400,
              ),
            ),
          ),
          Text(
            formatCurrency(value),
            style: TextStyle(
              fontSize: emphasized ? 18 : 14,
              fontWeight: emphasized ? FontWeight.w800 : FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

extension MonthlyStatementCopy on MonthlyStatement {
  MonthlyStatement copyWith({
    Employee? employee,
    DateTime? referenceMonth,
    double? salaryForecast,
    double? vouchers,
    int? absences,
    bool? discountAbsencesAsExpense,
    int? attendanceScore,
    Incentive? incentive,
    double? sundayCompensation,
    bool? launchSundayAsRevenue,
    double? doubleShift,
    bool? launchDoubleShiftAsRevenue,
    double? balanceBonus,
    bool? launchBalanceBonusAsRevenue,
    List<CashEntry>? positiveCashEntries,
    List<CashEntry>? negativeCashEntries,
    bool? launchNegativeCashAsExpense,
  }) {
    return MonthlyStatement(
      employee: employee ?? this.employee,
      referenceMonth: referenceMonth ?? this.referenceMonth,
      salaryForecast: salaryForecast ?? this.salaryForecast,
      vouchers: vouchers ?? this.vouchers,
      absences: absences ?? this.absences,
      discountAbsencesAsExpense:
          discountAbsencesAsExpense ?? this.discountAbsencesAsExpense,
      attendanceScore: attendanceScore ?? this.attendanceScore,
      incentive: incentive ?? this.incentive,
      sundayCompensation: sundayCompensation ?? this.sundayCompensation,
      launchSundayAsRevenue:
          launchSundayAsRevenue ?? this.launchSundayAsRevenue,
      doubleShift: doubleShift ?? this.doubleShift,
      launchDoubleShiftAsRevenue:
          launchDoubleShiftAsRevenue ?? this.launchDoubleShiftAsRevenue,
      balanceBonus: balanceBonus ?? this.balanceBonus,
      launchBalanceBonusAsRevenue:
          launchBalanceBonusAsRevenue ?? this.launchBalanceBonusAsRevenue,
      positiveCashEntries: positiveCashEntries ?? this.positiveCashEntries,
      negativeCashEntries: negativeCashEntries ?? this.negativeCashEntries,
      launchNegativeCashAsExpense:
          launchNegativeCashAsExpense ?? this.launchNegativeCashAsExpense,
    );
  }
}
