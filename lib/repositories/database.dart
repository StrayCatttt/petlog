import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/models.dart';

class AppDatabase {
  static final AppDatabase instance = AppDatabase._();
  AppDatabase._();
  Database? _db;
  Future<Database> get db async { _db??=await _initDb(); return _db!; }

  Future<Database> _initDb() async {
    final p = await getDatabasesPath();
    return openDatabase(join(p,'petlog.db'), version:3,
      onCreate:(db,v)=>_createAll(db),
      onUpgrade:(db,old,nw) async {
        if(old<2){ try{await db.execute('ALTER TABLE pets ADD COLUMN passedDate INTEGER');}catch(_){} }
        if(old<3){ try{await db.execute('CREATE TABLE IF NOT EXISTS schedules (id INTEGER PRIMARY KEY AUTOINCREMENT, petId INTEGER, date INTEGER NOT NULL, title TEXT NOT NULL, note TEXT, notifyEnabled INTEGER DEFAULT 1, createdAt INTEGER NOT NULL)');}catch(_){} }
      });
  }

  Future<void> _createAll(Database db) async {
    await db.execute('CREATE TABLE pets (id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT NOT NULL, species TEXT NOT NULL, gender TEXT NOT NULL, birthDate INTEGER, welcomeDate INTEGER, passedDate INTEGER, profilePhotoPath TEXT, memo TEXT DEFAULT \'\', createdAt INTEGER NOT NULL)');
    await db.execute('CREATE TABLE diary_entries (id INTEGER PRIMARY KEY AUTOINCREMENT, petId INTEGER NOT NULL, date INTEGER NOT NULL, mood TEXT NOT NULL, body TEXT DEFAULT \'\', photoUris TEXT DEFAULT \'\', createdAt INTEGER NOT NULL, updatedAt INTEGER NOT NULL)');
    await db.execute('CREATE TABLE expenses (id INTEGER PRIMARY KEY AUTOINCREMENT, petId INTEGER, date INTEGER NOT NULL, category TEXT NOT NULL, amount INTEGER NOT NULL, memo TEXT DEFAULT \'\', createdAt INTEGER NOT NULL)');
    await db.execute('CREATE TABLE schedules (id INTEGER PRIMARY KEY AUTOINCREMENT, petId INTEGER, date INTEGER NOT NULL, title TEXT NOT NULL, note TEXT, notifyEnabled INTEGER DEFAULT 1, createdAt INTEGER NOT NULL)');
  }

  // Pets
  Future<List<Pet>> getAllPets() async => (await (await db).query('pets',orderBy:'createdAt ASC')).map(Pet.fromMap).toList();
  Future<int> insertPet(Pet pet) async { final m=pet.toMap()..remove('id'); return (await db).insert('pets',m); }
  Future<void> updatePet(Pet pet) async => (await db).update('pets',pet.toMap(),where:'id=?',whereArgs:[pet.id]);
  Future<void> deletePet(int id) async => (await db).delete('pets',where:'id=?',whereArgs:[id]);

  // Diary
  Future<List<DiaryEntry>> getEntriesByPet(int petId) async =>
    (await (await db).query('diary_entries',where:'petId=?',whereArgs:[petId],orderBy:'date DESC')).map(DiaryEntry.fromMap).toList();
  Future<DiaryEntry?> getLatestEntry(int petId) async {
    final r=await (await db).query('diary_entries',where:'petId=?',whereArgs:[petId],orderBy:'date DESC',limit:1);
    return r.isEmpty?null:DiaryEntry.fromMap(r.first);
  }
  Future<DiaryEntry?> getRandomEntry(int petId) async {
    final r=await (await db).query('diary_entries',where:'petId=?',whereArgs:[petId],orderBy:'RANDOM()',limit:1);
    return r.isEmpty?null:DiaryEntry.fromMap(r.first);
  }
  Future<int> insertEntry(DiaryEntry e) async { final m=e.toMap()..remove('id'); return (await db).insert('diary_entries',m); }
  Future<void> updateEntry(DiaryEntry e) async => (await db).update('diary_entries',e.toMap(),where:'id=?',whereArgs:[e.id]);
  Future<void> deleteEntry(int id) async => (await db).delete('diary_entries',where:'id=?',whereArgs:[id]);

