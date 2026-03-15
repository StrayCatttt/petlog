import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/models.dart';
import 'database.dart';

class MonthTotal { final int month; final int total; MonthTotal(this.month,this.total); }

class AppProvider extends ChangeNotifier {
  final _db = AppDatabase.instance;
  List<Pet> _pets = [];
  int _activePetIndex = 0;
  int get activePetIndex => _activePetIndex;
  List<DiaryEntry> _allDiaryEntries = []; // 全ペット分
  List<Expense> _expenses = [];
  List<PetSchedule> _schedules = [];
  int _expenseYear=DateTime.now().year, _expenseMonth=DateTime.now().month;
  int? _expensePetFilter; // null=全て
  int? get expensePetFilter => _expensePetFilter;
  bool _isPro=false;
  int _quotaUsed=0, _quotaBonus=0;
  // ✅ 広告を「見始めた」フラグ（完了まで保存しない）
  bool _rewardInProgress=false;
  bool _rewardWatched=false;
  DiarySort _diarySort=DiarySort.dateDesc;
  DiarySort get diarySort => _diarySort;
  NotificationSettings _notifSettings=const NotificationSettings();
  NotificationSettings get notifSettings => _notifSettings;

  List<Pet> get pets => _pets;
  List<Pet> get activePets => _pets.where((p)=>!p.hasPassed).toList();
  List<Pet> get passedPets => _pets.where((p)=>p.hasPassed).toList();
  Pet? get activePet => activePets.isEmpty?null:activePets[_activePetIndex.clamp(0,activePets.length-1)];

  // 表示用日記（アクティブペット＋共通、ソート済み）
  List<DiaryEntry> get diaryEntries {
    final petId = activePet?.id;
    final list = petId==null ? <DiaryEntry>[] :
      _allDiaryEntries.where((e)=>e.petId==petId||e.isShared).toList();
    switch(_diarySort) {
      case DiarySort.dateDesc: list.sort((a,b)=>b.date.compareTo(a.date)); break;
      case DiarySort.dateAsc:  list.sort((a,b)=>a.date.compareTo(b.date)); break;
      case DiarySort.petName:  list.sort((a,b)=>_petName(a.petId).compareTo(_petName(b.petId))); break;
    }
    return list;
  }
  String _petName(int petId) => petId==-1?'共通':_pets.firstWhere((p)=>p.id==petId,orElse:()=>Pet(name:'',createdAt:DateTime.now())).name;

  List<Expense> get expenses => _expenses;
  List<PetSchedule> get schedules => _schedules;
  int get expenseYear => _expenseYear; int get expenseMonth => _expenseMonth;
  bool get isPro => _isPro;
  int get quotaUsed => _quotaUsed; int get quotaBonus => _quotaBonus;
  bool get rewardWatched => _rewardWatched;
  int get quotaTotal => _isPro?30:1+_quotaBonus;
  int get quotaRemaining => (quotaTotal-_quotaUsed).clamp(0,30);

  Future<void> init() async { await _loadPrefs(); await _loadPets(); }

  Future<void> _loadPrefs() async {
    final p=await SharedPreferences.getInstance();
    _isPro=p.getBool('is_pro')??false;
    final today=_todayStr();
    if(p.getString('quota_date')==today) {
      _quotaUsed=p.getInt('quota_used')??0;
      _quotaBonus=p.getInt('quota_bonus')??0;
      _rewardWatched=p.getString('reward_date')==today;
    } else { _quotaUsed=0; _quotaBonus=0; _rewardWatched=false; }
    _notifSettings=NotificationSettings(
      vaccineReminder:p.getBool('notif_vaccine')??true,
      vaccineDaysBefore:p.getInt('notif_vaccine_days')??7,
      anniversaryNotify:p.getBool('notif_anniversary')??true,
      notifySound:p.getString('notif_sound')??'default',
      defaultNotifyMinutesBefore:p.getInt('notif_default_minutes')??30,
    );
  }

  Future<void> saveNotifSettings(NotificationSettings s) async {
    _notifSettings=s;
    final p=await SharedPreferences.getInstance();
    await p.setBool('notif_vaccine',s.vaccineReminder);
    await p.setInt('notif_vaccine_days',s.vaccineDaysBefore);
    await p.setBool('notif_anniversary',s.anniversaryNotify);
    await p.setString('notif_sound',s.notifySound);
    await p.setInt('notif_default_minutes',s.defaultNotifyMinutesBefore);
    notifyListeners();
  }

