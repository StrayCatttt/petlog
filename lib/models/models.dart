// ─── Pet ──────────────────────────────────────────────

enum PetSpecies {
  dog('犬', '🐶'),
  cat('猫', '🐱'),
  rabbit('うさぎ', '🐰'),
  bird('鳥', '🐦'),
  reptile('爬虫類', '🦎'),
  fish('魚', '🐟'),
  other('その他', '🐾');

  const PetSpecies(this.label, this.emoji);
  final String label;
  final String emoji;
}

enum PetGender {
  male('オス'),
  female('メス'),
  unknown('不明');

  const PetGender(this.label);
  final String label;
}

class Pet {
  final int? id;
  final String name;
  final PetSpecies species;
  final PetGender gender;
  final DateTime? birthDate;
  final DateTime? welcomeDate;
  final String? profilePhotoPath;
  final String memo;
  final DateTime createdAt;

  const Pet({
    this.id,
    required this.name,
    this.species = PetSpecies.dog,
    this.gender = PetGender.unknown,
    this.birthDate,
    this.welcomeDate,
    this.profilePhotoPath,
    this.memo = '',
    required this.createdAt,
  });

  Pet copyWith({
    int? id,
    String? name,
    PetSpecies? species,
    PetGender? gender,
    DateTime? birthDate,
    DateTime? welcomeDate,
    String? profilePhotoPath,
    bool clearPhoto = false,
    String? memo,
  }) => Pet(
    id: id ?? this.id,
    name: name ?? this.name,
    species: species ?? this.species,
    gender: gender ?? this.gender,
    birthDate: birthDate ?? this.birthDate,
    welcomeDate: welcomeDate ?? this.welcomeDate,
    profilePhotoPath: clearPhoto ? null : (profilePhotoPath ?? this.profilePhotoPath),
    memo: memo ?? this.memo,
    createdAt: createdAt,
  );

  int get daysFromWelcome {
    if (welcomeDate == null) return 0;
    return DateTime.now().difference(welcomeDate!).inDays;
  }

  String get ageString {
    if (birthDate == null) return '';
    final diff = DateTime.now().difference(birthDate!);
    final years = (diff.inDays / 365).floor();
    final months = ((diff.inDays % 365) / 30).floor();
    if (years > 0) return '$years歳$months ヶ月';
    return '$monthsヶ月';
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'species': species.name,
    'gender': gender.name,
    'birthDate': birthDate?.millisecondsSinceEpoch,
    'welcomeDate': welcomeDate?.millisecondsSinceEpoch,
    'profilePhotoPath': profilePhotoPath,
    'memo': memo,
    'createdAt': createdAt.millisecondsSinceEpoch,
  };

  factory Pet.fromMap(Map<String, dynamic> m) => Pet(
    id: m['id'] as int?,
    name: m['name'] as String,
    species: PetSpecies.values.firstWhere((e) => e.name == m['species'], orElse: () => PetSpecies.dog),
    gender: PetGender.values.firstWhere((e) => e.name == m['gender'], orElse: () => PetGender.unknown),
    birthDate: m['birthDate'] != null ? DateTime.fromMillisecondsSinceEpoch(m['birthDate'] as int) : null,
    welcomeDate: m['welcomeDate'] != null ? DateTime.fromMillisecondsSinceEpoch(m['welcomeDate'] as int) : null,
    profilePhotoPath: m['profilePhotoPath'] as String?,
    memo: m['memo'] as String? ?? '',
    createdAt: DateTime.fromMillisecondsSinceEpoch(m['createdAt'] as int),
  );
}

// ─── DiaryEntry ───────────────────────────────────────

enum DiaryMood {
  happy('😸', 'うれしい'),
  smile('😊', 'ふつう'),
  sad('😔', 'かなしい'),
  sleepy('😴', 'ねむい'),
  scared('😨', 'こわかった'),
  excited('🎉', 'たのしい'),
  sick('🤒', 'ぐったり'),
  playful('😜', 'やんちゃ'),
  calm('😌', 'おだやか'),
  angry('😠', 'きげんわるい');

