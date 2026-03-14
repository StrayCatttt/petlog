import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/models.dart';

class AppDatabase {
  static final AppDatabase instance = AppDatabase._();
  AppDatabase._();
  Database? _db;

  Future<Database> get db async { _db ??= await _initDb(); return _db!; }

  Future<Database> _initDb() async {
    final dbPath = await getDatabasesPath();
    return openDatabase(join(dbPath, 'petlog.db'), version: 2,
      onCreate: (db, v) async { await _createTables(db); },
      onUpgrade: (db, oldV, newV) async {
        if (oldV < 2) {
          try { await db.execute('ALTER TABLE pets ADD COLUMN passedDate INTEGER'); } catch(_) {}
          try { await db.execute('ALTER TABLE expenses ADD COLUMN petId INTEGER'); } catch(_) {}
        }
      },
    );
  }

  Future<void> _createTables(Database db) async {
    await db.execute('''CREATE TABLE pets (
      id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT NOT NULL,
      species TEXT NOT NULL, gender TEXT NOT NULL,
      birthDate INTEGER, welcomeDate INTEGER, passedDate INTEGER,
      profilePhotoPath TEXT, memo TEXT DEFAULT '', createdAt INTEGER NOT NULL)''');
    await db.execute('''CREATE TABLE diary_entries (
      id INTEGER PRIMARY KEY AUTOINCREMENT, petId INTEGER NOT NULL,
      date INTEGER NOT NULL, mood TEXT NOT NULL, body TEXT DEFAULT '',
      photoUris TEXT DEFAULT '', createdAt INTEGER NOT NULL, updatedAt INTEGER NOT NULL)''');
    await db.execute('''CREATE TABLE expenses (
      id INTEGER PRIMARY KEY AUTOINCREMENT, petId INTEGER,
      date INTEGER NOT NULL, category TEXT NOT NULL, amount INTEGER NOT NULL,
      memo TEXT DEFAULT '', createdAt INTEGER NOT NULL)''');
  }

  // ── Pet ──
  Future<List<Pet>> getAllPets() async =>
      (await (await db).query('pets', orderBy: 'createdAt ASC')).map(Pet.fromMap).toList();

  Future<Pet?> getPetById(int id) async {
    final rows = await (await db).query('pets', where: 'id = ?', whereArgs: [id]);
    return rows.isEmpty ? null : Pet.fromMap(rows.first);
  }

  Future<int> insertPet(Pet pet) async {
    final map = pet.toMap()..remove('id');
    return (await db).insert('pets', map);
  }

  Future<void> updatePet(Pet pet) async =>
      (await db).update('pets', pet.toMap(), where: 'id = ?', whereArgs: [pet.id]);

  Future<void> deletePet(int id) async =>
      (await db).delete('pets', where: 'id = ?', whereArgs: [id]);

  // ── Diary ──
  Future<List<DiaryEntry>> getEntriesByPet(int petId) async =>
      (await (await db).query('diary_entries', where: 'petId = ?', whereArgs: [petId], orderBy: 'date DESC'))
          .map(DiaryEntry.fromMap).toList();

  Future<DiaryEntry?> getRandomEntry(int petId) async {
    final rows = await (await db).query('diary_entries',
        where: 'petId = ?', whereArgs: [petId], orderBy: 'RANDOM()', limit: 1);
    return rows.isEmpty ? null : DiaryEntry.fromMap(rows.first);
  }

  Future<int> insertEntry(DiaryEntry entry) async {
    final map = entry.toMap()..remove('id');
    return (await db).insert('diary_entries', map);
  }

  Future<void> updateEntry(DiaryEntry entry) async =>
      (await db).update('diary_entries', entry.toMap(), where: 'id = ?', whereArgs: [entry.id]);

  Future<void> deleteEntry(int id) async =>
      (await db).delete('diary_entries', where: 'id = ?', whereArgs: [id]);

  // ── Expense ── petId=nullは共通費用
  Future<List<Expense>> getExpensesInMonth(List<int> petIds, int year, int month) async {
    final from = DateTime(year, month, 1).millisecondsSinceEpoch;
    final to = DateTime(year, month + 1, 1).millisecondsSinceEpoch - 1;
    if (petIds.isEmpty) {
      // 共通費用のみ
      final rows = await (await db).query('expenses',
          where: 'petId IS NULL AND date BETWEEN ? AND ?', whereArgs: [from, to], orderBy: 'date DESC');
      return rows.map(Expense.fromMap).toList();
    }
    final placeholders = petIds.map((_) => '?').join(',');
    final rows = await (await db).rawQuery(
      'SELECT * FROM expenses WHERE (petId IN ($placeholders) OR petId IS NULL) AND date BETWEEN ? AND ? ORDER BY date DESC',
      [...petIds, from, to]);
    return rows.map(Expense.fromMap).toList();
  }

  Future<int> insertExpense(Expense expense) async {
    final map = expense.toMap()..remove('id');
    return (await db).insert('expenses', map);
  }

  Future<void> updateExpense(Expense expense) async =>
      (await db).update('expenses', expense.toMap(), where: 'id = ?', whereArgs: [expense.id]);

  Future<void> deleteExpense(int id) async =>
      (await db).delete('expenses', where: 'id = ?', whereArgs: [id]);
}
