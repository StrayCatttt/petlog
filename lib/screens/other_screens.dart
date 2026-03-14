import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../repositories/app_provider.dart';
import '../models/models.dart';
import '../theme/app_theme.dart';
import '../widgets/common_widgets.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final pet = provider.activePet;
    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(slivers: [
        const SliverAppBar(title: Text('⚙️ 設定', style: TextStyle(fontWeight: FontWeight.bold)), backgroundColor: Color(0xFFFBF0DE), floating: true),
        SliverToBoxAdapter(child: Padding(padding: const EdgeInsets.all(16), child: Column(children: [

          // ペットプロフィールカード
          if (pet != null) PetoCard(child: Row(children: [
            GestureDetector(
              onTap: () => _pickIcon(context, provider, pet),
              child: Stack(children: [
                Container(width: 64, height: 64,
                  decoration: BoxDecoration(shape: BoxShape.circle, color: AppColors.caramelPale, border: Border.all(color: AppColors.goldRing, width: 3)),
                  child: ClipOval(child: pet.profilePhotoPath != null
                      ? Image.file(File(pet.profilePhotoPath!), fit: BoxFit.cover, errorBuilder: (_, __, ___) => Center(child: Text(pet.species.emoji, style: const TextStyle(fontSize: 32))))
                      : Center(child: Text(pet.species.emoji, style: const TextStyle(fontSize: 32))))),
                Positioned(right: 0, bottom: 0, child: Container(width: 22, height: 22,
                  decoration: BoxDecoration(color: AppColors.caramel, shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 2)),
                  child: const Icon(Icons.camera_alt, color: Colors.white, size: 12))),
              ]),
            ),
            const SizedBox(width: 14),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(pet.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textDark)),
              Text('${pet.species.emoji} ${pet.species.label}・${pet.gender.label}', style: const TextStyle(fontSize: 12, color: AppColors.textLight)),
              const SizedBox(height: 5),
              if (pet.welcomeDate != null) Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                decoration: BoxDecoration(color: AppColors.caramelPale, borderRadius: BorderRadius.circular(10)),
                child: Text('🎂 お迎えから${pet.daysFromWelcome}日目', style: const TextStyle(fontSize: 11, color: AppColors.caramel, fontWeight: FontWeight.w600))),
            ])),
          ])),

          const SizedBox(height: 12),

          // Proバナー or Proステータス
          if (!provider.isPro) ...[
            _ProBanner(onUpgrade: () => _showProDialog(context, provider)),
            const SizedBox(height: 16),
          ] else ...[
            Container(padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: AppColors.sagePale, borderRadius: BorderRadius.circular(16)),
              child: Row(children: [
                const Text('✨', style: TextStyle(fontSize: 24)),
                const SizedBox(width: 12),
                const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('ぺとろぐ PRO 有効中', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textDark)),
                  Text('全機能をお楽しみください', style: TextStyle(fontSize: 12, color: AppColors.textMid)),
                ])),
                TextButton(onPressed: () => provider.setIsPro(false), child: const Text('解除', style: TextStyle(color: AppColors.textLight, fontSize: 12))),
              ])),
            const SizedBox(height: 16),
          ],

          // ペット管理
          _SettingsGroup(title: 'ペット管理', children: [
            SettingsRow(icon: '🖼️', title: '${pet?.name ?? 'ペット'}のアイコンを変更', subtitle: 'ギャラリーから写真を選択', onTap: pet != null ? () => _pickIcon(context, provider, pet) : null),
            const Divider(height: 1, indent: 52),
            SettingsRow(icon: '✏️', title: '${pet?.name ?? 'ペット'}のプロフィール編集', onTap: pet != null ? () => _showEditProfile(context, provider, pet) : null),
            const Divider(height: 1, indent: 52),
            // 無料版は1匹のみ
            if (provider.isPro || provider.activePets.length < 1)
              SettingsRow(icon: '🐾', title: 'ペットを追加', subtitle: '現在${provider.activePets.length}匹', onTap: () => _showAddPet(context, provider))
            else if (!provider.isPro)
              SettingsRow(icon: '🐾', title: 'ペットを追加（PRO機能）', subtitle: 'Proにアップグレードで複数匹対応', showProBadge: true, showArrow: false),
          ]),

          const SizedBox(height: 12),

          // 虹の橋（亡くなったペット）- 折りたたみ
          if (provider.passedPets.isNotEmpty || true)
            _RainbowBridgeSection(provider: provider),

          const SizedBox(height: 12),

          // Proウィジェット
          if (provider.isPro) ...[
            _SettingsGroup(title: 'ウィジェット（PRO）', children: [
              SettingsRow(icon: '🏠', title: 'ホーム画面に写真ウィジェットを追加', subtitle: 'Androidのホーム画面を長押しして追加'),
              const Divider(height: 1, indent: 52),
              SettingsRow(icon: '📅', title: 'お迎え日カウントウィジェット', subtitle: 'ペットとの日数を表示'),
            ]),
            const SizedBox(height: 12),
          ],

          // アプリ設定
          _SettingsGroup(title: 'アプリ設定', children: [
            const SettingsRow(icon: '🔔', title: '通知設定', trailingText: 'ON'),
            const Divider(height: 1, indent: 52),
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
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (ctx) => SafeArea(child: Column(mainAxisSize: MainAxisSize.min, children: [
        ListTile(leading: const Icon(Icons.photo_library, color: AppColors.caramel), title: const Text('ギャラリーから選ぶ'), onTap: () => Navigator.pop(ctx, ImageSource.gallery)),
        ListTile(leading: const Icon(Icons.camera_alt, color: AppColors.caramel), title: const Text('カメラで撮影'), onTap: () => Navigator.pop(ctx, ImageSource.camera)),
      ])));
    if (source == null) return;
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(source: source, imageQuality: 80);
      if (picked == null) return;
      await provider.updatePet(pet.copyWith(profilePhotoPath: picked.path));
    } catch (e) { debugPrint('icon pick error: $e'); }
  }

  void _showEditProfile(BuildContext context, AppProvider provider, Pet pet) {
    showModalBottomSheet(context: context, isScrollControlled: true, backgroundColor: Colors.transparent,
      builder: (_) => _EditPetSheet(pet: pet));
  }

  void _showAddPet(BuildContext context, AppProvider provider) {
    showModalBottomSheet(context: context, isScrollControlled: true, backgroundColor: Colors.transparent,
      builder: (_) => _AddPetSheet());
  }

  void _showProDialog(BuildContext context, AppProvider provider) {
    showDialog(context: context, builder: (ctx) => AlertDialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Column(children: [
        Text('✨', style: TextStyle(fontSize: 48)), SizedBox(height: 8),
        Text('ぺとろぐ PRO', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textDark)),
      ]),
      content: const Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('PRO機能：', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textDark)), SizedBox(height: 8),
        Text('✓ 広告なし\n✓ 写真1日30枚まで\n✓ ペット無制限\n✓ ホーム画面ウィジェット', style: TextStyle(color: AppColors.textMid, height: 1.8)),
        SizedBox(height: 12),
        Text('¥380/月（初月無料）', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.caramel, fontSize: 16)),
        SizedBox(height: 4),
        Text('※これは試用版です。実際の課金は発生しません。', style: TextStyle(fontSize: 10, color: AppColors.textLight)),
      ]),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('キャンセル', style: TextStyle(color: AppColors.textMid))),
        ElevatedButton(
          onPressed: () { Navigator.pop(ctx); provider.setIsPro(true); ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('✨ PRO機能が有効になりました！'), backgroundColor: AppColors.caramel)); },
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.gold, foregroundColor: AppColors.textDark),
          child: const Text('試用する（無料）', style: TextStyle(fontWeight: FontWeight.bold))),
      ],
    ));
  }
}