  // Schedules
  Future<List<PetSchedule>> getSchedulesInRange(DateTime from, DateTime to) async {
    final r=await (await db).query('schedules',where:'date BETWEEN ? AND ?',whereArgs:[from.millisecondsSinceEpoch,to.millisecondsSinceEpoch],orderBy:'date ASC');
    return r.map(PetSchedule.fromMap).toList();
  }
  Future<List<PetSchedule>> getSchedulesOnDay(DateTime day) async {
    final from=DateTime(day.year,day.month,day.day); final to=from.add(const Duration(days:1));
    final r=await (await db).query('schedules',where:'date BETWEEN ? AND ?',whereArgs:[from.millisecondsSinceEpoch,to.millisecondsSinceEpoch]);
    return r.map(PetSchedule.fromMap).toList();
  }
  Future<int> insertSchedule(PetSchedule s) async { final m=s.toMap()..remove('id'); return (await db).insert('schedules',m); }
  Future<void> updateSchedule(PetSchedule s) async => (await db).update('schedules',s.toMap(),where:'id=?',whereArgs:[s.id]);
  Future<void> deleteSchedule(int id) async => (await db).delete('schedules',where:'id=?',whereArgs:[id]);

  // Expenses
  Future<List<Expense>> getExpensesInMonth(List<int> petIds, int year, int month) async {
    final from=DateTime(year,month,1).millisecondsSinceEpoch;
    final to=DateTime(year,month+1,1).millisecondsSinceEpoch-1;
    if(petIds.isEmpty) {
      final r=await (await db).query('expenses',where:'petId IS NULL AND date BETWEEN ? AND ?',whereArgs:[from,to],orderBy:'date DESC');
      return r.map(Expense.fromMap).toList();
    }
    final ph=petIds.map((_)=>'?').join(',');
    final r=await (await db).rawQuery('SELECT * FROM expenses WHERE (petId IN ($ph) OR petId IS NULL) AND date BETWEEN ? AND ? ORDER BY date DESC',[...petIds,from,to]);
    return r.map(Expense.fromMap).toList();
  }
  Future<List<Expense>> getExpensesByPet(int petId, int year, int month) async {
    final from=DateTime(year,month,1).millisecondsSinceEpoch;
    final to=DateTime(year,month+1,1).millisecondsSinceEpoch-1;
    final r=await (await db).query('expenses',where:'(petId=? OR petId IS NULL) AND date BETWEEN ? AND ?',whereArgs:[petId,from,to],orderBy:'date DESC');
    return r.map(Expense.fromMap).toList();
  }
  Future<int> insertExpense(Expense e) async { final m=e.toMap()..remove('id'); return (await db).insert('expenses',m); }
  Future<void> updateExpense(Expense e) async => (await db).update('expenses',e.toMap(),where:'id=?',whereArgs:[e.id]);
  Future<void> deleteExpense(int id) async => (await db).delete('expenses',where:'id=?',whereArgs:[id]);

  // バックアップ用：全データをMapで取得
  Future<Map<String,dynamic>> exportAll() async {
    return {
      'pets': (await (await db).query('pets')).toList(),
      'diary': (await (await db).query('diary_entries')).toList(),
      'expenses': (await (await db).query('expenses')).toList(),
      'schedules': (await (await db).query('schedules')).toList(),
      'exportedAt': DateTime.now().millisecondsSinceEpoch,
    };
  }

  Future<void> importAll(Map<String,dynamic> data) async {
    final d=await db;
    await d.transaction((txn) async {
      await txn.delete('pets'); await txn.delete('diary_entries');
      await txn.delete('expenses'); await txn.delete('schedules');
      for(final row in (data['pets'] as List)) await txn.insert('pets', Map<String,dynamic>.from(row));
      for(final row in (data['diary'] as List)) await txn.insert('diary_entries', Map<String,dynamic>.from(row));
      for(final row in (data['expenses'] as List)) await txn.insert('expenses', Map<String,dynamic>.from(row));
      if(data['schedules']!=null) for(final row in (data['schedules'] as List)) await txn.insert('schedules', Map<String,dynamic>.from(row));
    });
  }
}
