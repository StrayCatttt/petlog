import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../repositories/app_provider.dart';
import '../models/models.dart';
import '../theme/app_theme.dart';
import '../widgets/common_widgets.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});
  @override State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  // 設定画面用に選択中のペット（activePetとは別）
  int _settingsPetIndex = 0;

  @override Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    // Pro: 全ペット切り替え可。フリー: activePetのみ
    final editablePets = provider.isPro ? provider.activePets : (provider.activePet != null ? [provider.activePet!] : <Pet>[]);
    if (editablePets.isEmpty) return const Scaffold(body: Center(child: Text('ペットを追加してください')));
    final idx = _settingsPetIndex.clamp(0, editablePets.length - 1);
    final pet = editablePets[idx];

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(slivers: [
        const SliverAppBar(title: Text('⚙️ 設定', style: TextStyle(fontWeight: FontWeight.bold)), backgroundColor: Color(0xFFFBF0DE), floating: true),
        SliverToBoxAdapter(child: Padding(padding: const EdgeInsets.all(16), child: Column(children: [

          // Pro版: ペット切り替えタブ
          if (provider.isPro && editablePets.length > 1) ...[
            SingleChildScrollView(scrollDirection: Axis.horizontal, child: Row(children: List.generate(editablePets.length, (i) => GestureDetector(
              onTap: () => setState(() => _settingsPetIndex = i),
              child: Container(margin: const EdgeInsets.only(right: 8), padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(color: i == idx ? AppColors.caramel : AppColors.caramelPale, borderRadius: BorderRadius.circular(20)),
                child: Text('${editablePets[i].species.emoji} ${editablePets[i].name}', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: i == idx ? Colors.white : AppColors.textMid))),
            )))),
            const SizedBox(height: 14),
          ],

          // ペットプロフィールカード
          PetoCard(child: Row(children: [
            GestureDetector(
              onTap: () => _pickIcon(context, provider, pet),
              child: Stack(children: [
                Container(width: 64, height: 64, decoration: BoxDecoration(shape: BoxShape.circle, color: AppColors.caramelPale, border: Border.all(color: AppColors.goldRing, width: 3)),
                  child: ClipOval(child: pet.profilePhotoPath != null
                      ? Image.file(File(pet.profilePhotoPath!), fit: BoxFit.cover, errorBuilder: (_,__,___) => Center(child: Text(pet.species.emoji, style: const TextStyle(fontSize: 32))))
                      : Center(child: Text(pet.species.emoji, style: const TextStyle(fontSize: 32))))),
                Positioned(right: 0, bottom: 0, child: Container(width: 22, height: 22, decoration: BoxDecoration(color: AppColors.caramel, shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 2)), child: const Icon(Icons.camera_alt, color: Colors.white, size: 12))),
              ]),
            ),
            const SizedBox(width: 14),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(pet.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textDark)),
              Text('${pet.species.emoji} ${pet.species.label}・${pet.gender.label}', style: const TextStyle(fontSize: 12, color: AppColors.textLight)),
              if (pet.welcomeDate != null) ...[const SizedBox(height: 5),
                Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2), decoration: BoxDecoration(color: AppColors.caramelPale, borderRadius: BorderRadius.circular(10)),
                  child: Text('🎂 お迎えから${pet.daysFromWelcome}日目', style: const TextStyle(fontSize: 11, color: AppColors.caramel, fontWeight: FontWeight.w600)))],
            ])),
          ])),

          const SizedBox(height: 12),

          // Pro / フリーバナー
          if (!provider.isPro) ...[_ProBanner(onUpgrade: () => _showProDialog(context, provider)), const SizedBox(height: 16)]
          else ...[Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: AppColors.sagePale, borderRadius: BorderRadius.circular(16)), child: Row(children: [
            const Text('✨', style: TextStyle(fontSize: 24)), const SizedBox(width: 12),
            const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('ぺちろぐ PRO 有効中', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textDark)),
              Text('全機能をお楽しみください', style: TextStyle(fontSize: 12, color: AppColors.textMid)),
            ])),
            TextButton(onPressed: () => provider.setIsPro(false), child: const Text('解除', style: TextStyle(color: AppColors.textLight, fontSize: 12))),
          ])), const SizedBox(height: 16)],

          // ペット管理
          _SettingsGroup(title: 'ペット管理', children: [
            SettingsRow(icon: '🖼️', title: '${pet.name}のアイコンを変更', subtitle: 'ギャラリーから写真を選択', onTap: () => _pickIcon(context, provider, pet)),
            const Divider(height: 1, indent: 52),
            SettingsRow(icon: '✏️', title: '${pet.name}のプロフィール編集', onTap: () => _showEditProfile(context, provider, pet)),
            const Divider(height: 1, indent: 52),
            if (provider.isPro || provider.activePets.isEmpty)
              SettingsRow(icon: '🐾', title: 'ペットを追加', onTap: () => _showAddPet(context, provider))
            else
              const SettingsRow(icon: '🐾', title: 'ペットを追加（PRO機能）', subtitle: 'Proで複数匹対応', showProBadge: true, showArrow: false),
          ]),

          const SizedBox(height: 12),

          // ウィジェット（Pro）
          if (provider.isPro) ...[
            _SettingsGroup(title: 'ウィジェット（PRO）', children: [
              SettingsRow(icon: '🏠', title: '写真ウィジェット', subtitle: 'ホーム画面を長押し → ウィジェット → ぺちろぐ', onTap: () => _showWidgetHelp(context)),
              const Divider(height: 1, indent: 52),
              SettingsRow(icon: '📅', title: 'お迎え日カウントウィジェット', subtitle: 'ペットとの日数をホーム画面に表示', onTap: () => _showWidgetHelp(context)),
            ]),
            const SizedBox(height: 12),
          ],

          // 通知設定は削除（カレンダーのベルアイコンから設定）

          const SizedBox(height: 12),

          // データ管理（Pro: 引継ぎ）
          _SettingsGroup(title: 'データ管理', children: [
            if (provider.isPro) ...[
              SettingsRow(
                icon: '📤',
                title: 'このスマホからデータを書き出す',
                subtitle: '機種変更・バックアップ用\nファイルを保存・共有できます',
                onTap: () async {
                  await provider.exportData();
                }),
              const Divider(height: 1, indent: 52),
              SettingsRow(
                icon: '📥',
                title: '新しいスマホにデータを引き継ぐ',
                subtitle: '書き出したファイルを選んで復元',
                onTap: () => _showImportGuide(context, provider)),
              const Divider(height: 1, indent: 52),
            ],
            const SettingsRow(icon: '📋', title: 'アプリ情報', trailingText: 'v1.0.0'),
            const Divider(height: 1, indent: 52),
            const SettingsRow(icon: '✉️', title: 'お問い合わせ'),
          ]),

          const SizedBox(height: 24),
        ]))),
      ]),
    );
  }

  Future<void> _pickIcon(BuildContext context, AppProvider provider, Pet pet) async {
    final source = await showModalBottomSheet<ImageSource>(context: context, builder: (ctx) => SafeArea(child: Column(mainAxisSize: MainAxisSize.min, children: [
      ListTile(leading: const Icon(Icons.photo_library, color: AppColors.caramel), title: const Text('ギャラリーから選ぶ'), onTap: () => Navigator.pop(ctx, ImageSource.gallery)),
      ListTile(leading: const Icon(Icons.camera_alt, color: AppColors.caramel), title: const Text('カメラで撮影'), onTap: () => Navigator.pop(ctx, ImageSource.camera)),
    ])));
    if (source == null || !mounted) return;
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(source: source, imageQuality: 85);
      if (picked == null) return;
      await provider.updatePet(pet.copyWith(profilePhotoPath: picked.path));
    } catch (e) { debugPrint('icon error: $e'); }
  }

  void _showEditProfile(BuildContext context, AppProvider provider, Pet pet) =>
    showModalBottomSheet(context: context, isScrollControlled: true, backgroundColor: Colors.transparent, builder: (_) => _EditPetSheet(pet: pet));
  void _showAddPet(BuildContext context, AppProvider provider) =>
    showModalBottomSheet(context: context, isScrollControlled: true, backgroundColor: Colors.transparent, builder: (_) => const _AddPetSheet());
  void _showWidgetHelp(BuildContext context) => showDialog(context: context, builder: (ctx) => AlertDialog(
    title: const Text('🏠 ウィジェットの追加方法'),
    content: const Text('1. ホーム画面を長押し\n2.「ウィジェット」をタップ\n3. アプリ一覧から「ぺちろぐ」を選択\n4. ウィジェットを長押しして配置\n\n※ Android 12以降対応', style: TextStyle(height: 1.8)),
    actions: [ElevatedButton(onPressed: () => Navigator.pop(ctx), child: const Text('OK'))],
  ));
  void _showProDialog(BuildContext context, AppProvider provider) => showDialog(context: context, builder: (ctx) => AlertDialog(
    backgroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    title: const Column(children: [Text('✨', style: TextStyle(fontSize: 48)), SizedBox(height: 8), Text('ぺとろぐ PRO', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textDark))]),
    content: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('PRO機能：', style: TextStyle(fontWeight: FontWeight.bold)), const SizedBox(height: 8),
      const Text('✓ 広告なし\n✓ 写真1日30枚\n✓ ペット無制限\n✓ ホーム画面ウィジェット\n✓ データ引継ぎ（機種変更対応）', style: TextStyle(color: AppColors.textMid, height: 1.8)),
      const SizedBox(height: 16),
      const Text('プランを選んでください：', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
      const SizedBox(height: 8),
      // 月額プラン
      OutlinedButton(
        onPressed: () { Navigator.pop(ctx); provider.setIsPro(true); ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('✨ PRO（月額）が有効になりました！'), backgroundColor: AppColors.caramel)); },
        style: OutlinedButton.styleFrom(minimumSize: const Size(double.infinity, 48), side: const BorderSide(color: AppColors.caramel), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
        child: const Column(children: [
          Text('月額プラン', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textDark)),
          Text('¥380 / 月（初月無料）', style: TextStyle(color: AppColors.caramel, fontWeight: FontWeight.bold)),
        ]),
      ),
      const SizedBox(height: 8),
      // 年額プラン
      ElevatedButton(
        onPressed: () { Navigator.pop(ctx); provider.setIsPro(true); ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('✨ PRO（年額）が有効になりました！'), backgroundColor: AppColors.caramel)); },
        style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 48), backgroundColor: AppColors.gold, foregroundColor: AppColors.textDark, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
        child: const Column(children: [
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Text('年額プラン', style: TextStyle(fontWeight: FontWeight.bold)),
            SizedBox(width: 8),
            Text('お得！', style: TextStyle(fontSize: 11, color: Colors.red, fontWeight: FontWeight.bold)),
          ]),
          Text('¥3,800 / 年（月あたり¥316）', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
        ]),
      ),
      const SizedBox(height: 8),
      const Text('※これは試用版です。実際の課金は発生しません。', style: TextStyle(fontSize: 10, color: AppColors.textLight)),
    ]),
    actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('キャンセル', style: TextStyle(color: AppColors.textMid)))],
  ));

  void _showImportGuide(BuildContext context, AppProvider provider) => showDialog(context: context, builder: (ctx) => AlertDialog(
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    title: const Text('📥 データを引き継ぐ', style: TextStyle(fontWeight: FontWeight.bold)),
    content: const SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('【手順】', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textDark)),
      SizedBox(height: 8),
      Text('① 古いスマホで\n「このスマホからデータを書き出す」をタップ', style: TextStyle(fontSize: 13, color: AppColors.textMid, height: 1.6)),
      SizedBox(height: 6),
      Text('② 表示されたファイルを\nGoogleドライブ・LINEなどで新しいスマホに送る', style: TextStyle(fontSize: 13, color: AppColors.textMid, height: 1.6)),
      SizedBox(height: 6),
      Text('③ 新しいスマホでぺとろぐを開き\nこの画面から「ファイルを選んで復元」をタップ', style: TextStyle(fontSize: 13, color: AppColors.textMid, height: 1.6)),
      SizedBox(height: 12),
      Text('⚠️ 復元すると現在のデータは上書きされます', style: TextStyle(fontSize: 11, color: Colors.orange)),
    ])),
    actions: [
      TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('閉じる', style: TextStyle(color: AppColors.textMid))),
      ElevatedButton(onPressed: () async {
        Navigator.pop(ctx);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('ファイル選択機能は次のバージョンで対応予定です')));
      }, child: const Text('ファイルを選んで復元')),
    ],
  ));
}

