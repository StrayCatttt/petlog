enum PetSpecies {
  dog('犬','🐶'), cat('猫','🐱'), rabbit('うさぎ','🐰'),
  bird('鳥','🐦'), reptile('爬虫類','🦎'), fish('魚','🐟'), other('その他','🐾');
  const PetSpecies(this.label,this.emoji); final String label,emoji;
}
enum PetGender { male('オス'), female('メス'), unknown('不明'); const PetGender(this.label); final String label; }

class Pet {
  final int? id; final String name; final PetSpecies species; final PetGender gender;
  final DateTime? birthDate, welcomeDate, passedDate;
  final String? profilePhotoPath; final String memo; final DateTime createdAt;
  const Pet({this.id,required this.name,this.species=PetSpecies.dog,this.gender=PetGender.unknown,
    this.birthDate,this.welcomeDate,this.passedDate,this.profilePhotoPath,this.memo='',required this.createdAt});
  bool get hasPassed => passedDate!=null;
  int get daysFromWelcome { if(welcomeDate==null) return 0; final e=passedDate??DateTime.now(); return e.difference(welcomeDate!).inDays; }
  String get ageString { if(birthDate==null) return ''; final e=passedDate??DateTime.now(); final d=e.difference(birthDate!); final y=(d.inDays/365).floor(); final m=((d.inDays%365)/30).floor(); return y>0?'$y歳$mヶ月':'$mヶ月'; }
  Pet copyWith({int? id,String? name,PetSpecies? species,PetGender? gender,DateTime? birthDate,bool clearBirth=false,DateTime? welcomeDate,bool clearWelcome=false,DateTime? passedDate,bool clearPassed=false,String? profilePhotoPath,bool clearPhoto=false,String? memo}) =>
    Pet(id:id??this.id,name:name??this.name,species:species??this.species,gender:gender??this.gender,
      birthDate:clearBirth?null:(birthDate??this.birthDate),welcomeDate:clearWelcome?null:(welcomeDate??this.welcomeDate),
      passedDate:clearPassed?null:(passedDate??this.passedDate),
      profilePhotoPath:clearPhoto?null:(profilePhotoPath??this.profilePhotoPath),memo:memo??this.memo,createdAt:createdAt);
  Map<String,dynamic> toMap() => {'id':id,'name':name,'species':species.name,'gender':gender.name,
    'birthDate':birthDate?.millisecondsSinceEpoch,'welcomeDate':welcomeDate?.millisecondsSinceEpoch,
    'passedDate':passedDate?.millisecondsSinceEpoch,'profilePhotoPath':profilePhotoPath,'memo':memo,'createdAt':createdAt.millisecondsSinceEpoch};
  factory Pet.fromMap(Map<String,dynamic> m) => Pet(id:m['id'],name:m['name'],
    species:PetSpecies.values.firstWhere((e)=>e.name==m['species'],orElse:()=>PetSpecies.dog),
    gender:PetGender.values.firstWhere((e)=>e.name==m['gender'],orElse:()=>PetGender.unknown),
    birthDate:m['birthDate']!=null?DateTime.fromMillisecondsSinceEpoch(m['birthDate']):null,
    welcomeDate:m['welcomeDate']!=null?DateTime.fromMillisecondsSinceEpoch(m['welcomeDate']):null,
    passedDate:m['passedDate']!=null?DateTime.fromMillisecondsSinceEpoch(m['passedDate']):null,
    profilePhotoPath:m['profilePhotoPath'],memo:m['memo']??'',createdAt:DateTime.fromMillisecondsSinceEpoch(m['createdAt']));
}

enum DiaryMood {
  happy('😸','うれしい'),smile('😊','ふつう'),sad('😔','かなしい'),sleepy('😴','ねむい'),
  scared('😨','こわかった'),excited('🎉','たのしい'),sick('🤒','ぐったり'),
  playful('😜','やんちゃ'),calm('😌','おだやか'),angry('😠','きげんわるい');
  const DiaryMood(this.emoji,this.label); final String emoji,label;
}

enum DiarySort { dateDesc, dateAsc, petName }

class DiaryEntry {
  final int? id;
  final int petId; // -1 = 共通（全ペット）
  final DateTime date; final DiaryMood mood;
  final String body; final List<String> photoUris;
  final DateTime createdAt,updatedAt;
  const DiaryEntry({this.id,required this.petId,required this.date,this.mood=DiaryMood.happy,
    this.body='',this.photoUris=const[],required this.createdAt,required this.updatedAt});
  bool get isShared => petId==-1;
  DiaryEntry copyWith({int? petId,DiaryMood? mood,String? body,List<String>? photoUris}) =>
    DiaryEntry(id:id,petId:petId??this.petId,date:date,mood:mood??this.mood,body:body??this.body,
      photoUris:photoUris??this.photoUris,createdAt:createdAt,updatedAt:DateTime.now());
  Map<String,dynamic> toMap() => {'id':id,'petId':petId,'date':date.millisecondsSinceEpoch,
    'mood':mood.name,'body':body,'photoUris':photoUris.join(','),'createdAt':createdAt.millisecondsSinceEpoch,'updatedAt':updatedAt.millisecondsSinceEpoch};
  factory DiaryEntry.fromMap(Map<String,dynamic> m) => DiaryEntry(id:m['id'],petId:m['petId']??-1,
    date:DateTime.fromMillisecondsSinceEpoch(m['date']),
    mood:DiaryMood.values.firstWhere((e)=>e.name==m['mood'],orElse:()=>DiaryMood.happy),
    body:m['body']??'',photoUris:(m['photoUris']??'').split(',').where((s)=>s.isNotEmpty).toList(),
    createdAt:DateTime.fromMillisecondsSinceEpoch(m['createdAt']),updatedAt:DateTime.fromMillisecondsSinceEpoch(m['updatedAt']));
}