// ─── 虹の橋セクション ─────────────────────────────────

class _RainbowBridgeSection extends StatefulWidget {
  final AppProvider provider;
  const _RainbowBridgeSection({required this.provider});
  @override State<_RainbowBridgeSection> createState() => _RainbowBridgeSectionState();
}

class _RainbowBridgeSectionState extends State<_RainbowBridgeSection> {
  bool _expanded = false;
  @override Widget build(BuildContext context) {
    final passed = widget.provider.passedPets;
    return _SettingsGroup(title: '🌈 虹の橋', children: [
      InkWell(onTap: () => setState(() => _expanded = !_expanded),
        child: Padding(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(children: [
            const Text('🌈', style: TextStyle(fontSize: 20)),
            const SizedBox(width: 8),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('亡くなったペット', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textDark)),
              Text(passed.isEmpty ? '登録なし' : '${passed.length}匹', style: const TextStyle(fontSize: 11, color: AppColors.textLight)),
            ])),
            Icon(_expanded ? Icons.expand_less : Icons.expand_more, color: AppColors.textLight),
          ]))),
      if (_expanded) ...[
        const Divider(height: 1, indent: 52),
        ...passed.map((p) => ListTile(
          leading: Text(p.species.emoji, style: const TextStyle(fontSize: 20)),
          title: Text(p.name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
          subtitle: p.passedDate != null ? Text('${p.passedDate!.year}年${p.passedDate!.month}月${p.passedDate!.day}日', style: const TextStyle(fontSize: 11, color: AppColors.textLight)) : null,
          trailing: IconButton(icon: const Icon(Icons.edit, size: 18, color: AppColors.textLight), onPressed: () => showModalBottomSheet(context: context, isScrollControlled: true, backgroundColor: Colors.transparent, builder: (_) => _EditPetSheet(pet: p))),
        )),
        const Divider(height: 1, indent: 52),
        ListTile(leading: const Icon(Icons.add, color: AppColors.textLight), title: const Text('亡くなったペットを追加', style: TextStyle(fontSize: 14, color: AppColors.textLight)),
          onTap: () => showModalBottomSheet(context: context, isScrollControlled: true, backgroundColor: Colors.transparent, builder: (_) => _AddPetSheet(isPassed: true))),
      ],
    ]);
  }
}