// ─── ペット追加シート ──────────────────────────────────

class _AddPetSheet extends StatefulWidget {
  const _AddPetSheet();
  @override State<_AddPetSheet> createState() => _AddPetSheetState();
}
class _AddPetSheetState extends State<_AddPetSheet> {
  final _nameCtrl = TextEditingController();
  PetSpecies _species = PetSpecies.dog; PetGender _gender = PetGender.unknown;
  DateTime? _birthDate, _welcomeDate;
  @override Widget build(BuildContext context) => Container(
    decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
    padding: EdgeInsets.only(left: 20, right: 20, top: 20, bottom: MediaQuery.of(context).viewInsets.bottom + 40),
    child: SingleChildScrollView(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('🐾 ペットを追加', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textDark)),
      const SizedBox(height: 16),
      TextField(controller: _nameCtrl, decoration: const InputDecoration(labelText: '名前', hintText: '例：むぎ', hintStyle: TextStyle(color: AppColors.textLight)), onChanged: (_) => setState(() {})),
      const SizedBox(height: 14),
      Wrap(spacing: 8, children: PetSpecies.values.map((s) => ChoiceChip(label: Text('${s.emoji} ${s.label}'), selected: _species == s, onSelected: (_) => setState(() => _species = s), selectedColor: AppColors.caramel, labelStyle: TextStyle(color: _species == s ? Colors.white : AppColors.textMid, fontSize: 12))).toList()),
      const SizedBox(height: 14),
      Wrap(spacing: 8, children: PetGender.values.map((g) => ChoiceChip(label: Text(g.label), selected: _gender == g, onSelected: (_) => setState(() => _gender = g), selectedColor: AppColors.caramel, labelStyle: TextStyle(color: _gender == g ? Colors.white : AppColors.textMid, fontSize: 12))).toList()),
      const SizedBox(height: 14),
      _DateRow(label: '誕生日', date: _birthDate, onPicked: (d) => setState(() => _birthDate = d)),
      _DateRow(label: 'お迎えした日', date: _welcomeDate, onPicked: (d) => setState(() => _welcomeDate = d)),
      const SizedBox(height: 20),
      PetoButton(label: '✓ 追加する', onPressed: _nameCtrl.text.trim().isEmpty ? null : () async {
        await context.read<AppProvider>().addPet(Pet(name: _nameCtrl.text.trim(), species: _species, gender: _gender, birthDate: _birthDate, welcomeDate: _welcomeDate, createdAt: DateTime.now()));
        if (mounted) Navigator.pop(context);
      }),
    ])),
  );
}