// 予定（時間必須）
class PetSchedule {
  final int? id; final int? petId;
  final DateTime dateTime; // 日付＋時間（必須）
  final String title; final String? note;
  final bool notifyEnabled;
  final int notifyMinutesBefore; // 通知は何分前か（0=当日,10,30,60,360,720）
  final DateTime createdAt;
  const PetSchedule({this.id,this.petId,required this.dateTime,required this.title,this.note,
    this.notifyEnabled=true,this.notifyMinutesBefore=30,required this.createdAt});
  PetSchedule copyWith({String? title,String? note,bool? notifyEnabled,int? notifyMinutesBefore}) =>
    PetSchedule(id:id,petId:petId,dateTime:dateTime,title:title??this.title,note:note??this.note,
      notifyEnabled:notifyEnabled??this.notifyEnabled,notifyMinutesBefore:notifyMinutesBefore??this.notifyMinutesBefore,createdAt:createdAt);
  Map<String,dynamic> toMap() => {'id':id,'petId':petId,'date':dateTime.millisecondsSinceEpoch,'title':title,'note':note,'notifyEnabled':notifyEnabled?1:0,'notifyMinutesBefore':notifyMinutesBefore,'createdAt':createdAt.millisecondsSinceEpoch};
  factory PetSchedule.fromMap(Map<String,dynamic> m) => PetSchedule(id:m['id'],petId:m['petId'],
    dateTime:DateTime.fromMillisecondsSinceEpoch(m['date']),title:m['title'],note:m['note'],
    notifyEnabled:(m['notifyEnabled']??1)==1,notifyMinutesBefore:m['notifyMinutesBefore']??30,
    createdAt:DateTime.fromMillisecondsSinceEpoch(m['createdAt']));
  String get notifyLabel { if(!notifyEnabled) return '通知なし'; switch(notifyMinutesBefore) { case 0: return '当日'; case 10: return '10分前'; case 30: return '30分前'; case 60: return '1時間前'; case 360: return '6時間前'; case 720: return '12時間前'; default: return '${notifyMinutesBefore}分前'; } }
}

enum ExpenseCategory {
  food('フード','🍖',0xFFF59E0B),medical('医療','💉',0xFF10B981),
  goods('グッズ','🎾',0xFF3B82F6),beauty('美容','✂️',0xFFEC4899),other('その他','📦',0xFF8B5CF6);
  const ExpenseCategory(this.label,this.emoji,this.colorValue); final String label,emoji; final int colorValue;
}

class Expense {
  final int? id; final int? petId; final DateTime date;
  final ExpenseCategory category; final int amount; final String memo; final DateTime createdAt;
  const Expense({this.id,this.petId,required this.date,this.category=ExpenseCategory.food,required this.amount,this.memo='',required this.createdAt});
  bool get isShared => petId==null;
  Expense copyWith({int? petId,bool sharedExpense=false,ExpenseCategory? category,int? amount,String? memo}) =>
    Expense(id:id,petId:sharedExpense?null:(petId??this.petId),date:date,category:category??this.category,amount:amount??this.amount,memo:memo??this.memo,createdAt:createdAt);
  Map<String,dynamic> toMap() => {'id':id,'petId':petId,'date':date.millisecondsSinceEpoch,'category':category.name,'amount':amount,'memo':memo,'createdAt':createdAt.millisecondsSinceEpoch};
  factory Expense.fromMap(Map<String,dynamic> m) => Expense(id:m['id'],petId:m['petId'],
    date:DateTime.fromMillisecondsSinceEpoch(m['date']),
    category:ExpenseCategory.values.firstWhere((e)=>e.name==m['category'],orElse:()=>ExpenseCategory.other),
    amount:m['amount'],memo:m['memo']??'',createdAt:DateTime.fromMillisecondsSinceEpoch(m['createdAt']));
}

class NotificationSettings {
  final bool vaccineReminder;
  final int vaccineDaysBefore;
  final bool anniversaryNotify;
  final String notifySound; // 'default','vibrate','silent'
  final int defaultNotifyMinutesBefore; // 全般のデフォルト通知タイミング
  const NotificationSettings({
    this.vaccineReminder=true,this.vaccineDaysBefore=7,
    this.anniversaryNotify=true,this.notifySound='default',
    this.defaultNotifyMinutesBefore=30});
}
