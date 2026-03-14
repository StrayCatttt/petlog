import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/models.dart';
import 'database.dart';

class MonthTotal { final int month; final int total; MonthTotal(this.month, this.total); }

class AppProvider extends ChangeNotifier {
  final _db = AppDatabase.instance;

  List<Pet> _pets = [];
  int _activePetIndex = 0;
  int get activePetIndex => _activePetIndex;

  List<DiaryEntry> _diaryEntries = [];
  List<Expense> _expenses = [];
  int _expenseYear = DateTime.now().year;
  int _expenseMonth = DateTime.now().month;
  bool _isPro = false;
  int _quotaUsed = 0, _quotaBonus = 0;
  bool _rewardWatched = false;

  List<Pet> get pets => _pets;
  List<Pet> get activePets => _pets.where((p) => !p.hasPassed).toList();
  List<Pet> get passedPets => _pets.where((p) => p.hasPassed).toList();
  Pet? get activePet => activePets.isEmpty ? null : activePets[_activePetIndex.clamp(0, activePets.length - 1)];
  List<DiaryEntry> get diaryEntries => _diaryEntries;
  List<Expense> get expenses => _expenses;
  int get expenseYear => _expenseYear;
  int get expenseMonth => _expenseMonth;
  bool get isPro => _isPro;
  int get quotaUsed => _quotaUsed;
  int get quotaBonus => _quotaBonus;
  bool get rewardWatched => _rewardWatched;
  int get quotaTotal => _isPro ? 30 : 1 + _quotaBonus;
  int get quotaRemaining => (quotaTotal - _quotaUsed).clamp(0, 30);

  Future<void> init() async { await _loadPrefs(); await _loadPets(); }

  Future<void> _loadPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    _isPro = prefs.getBool('is_pro') ?? false;
    final today = _todayStr();
    if (prefs.getString('quota_date') == today) {
      _quotaUsed = prefs.getInt('quota_used') ?? 0;
      _quotaBonus = prefs.getInt('quota_bonus') ?? 0;
      _rewardWatched = prefs.getString('reward_date') == today;
    } else { _quotaUsed = 0; _quotaBonus = 0; _rewardWatched = false; }
  }

  Future<void> _loadPets() async {
    _pets = await _db.getAllPets();
    final prefs = await SharedPreferences.getInstance();
    final savedId = prefs.getInt('active_pet_id') ?? 0;
    final idx = activePets.indexWhere((p) => p.id == savedId);
    _activePetIndex = idx >= 0 ? idx : 0;
    if (activePet != null) await _loadDiary();
    await loadExpenses();
    notifyListeners();
  }

  Future<void> setActivePet(int index) async {
    _activePetIndex = index;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('active_pet_id', activePet?.id ?? 0);
    await _loadDiary();
    await loadExpenses();
    notifyListeners();
  }

  Future<void> addPet(Pet pet) async {
    final id = await _db.insertPet(pet);
    _pets = await _db.getAllPets();
    _activePetIndex = activePets.indexWhere((p) => p.id == id).clamp(0, activePets.length - 1);
    await _loadDiary();
    notifyListeners();
  }

  Future<void> updatePet(Pet pet) async {
    await _db.updatePet(pet);
    _pets = await _db.getAllPets();
    notifyListeners();
  }

  Future<void> deletePet(int id) async {
    await _db.deletePet(id);
    _pets = await _db.getAllPets();
    _activePetIndex = 0;
    _diaryEntries = [];
    if (activePet != null) await _loadDiary();
    notifyListeners();
  }

  Future<void> _loadDiary() async {
    if (activePet?.id == null) return;
    _diaryEntries = await _db.getEntriesByPet(activePet!.id!);
  }

  Future<DiaryEntry?> getRandomMemory() async {
    if (activePet?.id == null) return null;
    return _db.getRandomEntry(activePet!.id!);
  }

  Set<DateTime> getDatesWithEntries() =>
      _diaryEntries.map((e) => DateTime(e.date.year, e.date.month, e.date.day)).toSet();

  Future<void> addDiaryEntry({required DiaryMood mood, required String body, required List<String> photoUris}) async {
    if (activePet?.id == null) return;
    final allowed = _isPro ? photoUris : photoUris.take(quotaRemaining).toList();
    await _db.insertEntry(DiaryEntry(
      petId: activePet!.id!, date: DateTime.now(), mood: mood, body: body,
      photoUris: allowed, createdAt: DateTime.now(), updatedAt: DateTime.now()));
    if (!_isPro && allowed.isNotEmpty) {
      _quotaUsed = (_quotaUsed + allowed.length).clamp(0, quotaTotal);
      await _saveQuota();
    }
    await _loadDiary();
    notifyListeners();
  }

  Future<void> updateDiaryEntry(DiaryEntry entry) async {
    await _db.updateEntry(entry);
    await _loadDiary();
    notifyListeners();
  }

  Future<void> deleteEntry(int id) async {
    await _db.deleteEntry(id);
    await _loadDiary();
    notifyListeners();
  }

  // 支出 - 全ペット + 共通費用を表示
  Future<void> loadExpenses() async {
    final ids = activePets.map((p) => p.id!).where((id) => id != null).toList();
    _expenses = await _db.getExpensesInMonth(ids, _expenseYear, _expenseMonth);
    notifyListeners();
  }

  Future<void> navigateExpenseMonth(int dir) async {
    final d = DateTime(_expenseYear, _expenseMonth + dir);
    _expenseYear = d.year; _expenseMonth = d.month;
    await loadExpenses();
  }

  Future<void> addExpense({required ExpenseCategory category, required int amount, required String memo, int? petId, bool isShared = false}) async {
    await _db.insertExpense(Expense(
      petId: isShared ? null : (petId ?? activePet?.id),
      date: DateTime.now(), category: category, amount: amount,
      memo: memo, createdAt: DateTime.now()));
    await loadExpenses();
  }

  Future<void> deleteExpense(int id) async { await _db.deleteExpense(id); await loadExpenses(); }
  Future<void> updateExpense(Expense expense) async { await _db.updateExpense(expense); await loadExpenses(); }

  Future<List<MonthTotal>> getPast3MonthTotals() async {
    final ids = activePets.map((p) => p.id!).toList();
    final result = <MonthTotal>[];
    for (int i = 3; i >= 1; i--) {
      final d = DateTime(_expenseYear, _expenseMonth - i);
      final items = await _db.getExpensesInMonth(ids, d.year, d.month);
      result.add(MonthTotal(d.month, items.fold(0, (s, e) => s + e.amount)));
    }
    return result;
  }

  Map<ExpenseCategory, int> get categoryTotals {
    final map = <ExpenseCategory, int>{};
    for (final e in _expenses) { map[e.category] = (map[e.category] ?? 0) + e.amount; }
    return map;
  }

  int get expenseTotal => _expenses.fold(0, (s, e) => s + e.amount);

  Future<void> applyRewardBonus() async {
    _quotaBonus = 3; _rewardWatched = true;
    await _saveQuota(); notifyListeners();
  }

  Future<void> _saveQuota() async {
    final prefs = await SharedPreferences.getInstance();
    final today = _todayStr();
    await prefs.setString('quota_date', today);
    await prefs.setInt('quota_used', _quotaUsed);
    await prefs.setInt('quota_bonus', _quotaBonus);
    if (_rewardWatched) await prefs.setString('reward_date', today);
  }

  Future<void> setIsPro(bool value) async {
    _isPro = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_pro', value);
    notifyListeners();
  }

  String _todayStr() { final n = DateTime.now(); return '${n.year}-${n.month}-${n.day}'; }
}