// ─── ペット編集シート ──────────────────────────────────

class _EditPetSheet extends StatefulWidget {
  final Pet pet;
  const _EditPetSheet({required this.pet});
  @override State<_EditPetSheet> createState() => _EditPetSheetState();
}
class _EditPetSheetState extends State<_EditPetSheet> {
  late TextEditingController _nameCtrl, _memoCtrl;
  late PetSpecies _species; late PetGender _gender;
  DateTime? _birthDate, _welcomeDate, _passedDate;
  bool _showPassed = false;
  @override void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.pet.name);
    _memoCtrl = TextEditingController(text: widget.pet.memo);
    _species = widget.pet.species; _gender = widget.pet.gender;
    _birthDate = widget.pet.birthDate; _welcomeDate = widget.pet.welcomeDate;
    _passedDate = widget.pet.passedDate; _showPassed = widget.pet.hasPassed;
  }
  @override Widget build(BuildContext context) => Container(
    decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
    padding: EdgeInsets.only(left: 20, right: 20, top: 20, bottom: MediaQuery.of(context).viewInsets.bottom + 40),
    child: SingleChildScrollView(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('✏️ プロフィール編集', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textDark)),
      const SizedBox(height: 16),
      TextField(controller: _nameCtrl, decoration: const InputDecoration(labelText: '名前', hintStyle: TextStyle(color: AppColors.textLight))),
      const SizedBox(height: 14),
      Wrap(spacing: 8, children: PetSpecies.values.map((s) => ChoiceChip(label: Text('${s.emoji} ${s.label}'), selected: _species == s, onSelected: (_) => setState(() => _species = s), selectedColor: AppColors.caramel, labelStyle: TextStyle(color: _species == s ? Colors.white : AppColors.textMid, fontSize: 12))).toList()),
      const SizedBox(height: 14),
      Wrap(spacing: 8, children: PetGender.values.map((g) => ChoiceChip(label: Text(g.label), selected: _gender == g, onSelected: (_) => setState(() => _gender = g), selectedColor: AppColors.caramel, labelStyle: TextStyle(color: _gender == g ? Colors.white : AppColors.textMid, fontSize: 12))).toList()),
      const SizedBox(height: 14),
      _DateRow(label: '誕生日', date: _birthDate, onPicked: (d) => setState(() => _birthDate = d), clearable: true, onCleared: () => setState(() => _birthDate = null)),
      _DateRow(label: 'お迎えした日', date: _welcomeDate, onPicked: (d) => setState(() => _welcomeDate = d), clearable: true, onCleared: () => setState(() => _welcomeDate = null)),
      const SizedBox(height: 14),
      TextField(controller: _memoCtrl, maxLines: 2, decoration: const InputDecoration(labelText: 'メモ', hintText: '好きなおやつ、かかりつけ医など', hintStyle: TextStyle(color: AppColors.textLight))),
      const SizedBox(height: 16),
      // 虹の橋（折りたたみ）
      InkWell(onTap: () => setState(() => _showPassed = !_showPassed),
        child: Row(children: [
          Icon(_showPassed ? Icons.expand_less : Icons.expand_more, color: AppColors.textLight, size: 20), const SizedBox(width: 4),
          Text('🌈 虹の橋（亡くなった場合）', style: TextStyle(fontSize: 12, color: _showPassed ? AppColors.textMid : AppColors.textLight)),
        ])),
      if (_showPassed) ...[
        const SizedBox(height: 8),
        _DateRow(label: '虹の橋を渡った日', date: _passedDate, onPicked: (d) => setState(() => _passedDate = d), clearable: true, onCleared: () => setState(() => _passedDate = null)),
        if (_passedDate != null) Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: const Color(0xFFF0F0F0), borderRadius: BorderRadius.circular(12)),
          child: const Text('亡くなった日を設定すると、このペットは「虹の橋」カテゴリーに移動します。', style: TextStyle(fontSize: 12, color: AppColors.textMid))),
      ],
      const SizedBox(height: 20),
      PetoButton(label: '✓ 保存する', onPressed: () async {
        await context.read<AppProvider>().updatePet(widget.pet.copyWith(
          name: _nameCtrl.text.trim(), species: _species, gender: _gender,
          birthDate: _birthDate, clearBirth: _birthDate == null,
          welcomeDate: _welcomeDate, clearWelcome: _welcomeDate == null,
          passedDate: _passedDate, clearPassed: _passedDate == null,
          memo: _memoCtrl.text));
        if (mounted) Navigator.pop(context);
      }),
    ])),
  );
}

