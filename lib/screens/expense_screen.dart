import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../repositories/app_provider.dart';
import '../models/models.dart';
import '../theme/app_theme.dart';
import '../widgets/common_widgets.dart';
import '../utils/ad_helper.dart';

class ExpenseScreen extends StatefulWidget {
  const ExpenseScreen({super.key});
  @override
  State<ExpenseScreen> createState() => _ExpenseScreenState();
}

class _ExpenseScreenState extends State<ExpenseScreen> {
  List<MonthTotal> _pastTotals = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await context.read<AppProvider>().loadExpenses();
      await _loadPastTotals();
    });
  }

  Future<void> _loadPastTotals() async {
    final provider = context.read<AppProvider>();
    final totals = await provider.getPast3MonthTotals();
    if (mounted) setState(() => _pastTotals = totals);
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    return Scaffold(
      backgroundColor: AppColors.background,
      floatingActionButton: FloatingActionButton(
        onPressed: () => showModalBottomSheet(context: context, isScrollControlled: true, backgroundColor: Colors.transparent, builder: (_) => const _AddExpenseSheet()),
        backgroundColor: AppColors.caramel,
        child: const Icon(Icons.add, color: Colors.white, size: 28),
      ),
      body: CustomScrollView(slivers: [
        SliverToBoxAdapter(child: Container(
          decoration: const BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFFFBF0DE), AppColors.background])),
          padding: const EdgeInsets.fromLTRB(16, 56, 16, 16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('💰 支出管理', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.textDark)),
            const SizedBox(height: 14),
            _MonthSwitcher(year: provider.expenseYear, month: provider.expenseMonth,
              onPrev: () async { await provider.navigateExpenseMonth(-1); await _loadPastTotals(); },
              onNext: () async { await provider.navigateExpenseMonth(1); await _loadPastTotals(); }),
          ]),
        )),
        SliverToBoxAdapter(child: Padding(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4), child: _DonutCard(provider: provider))),
        if (_pastTotals.isNotEmpty || provider.expenseTotal > 0)
          SliverToBoxAdapter(child: Padding(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4), child: _CompareCard(provider: provider, pastTotals: _pastTotals))),
        SliverToBoxAdapter(child: Padding(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Text('${provider.expenseMonth}月の記録', style: const TextStyle(fontSize: 12, color: AppColors.textMid)))),
        if (provider.expenses.isEmpty)
          const SliverToBoxAdapter(child: Padding(padding: EdgeInsets.all(32), child: Center(child: Text('まだ支出の記録がありません', style: TextStyle(color: AppColors.textLight)))))
        else
          SliverList(delegate: SliverChildBuilderDelegate(
            (ctx, i) => _ExpenseCard(expense: provider.expenses[i]),
            childCount: provider.expenses.length,
          )),
        if (!provider.isPro) const SliverToBoxAdapter(child: Padding(padding: EdgeInsets.symmetric(vertical: 8), child: Center(child: BannerAdWidget()))),
        const SliverToBoxAdapter(child: SizedBox(height: 100)),
      ]),
    );
  }
}

class _MonthSwitcher extends StatelessWidget {
  final int year, month;
  final VoidCallback onPrev, onNext;
  const _MonthSwitcher({required this.year, required this.month, required this.onPrev, required this.onNext});
  @override
  Widget build(BuildContext context) {
    return Material(color: Colors.white, borderRadius: BorderRadius.circular(14), child: Row(children: [
      IconButton(onPressed: onPrev, icon: const Text('‹', style: TextStyle(fontSize: 20, color: AppColors.caramel, fontWeight: FontWeight.bold))),
      Expanded(child: Text('${year}年 ${month}月', textAlign: TextAlign.center, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textDark))),
      IconButton(onPressed: onNext, icon: const Text('›', style: TextStyle(fontSize: 20, color: AppColors.caramel, fontWeight: FontWeight.bold))),
    ]));
  }
}