  Future<void> _loadPets() async {
    _pets=await _db.getAllPets();
    final p=await SharedPreferences.getInstance();
    final savedId=p.getInt('active_pet_id')??0;
    final idx=activePets.indexWhere((p)=>p.id==savedId);
    _activePetIndex=idx>=0?idx:0;
    await _loadAllDiary();
    await loadExpenses();
    await _loadSchedules();
    notifyListeners();
  }

  Future<void> setActivePet(int index) async {
    _activePetIndex=index;
    final p=await SharedPreferences.getInstance();
    await p.setInt('active_pet_id',activePet?.id??0);
    await loadExpenses();
    notifyListeners();
  }

  Future<void> addPet(Pet pet) async {
    final id=await _db.insertPet(pet); _pets=await _db.getAllPets();
    _activePetIndex=activePets.indexWhere((p)=>p.id==id).clamp(0,activePets.isEmpty?0:activePets.length-1);
    await _loadAllDiary(); notifyListeners();
  }
  Future<void> updatePet(Pet pet) async { await _db.updatePet(pet); _pets=await _db.getAllPets(); notifyListeners(); }
  Future<void> deletePet(int id) async {
    await _db.deletePet(id); _pets=await _db.getAllPets(); _activePetIndex=0;
    await _loadAllDiary(); notifyListeners();
  }

  // ✅ 全ペット分の日記をまとめてロード
  Future<void> _loadAllDiary() async {
    _allDiaryEntries=await _db.getAllEntries();
  }

  Future<DiaryEntry?> getRandomMemory() async {
    if(activePet?.id==null) return null;
    return _db.getRandomEntryForPet(activePet!.id!);
  }
  Future<DiaryEntry?> getLatestEntry() async {
    if(activePet?.id==null) return null;
    return _db.getLatestEntryForPet(activePet!.id!);
  }

  Set<DateTime> getDatesWithEntries() {
    final petId=activePet?.id; if(petId==null) return {};
    return _allDiaryEntries.where((e)=>e.petId==petId||e.isShared).map((e)=>DateTime(e.date.year,e.date.month,e.date.day)).toSet();
  }
  Set<DateTime> getDatesWithSchedules() => _schedules.map((s)=>DateTime(s.dateTime.year,s.dateTime.month,s.dateTime.day)).toSet();

  void setDiarySort(DiarySort sort) { _diarySort=sort; notifyListeners(); }

  // ✅ petId=-1は共通
  Future<void> addDiaryEntry({required int petId, required DiaryMood mood, required String body, required List<String> photoUris}) async {
    final allowed=_isPro?photoUris:photoUris.take(quotaRemaining).toList();
    await _db.insertEntry(DiaryEntry(petId:petId,date:DateTime.now(),mood:mood,body:body,photoUris:allowed,createdAt:DateTime.now(),updatedAt:DateTime.now()));
    // ✅ 保存成功後にのみ枠消費
    if(!_isPro&&allowed.isNotEmpty) { _quotaUsed=(_quotaUsed+allowed.length).clamp(0,quotaTotal); await _saveQuota(); }
    await _loadAllDiary(); notifyListeners();
  }
  Future<void> updateDiaryEntry(DiaryEntry e) async { await _db.updateEntry(e); await _loadAllDiary(); notifyListeners(); }
  Future<void> deleteEntry(int id) async { await _db.deleteEntry(id); await _loadAllDiary(); notifyListeners(); }

  // ✅ ウィジェット用：特定ペットの全日記（写真付き優先）
  Future<List<DiaryEntry>> getEntriesForWidget(int petId) async =>
    _allDiaryEntries.where((e)=>(e.petId==petId||e.isShared)&&e.photoUris.isNotEmpty).toList();

  // Schedules
  Future<void> _loadSchedules() async {
    final now=DateTime.now();
    _schedules=await _db.getSchedulesInRange(DateTime(now.year,now.month-1,1),DateTime(now.year,now.month+3,1));
  }
  Future<List<PetSchedule>> getSchedulesOnDay(DateTime day) => _db.getSchedulesOnDay(day);
  Future<void> addSchedule(PetSchedule s) async { await _db.insertSchedule(s); await _loadSchedules(); notifyListeners(); }
  Future<void> updateSchedule(PetSchedule s) async { await _db.updateSchedule(s); await _loadSchedules(); notifyListeners(); }
  Future<void> deleteSchedule(int id) async { await _db.deleteSchedule(id); await _loadSchedules(); notifyListeners(); }