// ─── 日付選択行 ───────────────────────────────────────

class _DateRow extends StatelessWidget {
  final String label; final DateTime? date; final ValueChanged<DateTime> onPicked; final bool clearable; final VoidCallback? onCleared;
  const _DateRow({required this.label, required this.date, required this.onPicked, this.clearable = false, this.onCleared});
  @override Widget build(BuildContext context) => Padding(padding: const EdgeInsets.only(bottom: 8), child: Row(children: [
    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textLight)), const SizedBox(height: 2),
      Text(date != null ? '${date!.year}年${date!.month}月${date!.day}日' : '未設定',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: date != null ? AppColors.textDark : AppColors.textLight)),
    ])),
    if (clearable && date != null) IconButton(icon: const Icon(Icons.clear, size: 18, color: AppColors.textLight), onPressed: onCleared),
    TextButton(onPressed: () async { final p = await showDatePicker(context: context, initialDate: date ?? DateTime.now(), firstDate: DateTime(2000), lastDate: DateTime(2100)); if (p != null) onPicked(p); },
      child: Text(date != null ? '変更' : '設定', style: const TextStyle(color: AppColors.caramel))),
  ]));
}

// ─── 設定グループ ─────────────────────────────────────

class _SettingsGroup extends StatelessWidget {
  final String title; final List<Widget> children;
  const _SettingsGroup({required this.title, required this.children});
  @override Widget build(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Padding(padding: const EdgeInsets.only(left: 4, bottom: 8), child: Text(title.toUpperCase(), style: const TextStyle(fontSize: 10, color: AppColors.textLight, letterSpacing: 1))),
    Material(color: Colors.white, borderRadius: BorderRadius.circular(14), child: Column(children: children)),
  ]);
}

class _ProBanner extends StatelessWidget {
  final VoidCallback onUpgrade;
  const _ProBanner({required this.onUpgrade});
  @override Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(color: const Color(0xFF3D2E1E), borderRadius: BorderRadius.circular(20)),
    padding: const EdgeInsets.all(20),
    child: Row(children: [
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('ぺちろぐ PRO', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.goldRing, letterSpacing: 2)), const SizedBox(height: 5),
        const Text('広告なし・ウィジェット\n写真1日30枚・データ引継ぎ', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)), const SizedBox(height: 4),
        const Text('¥380/月（初月無料）', style: TextStyle(fontSize: 12, color: Colors.white70)), const SizedBox(height: 14),
        ElevatedButton(onPressed: onUpgrade, style: ElevatedButton.styleFrom(backgroundColor: AppColors.gold, foregroundColor: const Color(0xFF3D2E1E), padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8)),
          child: const Text('✨ 試してみる', style: TextStyle(fontWeight: FontWeight.bold))),
      ])),
      const Text('🐾', style: TextStyle(fontSize: 60, color: Colors.white12)),
    ]),
  );
}