class _DonutCard extends StatelessWidget {
  final AppProvider provider;
  const _DonutCard({required this.provider});
  @override
  Widget build(BuildContext context) {
    final totals = provider.categoryTotals;
    final total = provider.expenseTotal;
    return PetoCard(child: Row(children: [
      SizedBox(width: 120, height: 120, child: total > 0
          ? PieChart(PieChartData(sectionsSpace: 2, centerSpaceRadius: 35,
              sections: totals.entries.map((e) => PieChartSectionData(color: Color(e.key.colorValue), value: e.value.toDouble(), radius: 30, showTitle: false)).toList()))
          : Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Text('¥0', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: AppColors.textDark)),
              const Text('今月合計', style: TextStyle(fontSize: 10, color: AppColors.textLight)),
            ]))),
      if (total > 0) ...[
        Container(width: 1, height: 100, color: AppColors.caramelPale, margin: const EdgeInsets.symmetric(horizontal: 16)),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('¥${_fmt(total)}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: AppColors.textDark)),
          const Text('今月合計', style: TextStyle(fontSize: 10, color: AppColors.textLight)),
          const SizedBox(height: 8),
          ...totals.entries.map((e) => Padding(padding: const EdgeInsets.only(bottom: 5), child: Row(children: [
            Container(width: 10, height: 10, decoration: BoxDecoration(color: Color(e.key.colorValue), shape: BoxShape.circle)),
            const SizedBox(width: 6),
            Expanded(child: Text(e.key.label, style: const TextStyle(fontSize: 12, color: AppColors.textMid))),
            Text('¥${_fmt(e.value)}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
            Text(' ${(e.value * 100 ~/ total)}%', style: const TextStyle(fontSize: 10, color: AppColors.textLight)),
          ]))),
        ])),
      ] else
        const Expanded(child: Center(child: Text('支出を追加してみよう', style: TextStyle(color: AppColors.textLight)))),
    ]));
  }
}

class _CompareCard extends StatelessWidget {
  final AppProvider provider;
  final List<MonthTotal> pastTotals;
  const _CompareCard({required this.provider, required this.pastTotals});
  @override
  Widget build(BuildContext context) {
    final current = MonthTotal(provider.expenseMonth, provider.expenseTotal);
    final allMonths = [...pastTotals, current];
    final maxVal = allMonths.map((m) => m.total).fold(0, (a, b) => a > b ? a : b);
    if (maxVal == 0) return const SizedBox.shrink();
    return PetoCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('📊 月別比較', style: TextStyle(fontSize: 12, color: AppColors.textMid)),
      const SizedBox(height: 12),
      ...allMonths.map((m) {
        final isCurrent = m.month == provider.expenseMonth;
        return Padding(padding: const EdgeInsets.only(bottom: 8), child: Row(children: [
          SizedBox(width: 32, child: Text('${m.month}月', style: TextStyle(fontSize: 11, color: isCurrent ? AppColors.caramel : AppColors.textLight, fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal))),
          Expanded(child: ClipRRect(borderRadius: BorderRadius.circular(10), child: LinearProgressIndicator(
            value: maxVal > 0 ? m.total / maxVal : 0,
            minHeight: 20, backgroundColor: const Color(0xFFF5EDE4),
            valueColor: AlwaysStoppedAnimation(isCurrent ? AppColors.caramel : const Color(0xFFD4B896)),
          ))),
          const SizedBox(width: 10),
          SizedBox(width: 60, child: Text('¥${_fmt(m.total)}', style: TextStyle(fontSize: 11, fontWeight: isCurrent ? FontWeight.w900 : FontWeight.normal, color: isCurrent ? AppColors.caramel : AppColors.textDark), textAlign: TextAlign.end)),
        ]));
      }),
    ]));
  }
}

class _ExpenseCard extends StatelessWidget {
  final Expense expense;
  const _ExpenseCard({required this.expense});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
      child: PetoCard(
        onTap: () {},
        onLongPress: () => _showOptions(context),
        child: Row(children: [
          Container(width: 40, height: 40, decoration: BoxDecoration(color: Color(expense.category.colorValue).withOpacity(0.12), borderRadius: BorderRadius.circular(12)),
            child: Center(child: Text(expense.category.emoji, style: const TextStyle(fontSize: 18)))),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(expense.category.label, style: const TextStyle(fontSize: 11, color: AppColors.textLight)),
            Text(expense.memo.isEmpty ? '（メモなし）' : expense.memo, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textDark)),
            Text(DateFormat('M月d日').format(expense.date), style: const TextStyle(fontSize: 11, color: AppColors.textLight)),
          ])),
          Text('¥${_fmt(expense.amount)}', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: AppColors.textDark)),
        ]),
      ),
    );
  }

  void _showOptions(BuildContext context) {
    showModalBottomSheet(context: context, builder: (ctx) => SafeArea(child: Column(mainAxisSize: MainAxisSize.min, children: [
      ListTile(leading: const Icon(Icons.edit, color: AppColors.caramel), title: const Text('編集'), onTap: () {
        Navigator.pop(ctx);
        showModalBottomSheet(context: context, isScrollControlled: true, backgroundColor: Colors.transparent, builder: (_) => _EditExpenseSheet(expense: expense));
      }),
      ListTile(leading: const Icon(Icons.delete, color: Colors.red), title: const Text('削除', style: TextStyle(color: Colors.red)), onTap: () {
        Navigator.pop(ctx);
        context.read<AppProvider>().deleteExpense(expense.id!);
      }),
    ])));
  }
}