// ─── ペット追加シート ──────────────────────────────────

class _AddPetSheet extends StatefulWidget {
  final bool isPassed;
  const _AddPetSheet({this.isPassed = false});
  @override State<_AddPetSheet> createState() => _AddPetSheetState();
}

class _AddPetSheetState extends State<_AddPetSheet> {
  final _nameCtrl = TextEditingController();
  PetSpecies _species = PetSpecies.dog;
  PetGender _gender = PetGender.unknown;
  DateTime? _birthDate, _welcomeDate, _passedDate;

  @override Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      padding: EdgeInsets.only(left: 20, right: 20, top: 20, bottom: MediaQuery.of(context).viewInsets.bottom + 40),
      child: SingleChildScrollView(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(widget.isPassed ? '🌈 亡くなったペットを追加' : '🐾 ペットを追加', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textDark)),
        const SizedBox(height: 16),
        TextField(controller: _nameCtrl, decoration: const InputDecoration(labelText: '名前', hintText: '例：むぎ', hintStyle: TextStyle(color: AppColors.textLight)), onChanged: (_) => setState(() {})),
        const SizedBox(height: 14),
        const Text('種類', style: TextStyle(fontSize: 12, color: AppColors.textLight)), const SizedBox(height: 6),
        Wrap(spacing: 8, children: PetSpecies.values.map((s) => ChoiceChip(label: Text('${s.emoji} ${s.label}'), selected: _species == s, onSelected: (_) => setState(() => _species = s), selectedColor: AppColors.caramel, labelStyle: TextStyle(color: _species == s ? Colors.white : AppColors.textMid, fontSize: 12))).toList()),
        const SizedBox(height: 14),
        const Text('性別', style: TextStyle(fontSize: 12, color: AppColors.textLight)), const SizedBox(height: 6),
        Wrap(spacing: 8, children: PetGender.values.map((g) => ChoiceChip(label: Text(g.label), selected: _gender == g, onSelected: (_) => setState(() => _gender = g), selectedColor: AppColors.caramel, labelStyle: TextStyle(color: _gender == g ? Colors.white : AppColors.textMid, fontSize: 12))).toList()),
        const SizedBox(height: 14),
        _DatePickerRow(label: '誕生日', date: _birthDate, onPicked: (d) => setState(() => _birthDate = d)),
        _DatePickerRow(label: 'お迎えした日', date: _welcomeDate, onPicked: (d) => setState(() => _welcomeDate = d)),
        if (widget.isPassed) _DatePickerRow(label: '虹の橋を渡った日', date: _passedDate, onPicked: (d) => setState(() => _passedDate = d)),
        const SizedBox(height: 20),
        PetoButton(label: '✓ 追加する', onPressed: _nameCtrl.text.trim().isEmpty ? null : () async {
          await context.read<AppProvider>().addPet(Pet(name: _nameCtrl.text.trim(), species: _species, gender: _gender, birthDate: _birthDate, welcomeDate: _welcomeDate, passedDate: widget.isPassed ? _passedDate : null, createdAt: DateTime.now()));
          if (mounted) Navigator.pop(context);
        }),
      ])),
    );
  }
}