  const DiaryMood(this.emoji, this.label);
  final String emoji;
  final String label;
}

class DiaryEntry {
  final int? id;
  final int petId;
  final DateTime date;
  final DiaryMood mood;
  final String body;
  final List<String> photoUris;
  final DateTime createdAt;
  final DateTime updatedAt;

  const DiaryEntry({
    this.id,
    required this.petId,
    required this.date,
    this.mood = DiaryMood.happy,
    this.body = '',
    this.photoUris = const [],
    required this.createdAt,
    required this.updatedAt,
  });

  DiaryEntry copyWith({DiaryMood? mood, String? body, List<String>? photoUris}) => DiaryEntry(
    id: id, petId: petId, date: date,
    mood: mood ?? this.mood,
    body: body ?? this.body,
    photoUris: photoUris ?? this.photoUris,
    createdAt: createdAt,
    updatedAt: DateTime.now(),
  );

  Map<String, dynamic> toMap() => {
    'id': id,
    'petId': petId,
    'date': date.millisecondsSinceEpoch,
    'mood': mood.name,
    'body': body,
    'photoUris': photoUris.join(','),
    'createdAt': createdAt.millisecondsSinceEpoch,
    'updatedAt': updatedAt.millisecondsSinceEpoch,
  };

  factory DiaryEntry.fromMap(Map<String, dynamic> m) => DiaryEntry(
    id: m['id'] as int?,
    petId: m['petId'] as int,
    date: DateTime.fromMillisecondsSinceEpoch(m['date'] as int),
    mood: DiaryMood.values.firstWhere((e) => e.name == m['mood'], orElse: () => DiaryMood.happy),
    body: m['body'] as String? ?? '',
    photoUris: (m['photoUris'] as String? ?? '').split(',').where((s) => s.isNotEmpty).toList(),
    createdAt: DateTime.fromMillisecondsSinceEpoch(m['createdAt'] as int),
    updatedAt: DateTime.fromMillisecondsSinceEpoch(m['updatedAt'] as int),
  );
}

// ─── Expense ──────────────────────────────────────────

enum ExpenseCategory {
  food('フード', '🍖', 0xFFF59E0B),
  medical('医療', '💉', 0xFF10B981),
  goods('グッズ', '🎾', 0xFF3B82F6),
  beauty('美容', '✂️', 0xFFEC4899),
  other('その他', '📦', 0xFF8B5CF6);

  const ExpenseCategory(this.label, this.emoji, this.colorValue);
  final String label;
  final String emoji;
  final int colorValue;
}

class Expense {
  final int? id;
  final int petId;
  final DateTime date;
  final ExpenseCategory category;
  final int amount;
  final String memo;
  final DateTime createdAt;

  const Expense({
    this.id,
    required this.petId,
    required this.date,
    this.category = ExpenseCategory.food,
    required this.amount,
    this.memo = '',
    required this.createdAt,
  });

  Expense copyWith({ExpenseCategory? category, int? amount, String? memo}) => Expense(
    id: id, petId: petId, date: date,
    category: category ?? this.category,
    amount: amount ?? this.amount,
    memo: memo ?? this.memo,
    createdAt: createdAt,
  );

  Map<String, dynamic> toMap() => {
    'id': id,
    'petId': petId,
    'date': date.millisecondsSinceEpoch,
    'category': category.name,
    'amount': amount,
    'memo': memo,
    'createdAt': createdAt.millisecondsSinceEpoch,
  };

  factory Expense.fromMap(Map<String, dynamic> m) => Expense(
    id: m['id'] as int?,
    petId: m['petId'] as int,
    date: DateTime.fromMillisecondsSinceEpoch(m['date'] as int),
    category: ExpenseCategory.values.firstWhere((e) => e.name == m['category'], orElse: () => ExpenseCategory.other),
    amount: m['amount'] as int,
    memo: m['memo'] as String? ?? '',
    createdAt: DateTime.fromMillisecondsSinceEpoch(m['createdAt'] as int),
  );
}