  // ✅ 支出：フィルタ設定 + 追加時にフィルタのpetIdを使う
  void setExpensePetFilter(int? petId) { _expensePetFilter=petId; loadExpenses(); }

  Future<void> loadExpenses() async {
    if(activePets.isEmpty) { _expenses=[]; notifyListeners(); return; }
    if(_expensePetFilter!=null) {
      _expenses=await _db.getExpensesByPet(_expensePetFilter!,_expenseYear,_expenseMonth);
    } else {
      final ids=activePets.map((p)=>p.id!).toList();
      _expenses=await _db.getExpensesInMonth(ids,_expenseYear,_expenseMonth);
    }
    notifyListeners();
  }
  Future<void> navigateExpenseMonth(int dir) async { final d=DateTime(_expenseYear,_expenseMonth+dir); _expenseYear=d.year; _expenseMonth=d.month; await loadExpenses(); }

  // ✅ petId を明示的に受け取る（フィルタから自動決定）
  Future<void> addExpense({required ExpenseCategory category, required int amount, required String memo, required int? petId, required bool isShared}) async {
    await _db.insertExpense(Expense(
      petId: isShared ? null : petId,
      date:DateTime.now(), category:category, amount:amount, memo:memo, createdAt:DateTime.now()));
    await loadExpenses();
  }
  Future<void> deleteExpense(int id) async { await _db.deleteExpense(id); await loadExpenses(); }
  Future<void> updateExpense(Expense e) async { await _db.updateExpense(e); await loadExpenses(); }
  Future<List<MonthTotal>> getPast3MonthTotals() async {
    final ids=activePets.map((p)=>p.id!).toList();
    final result=<MonthTotal>[];
    for(int i=3;i>=1;i--) { final d=DateTime(_expenseYear,_expenseMonth-i); final items=await _db.getExpensesInMonth(ids,d.year,d.month); result.add(MonthTotal(d.month,items.fold(0,(s,e)=>s+e.amount))); }
    return result;
  }
  Map<ExpenseCategory,int> get categoryTotals { final m=<ExpenseCategory,int>{}; for(final e in _expenses) m[e.category]=(m[e.category]??0)+e.amount; return m; }
  int get expenseTotal => _expenses.fold(0,(s,e)=>s+e.amount);

  // ✅ 写真枠：広告視聴完了時のみ付与（途中キャンセルは付与しない）
  Future<void> applyRewardBonus() async {
    _quotaBonus=3; _rewardWatched=true; _rewardInProgress=false;
    await _saveQuota(); notifyListeners();
  }
  Future<void> _saveQuota() async {
    final p=await SharedPreferences.getInstance(); final today=_todayStr();
    await p.setString('quota_date',today); await p.setInt('quota_used',_quotaUsed);
    await p.setInt('quota_bonus',_quotaBonus);
    if(_rewardWatched) await p.setString('reward_date',today);
  }

  Future<void> setIsPro(bool value) async { _isPro=value; final p=await SharedPreferences.getInstance(); await p.setBool('is_pro',value); notifyListeners(); }

  // ✅ エクスポート（わかりやすい説明付き）
  Future<void> exportData() async {
    final data=await _db.exportAll();
    final json=const JsonEncoder.withIndent('  ').convert(data);
    final dir=await getTemporaryDirectory();
    final dateStr='${DateTime.now().year}${DateTime.now().month.toString().padLeft(2,'0')}${DateTime.now().day.toString().padLeft(2,'0')}';
    final file=File('${dir.path}/petlog_backup_$dateStr.json');
    await file.writeAsString(json);
    await Share.shareXFiles([XFile(file.path)], subject:'ぺとろぐ バックアップ $dateStr', text:'このファイルを大切に保存してください。\n新しいスマホでぺとろぐを開いて「データを引き継ぐ」からこのファイルを選択すると復元できます。');
  }

  Future<bool> importData(String jsonStr) async {
    try { final data=jsonDecode(jsonStr) as Map<String,dynamic>; await _db.importAll(data); await _loadPets(); return true; }
    catch(e) { return false; }
  }

  String _todayStr() { final n=DateTime.now(); return '${n.year}-${n.month}-${n.day}'; }
}