class _AddExpenseSheet extends StatefulWidget {
  const _AddExpenseSheet();
  @override
  State<_AddExpenseSheet> createState() => _AddExpenseSheetState();
}

class _AddExpenseSheetState extends State<_AddExpenseSheet> {
  ExpenseCategory _cat = ExpenseCategory.food;
  final _amountCtrl = TextEditingController();
  final _memoCtrl = TextEditingController();
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      padding: EdgeInsets.only(left: 20, right: 20, top: 20, bottom: MediaQuery.of(context).viewInsets.bottom + 40),
      child: SingleChildScrollView(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('💰 支出を追加', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textDark)),
        const SizedBox(height: 20),
        const Text('カテゴリ', style: TextStyle(fontSize: 12, color: AppColors.textLight)),
        const SizedBox(height: 8),
        Wrap(spacing: 8, runSpacing: 8, children: ExpenseCategory.values.map((cat) => FilterChip(
          label: Text('${cat.emoji} ${cat.label}'), selected: _cat == cat,
          onSelected: (_) => setState(() => _cat = cat),
          selectedColor: AppColors.caramel,
          labelStyle: TextStyle(color: _cat == cat ? Colors.white : AppColors.textMid, fontSize: 12),
        )).toList()),
        const SizedBox(height: 16),
        const Text('金額（円）', style: TextStyle(fontSize: 12, color: AppColors.textLight)),
        const SizedBox(height: 6),
        TextField(controller: _amountCtrl, keyboardType: TextInputType.number, inputFormatters: [FilteringTextInputFormatter.digitsOnly], decoration: const InputDecoration(hintText: '例：3500')),
        const SizedBox(height: 14),
        const Text('メモ（任意）', style: TextStyle(fontSize: 12, color: AppColors.textLight)),
        const SizedBox(height: 6),
        TextField(controller: _memoCtrl, decoration: const InputDecoration(hintText: '例：ロイヤルカナン 3kg')),
        const SizedBox(height: 20),
        PetoButton(label: '✓ 保存する', onPressed: () async {
          final amt = int.tryParse(_amountCtrl.text) ?? 0;
          if (amt <= 0) return;
          await context.read<AppProvider>().addExpense(category: _cat, amount: amt, memo: _memoCtrl.text);
          if (mounted) Navigator.pop(context);
        }),
      ])),
    );
  }
}

class _EditExpenseSheet extends StatefulWidget {
  final Expense expense;
  const _EditExpenseSheet({required this.expense});
  @override
  State<_EditExpenseSheet> createState() => _EditExpenseSheetState();
}

class _EditExpenseSheetState extends State<_EditExpenseSheet> {
  late ExpenseCategory _cat;
  late TextEditingController _amountCtrl;
  late TextEditingController _memoCtrl;
  @override
  void initState() {
    super.initState();
    _cat = widget.expense.category;
    _amountCtrl = TextEditingController(text: widget.expense.amount.toString());
    _memoCtrl = TextEditingController(text: widget.expense.memo);
  }
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      padding: EdgeInsets.only(left: 20, right: 20, top: 20, bottom: MediaQuery.of(context).viewInsets.bottom + 40),
      child: SingleChildScrollView(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('✏️ 支出を編集', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textDark)),
        const SizedBox(height: 20),
        Wrap(spacing: 8, runSpacing: 8, children: ExpenseCategory.values.map((cat) => FilterChip(
          label: Text('${cat.emoji} ${cat.label}'), selected: _cat == cat,
          onSelected: (_) => setState(() => _cat = cat),
          selectedColor: AppColors.caramel,
          labelStyle: TextStyle(color: _cat == cat ? Colors.white : AppColors.textMid, fontSize: 12),
        )).toList()),
        const SizedBox(height: 16),
        TextField(controller: _amountCtrl, keyboardType: TextInputType.number, inputFormatters: [FilteringTextInputFormatter.digitsOnly], decoration: const InputDecoration(labelText: '金額（円）')),
        const SizedBox(height: 14),
        TextField(controller: _memoCtrl, decoration: const InputDecoration(labelText: 'メモ')),
        const SizedBox(height: 20),
        PetoButton(label: '✓ 保存する', onPressed: () async {
          final amt = int.tryParse(_amountCtrl.text) ?? 0;
          if (amt <= 0) return;
          await context.read<AppProvider>().updateExpense(widget.expense.copyWith(category: _cat, amount: amt, memo: _memoCtrl.text));
          if (mounted) Navigator.pop(context);
        }),
      ])),
    );
  }
}

String _fmt(int v) => NumberFormat('#,###').format(v);