// ─── ペット編集シート ──────────────────────────────────

class _EditPetSheet extends StatefulWidget {
  final Pet pet;
  const _EditPetSheet({required this.pet});
  @override State<_EditPetSheet> createState() => _EditPetSheetState();
}

class _EditPetSheetState extends State<_EditPetSheet> {
  late TextEditingController _nameCtrl, _memoCtrl;
  late PetSpecies _species;
  late PetGender _gender;
  DateTime? _birthDate, _welcomeDate, _passedDate;
  bool _showPassedDate = false;

  @override void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.pet.name);
    _memoCtrl = TextEditingController(text: widget.pet.memo);
    _species = widget.pet.species; _gender = widget.pet.gender;
    _birthDate = widget.pet.birthDate; _welcomeDate = widget.pet.welcomeDate;
    _passedDate = widget.pet.passedDate;
    _showPassedDate = widget.pet.hasPassed;
  }

  @override Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      padding: EdgeInsets.only(left: 20, right: 20, top: 20, bottom: MediaQuery.of(context).viewInsets.bottom + 40),
      child: SingleChildScrollView(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('✏️ プロフィール編集', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textDark)),
        const SizedBox(height: 16),
        TextField(controller: _nameCtrl, decoration: const InputDecoration(labelText: '名前', hintStyle: TextStyle(color: AppColors.textLight))),
        const SizedBox(height: 14),
        const Text('種類', style: TextStyle(fontSize: 12, color: AppColors.textLight)), const SizedBox(height: 6),
        Wrap(spacing: 8, children: PetSpecies.values.map((s) => ChoiceChip(label: Text('${s.emoji} ${s.label}'), selected: _species == s, onSelected: (_) => setState(() => _species = s), selectedColor: AppColors.caramel, labelStyle: TextStyle(color: _species == s ? Colors.white : AppColors.textMid, fontSize: 12))).toList()),
        const SizedBox(height: 14),
        const Text('性別', style: TextStyle(fontSize: 12, color: AppColors.textLight)), const SizedBox(height: 6),
        Wrap(spacing: 8, children: PetGender.values.map((g) => ChoiceChip(label: Text(g.label), selected: _gender == g, onSelected: (_) => setState(() => _gender = g), selectedColor: AppColors.caramel, labelStyle: TextStyle(color: _gender == g ? Colors.white : AppColors.textMid, fontSize: 12))).toList()),
        const SizedBox(height: 14),
        _DatePickerRow(label: '誕生日', date: _birthDate, onPicked: (d) => setState(() => _birthDate = d), clearable: true, onCleared: () => setState(() => _birthDate = null)),
        _DatePickerRow(label: 'お迎えした日', date: _welcomeDate, onPicked: (d) => setState(() => _welcomeDate = d), clearable: true, onCleared: () => setState(() => _welcomeDate = null)),
        const SizedBox(height: 14),
        TextField(controller: _memoCtrl, maxLines: 2, decoration: const InputDecoration(labelText: 'メモ', hintText: '好きなおやつ、かかりつけ医など', hintStyle: TextStyle(color: AppColors.textLight))),
        const SizedBox(height: 14),
        // 虹の橋（折りたたみ）
        InkWell(onTap: () => setState(() => _showPassedDate = !_showPassedDate),
          child: Row(children: [
            Icon(_showPassedDate ? Icons.expand_less : Icons.expand_more, color: AppColors.textLight, size: 20),
            const SizedBox(width: 4),
            Text('🌈 虹の橋（亡くなった場合）', style: TextStyle(fontSize: 12, color: _showPassedDate ? AppColors.textMid : AppColors.textLight)),
          ])),
        if (_showPassedDate) ...[
          const SizedBox(height: 8),
          _DatePickerRow(label: '虹の橋を渡った日', date: _passedDate, onPicked: (d) => setState(() => _passedDate = d), clearable: true, onCleared: () => setState(() => _passedDate = null)),
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
}

