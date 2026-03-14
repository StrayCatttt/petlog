import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/models.dart';
import 'database.dart';

class AppProvider extends ChangeNotifier {
  final _db = AppDatabase.instance;

  // ─── State ─────────────────────────────────────────
  List<Pet> _pets = [];
  int _activePetIndex = 0;
  List<DiaryEntry> _diaryEntries = [];
  List<Expense> _expenses = [];
  int _expenseYear  = DateTime.now().year;
  int _expenseMonth = DateTime.now().month;
  bool _isPro = false;

  // 写真枠
  int _quotaUsed   = 0;
  int _quotaBonus  = 0;
  bool _rewardWatched = false;

  // ─── Getters ───────────────────────────────────────
  List<Pet> get pets => _pets;
  Pet? get activePet => _pets.isEmpty ? null : _pets[_activePetIndex];
  List<DiaryEntry> get diaryEntries => _diaryEntries;
  List<Expense> get expenses => _expenses;
  int get expenseYear  => _expenseYear;
  int get expenseMonth => _expenseMonth;
  bool get isPro => _isPro;
  int get quotaUsed  => _quotaUsed;
  int get quotaBonus => _quotaBonus;
  bool get rewardWatched => _rewardWatched;
  int get quotaTotal => _isPro ? 30 : 1 + _quotaBonus;
  int get quotaRemaining => (quotaTotal - _quotaUsed).clamp(0, 30);

  // ─── Init ──────────────────────────────────────────
  Future<void> init() async {
    await _loadPrefs();
    await _loadPets();
  }

  Future<void> _loadPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    _isPro = prefs.getBool('is_pro') ?? false;
    final today = _todayStr();
    final savedDate = prefs.getString('quota_date') ?? '';
    if (savedDate == today) {
      _quotaUsed  = prefs.getInt('quota_used')  ?? 0;
      _quotaBonus = prefs.getInt('quota_bonus') ?? 0;
      _rewardWatched = prefs.getString('reward_date') == today;
    }
  }

  // ─── Pet ───────────────────────────────────────────
  Future<void> _loadPets() async {
    _pets = await _db.getAllPets();
    final prefs = await SharedPreferences.getInstance();
    final savedId = prefs.getInt('active_pet_id') ?? 0;
    _activePetIndex = _pets.indexWhere((p) => p.id == savedId).clamp(0, _pets.isEmpty ? 0 : _pets.length - 1);
    if (activePet != null) await _loadDiary();
    notifyListeners();
  }

  Future<void> setActivePet(int index) async {
    _activePetIndex = index;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('active_pet_id', activePet?.id ?? 0);
    await _loadDiary();
    notifyListeners();
  }

  Future<void> addPet(Pet pet) async {
    final id = await _db.insertPet(pet);
    _pets = await _db.getAllPets();
    _activePetIndex = _pets.indexWhere((p) => p.id == id).clamp(0, _pets.length - 1);
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
    if (activePet != null) await _loadDiary();
    notifyListeners();
  }

  // ─── Diary ─────────────────────────────────────────
  Future<void> _loadDiary() async {
    if (activePet == null) return;
    _diaryEntries = await _db.getEntriesByPet(activePet!.id!);
  }

  Future<DiaryEntry?> getRandomMemory() async {
    if (activePet == null) return null;
    return _db.getRandomEntry(activePet!.id!);
  }

  Set<DateTime> getDatesWithEntries() =>
      _diaryEntries.map((e) => DateTime(e.date.year, e.date.month, e.date.day)).toSet();

  Future<void> addDiaryEntry({
    required DiaryMood mood,
    required String body,
    required List<String> photoUris,
  }) async {
    if (activePet == null) return;
    final entry = DiaryEntry(
      petId: activePet!.id!,
      date: DateTime.now(),
      mood: mood,
      body: body,
      photoUris: photoUris,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    await _db.insertEntry(entry);
    // 写真枠カウント
    _quotaUsed += photoUris.length;
    await _saveQuota();
    await _loadDiary();
    notifyListeners();
  }

  Future<void> deleteEntry(int id) async {
    await _db.deleteEntry(id);
    await _loadDiary();
    notifyListeners();
  }

  // ─── Expense ───────────────────────────────────────
  Future<void> loadExpenses() async {
    if (activePet == null) return;
    _expenses = await _db.getExpensesInMonth(activePet!.id!, _expenseYear, _expenseMonth);
    notifyListeners();
  }

  Future<void> navigateExpenseMonth(int dir) async {
    final d = DateTime(_expenseYear, _expenseMonth + dir);
    _expenseYear  = d.year;
    _expenseMonth = d.month;
    await loadExpenses();
  }

  Future<void> addExpense({
    required ExpenseCategory category,
    required int amount,
    required String memo,
  }) async {
    if (activePet == null) return;
    final expense = Expense(
      petId: activePet!.id!,
      date: DateTime.now(),
      category: category,
      amount: amount,
      memo: memo,
      createdAt: DateTime.now(),
    );
    await _db.insertExpense(expense);
    await loadExpenses();
  }

  Future<void> deleteExpense(int id) async {
    await _db.deleteExpense(id);
    await loadExpenses();
  }

  Map<ExpenseCategory, int> get categoryTotals {
    final map = <ExpenseCategory, int>{};
    for (final e in _expenses) {
      map[e.category] = (map[e.category] ?? 0) + e.amount;
    }
    return map;
  }

  int get expenseTotal => _expenses.fold(0, (sum, e) => sum + e.amount);

  // ─── 写真枠 ─────────────────────────────────────────
  Future<void> applyRewardBonus() async {
    _quotaBonus = 3;
    _rewardWatched = true;
    await _saveQuota();
    notifyListeners();
  }

  Future<void> _saveQuota() async {
    final prefs = await SharedPreferences.getInstance();
    final today = _todayStr();
    await prefs.setString('quota_date', today);
    await prefs.setInt('quota_used', _quotaUsed);
    await prefs.setInt('quota_bonus', _quotaBonus);
    if (_rewardWatched) await prefs.setString('reward_date', today);
  }

  // ─── Pro ───────────────────────────────────────────
  Future<void> setIsPro(bool value) async {
    _isPro = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_pro', value);
    notifyListeners();
  }

  String _todayStr() {
    final now = DateTime.now();
    return '${now.year}-${now.month}-${now.day}';
  }
}