// ─── 日付選択行 ───────────────────────────────────────

class _DatePickerRow extends StatelessWidget {
  final String label; final DateTime? date;
  final ValueChanged<DateTime> onPicked;
  final bool clearable; final VoidCallback? onCleared;
  const _DatePickerRow({required this.label, required this.date, required this.onPicked, this.clearable = false, this.onCleared});

  @override Widget build(BuildContext context) {
    return Padding(padding: const EdgeInsets.only(bottom: 8), child: Row(children: [
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textLight)),
        const SizedBox(height: 2),
        Text(date != null ? '${date!.year}年${date!.month}月${date!.day}日' : '未設定',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: date != null ? AppColors.textDark : AppColors.textLight)),
      ])),
      if (clearable && date != null) IconButton(icon: const Icon(Icons.clear, size: 18, color: AppColors.textLight), onPressed: onCleared),
      TextButton(onPressed: () async {
        final picked = await showDatePicker(context: context, initialDate: date ?? DateTime.now(), firstDate: DateTime(2000), lastDate: DateTime(2100));
        if (picked != null) onPicked(picked);
      }, child: Text(date != null ? '変更' : '設定', style: const TextStyle(color: AppColors.caramel))),
    ]));
  }
}

// ─── 設定グループ ─────────────────────────────────────

class _SettingsGroup extends StatelessWidget {
  final String title; final List<Widget> children;
  const _SettingsGroup({required this.title, required this.children});
  @override Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Padding(padding: const EdgeInsets.only(left: 4, bottom: 8),
        child: Text(title.toUpperCase(), style: const TextStyle(fontSize: 10, color: AppColors.textLight, letterSpacing: 1))),
      Material(color: Colors.white, borderRadius: BorderRadius.circular(14), child: Column(children: children)),
    ]);
  }
}

class _ProBanner extends StatelessWidget {
  final VoidCallback onUpgrade;
  const _ProBanner({required this.onUpgrade});
  @override Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(color: const Color(0xFF3D2E1E), borderRadius: BorderRadius.circular(20)),
      padding: const EdgeInsets.all(20),
      child: Row(children: [
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('ぺとろぐ PRO', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.goldRing, letterSpacing: 2)),
          const SizedBox(height: 5),
          const Text('広告なし・ウィジェット\n写真1日30枚まで', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
          const SizedBox(height: 4),
          const Text('¥380/月（初月無料）', style: TextStyle(fontSize: 12, color: Colors.white70)),
          const SizedBox(height: 14),
          ElevatedButton(onPressed: onUpgrade,
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.gold, foregroundColor: const Color(0xFF3D2E1E), padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8)),
            child: const Text('✨ 試してみる', style: TextStyle(fontWeight: FontWeight.bold))),
        ])),
        const Text('🐾', style: TextStyle(fontSize: 60, color: Colors.white12)),
      ]),
    );
  }
}
