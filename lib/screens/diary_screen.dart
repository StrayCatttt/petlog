import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import '../repositories/app_provider.dart';
import '../models/models.dart';
import '../theme/app_theme.dart';
import '../widgets/common_widgets.dart';
import '../utils/ad_helper.dart';

class DiaryScreen extends StatelessWidget {
  const DiaryScreen({super.key});
  @override Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    return Scaffold(
      backgroundColor: AppColors.background,
      floatingActionButton: FloatingActionButton(
        onPressed: () => showDialog(context: context, builder: (_) => _AddDiaryDialog(provider: provider)),
        backgroundColor: AppColors.caramel,
        child: const Icon(Icons.add, color: Colors.white, size: 28),
      ),
      body: CustomScrollView(slivers: [
        SliverAppBar(
          title: const Text('📅 思い出カレンダー', style: TextStyle(fontWeight: FontWeight.bold)),
          backgroundColor: const Color(0xFFFBF0DE), floating: true,
          actions: [
            PopupMenuButton<DiarySort>(
              icon: const Icon(Icons.sort, color: AppColors.caramel),
              onSelected: (s) => provider.setDiarySort(s),
              itemBuilder: (_) => [
                const PopupMenuItem(value: DiarySort.dateDesc, child: Text('新しい順')),
                const PopupMenuItem(value: DiarySort.dateAsc, child: Text('古い順')),
                const PopupMenuItem(value: DiarySort.petName, child: Text('ペット名順')),
              ],
            ),
          ],
        ),
        if (provider.diaryEntries.isEmpty)
          const SliverFillRemaining(child: Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
            Text('📖', style: TextStyle(fontSize: 48)), SizedBox(height: 12),
            Text('まだ日記がありません\n＋ボタンで記録してみよう', textAlign: TextAlign.center, style: TextStyle(color: AppColors.textLight)),
          ])))
        else
          SliverPadding(padding: const EdgeInsets.only(bottom: 100),
            sliver: SliverList(delegate: SliverChildBuilderDelegate(
              (ctx, i) => _DiaryCard(entry: provider.diaryEntries[i], pets: provider.activePets),
              childCount: provider.diaryEntries.length))),
        if (!provider.isPro) const SliverToBoxAdapter(child: Padding(padding: EdgeInsets.symmetric(vertical: 8), child: Center(child: BannerAdWidget()))),
      ]),
    );
  }
}

class _DiaryCard extends StatelessWidget {
  final DiaryEntry entry; final List<Pet> pets;
  const _DiaryCard({required this.entry, required this.pets});
  @override Widget build(BuildContext context) {
    final firstPhoto = entry.photoUris.isNotEmpty ? entry.photoUris.first : null;
    final isVideo = firstPhoto != null && (firstPhoto.endsWith('.mp4') || firstPhoto.endsWith('.mov'));
    final petName = entry.isShared ? '共通' : pets.firstWhere((p)=>p.id==entry.petId, orElse:()=>Pet(name:'不明',createdAt:DateTime.now())).name;
    return Padding(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: PetoCard(onTap: (){}, onLongPress: ()=>_showOptions(context),
        child: Row(children: [
          SizedBox(width: 40, child: Column(children: [
            Text('${entry.date.day}', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: AppColors.caramel, height: 1)),
            Text(DateFormat('E','ja').format(entry.date), style: const TextStyle(fontSize: 11, color: AppColors.textLight)),
          ])),
          Container(width: 1, height: 60, color: AppColors.caramelLight, margin: const EdgeInsets.symmetric(horizontal: 12)),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Text(entry.mood.emoji, style: const TextStyle(fontSize: 16)),
              const SizedBox(width: 6),
              Container(padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(color: entry.isShared ? AppColors.sagePale : AppColors.caramelPale, borderRadius: BorderRadius.circular(8)),
                child: Text(petName, style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: entry.isShared ? AppColors.sage : AppColors.caramel))),
            ]),
            const SizedBox(height: 3),
            Text(entry.body.isEmpty ? '（本文なし）' : entry.body,
                style: const TextStyle(fontSize: 12, color: AppColors.textMid), maxLines: 2, overflow: TextOverflow.ellipsis),
          ])),
          if (firstPhoto != null) ...[
            const SizedBox(width: 12),
            ClipRRect(borderRadius: BorderRadius.circular(10),
              child: isVideo
                  ? Container(width: 56, height: 56, color: Colors.black87, child: const Center(child: Icon(Icons.play_circle, color: Colors.white, size: 28)))
                  : Image.file(File(firstPhoto), width: 56, height: 56, fit: BoxFit.cover, errorBuilder: (_,__,___) => const SizedBox(width: 56, height: 56))),
          ],
        ])));
  }
  void _showOptions(BuildContext context) {
    showDialog(context: context, builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text(DateFormat('M月d日の記録').format(entry.date), style: const TextStyle(fontSize: 16)),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        ListTile(leading: const Icon(Icons.edit, color: AppColors.caramel), title: const Text('編集'), onTap: () { Navigator.pop(ctx); showDialog(context: context, builder: (_) => _EditDiaryDialog(entry: entry, pets: pets)); }),
        ListTile(leading: const Icon(Icons.delete, color: Colors.red), title: const Text('削除', style: TextStyle(color: Colors.red)), onTap: () { Navigator.pop(ctx); showDialog(context: context, builder: (d) => AlertDialog(title: const Text('削除しますか？'), actions: [TextButton(onPressed:()=>Navigator.pop(d), child: const Text('キャンセル')), ElevatedButton(onPressed:(){Navigator.pop(d); context.read<AppProvider>().deleteEntry(entry.id!);}, style: ElevatedButton.styleFrom(backgroundColor: Colors.red), child: const Text('削除'))])); }),
      ]),
    ));
  }
}

// ─── 日記追加 Dialog ─────────────────────────────────────

class _AddDiaryDialog extends StatefulWidget {
  final AppProvider provider;
  const _AddDiaryDialog({required this.provider});
  @override State<_AddDiaryDialog> createState() => _AddDiaryDialogState();
}

class _AddDiaryDialogState extends State<_AddDiaryDialog> {
  DiaryMood _mood = DiaryMood.happy;
  final _bodyCtrl = TextEditingController();
  final List<String> _confirmedMedia = [];
  bool _picking = false;
  bool _saving = false;
  late int _selectedPetId;

  // ✅ ダイアログ開いた時点の上限を固定で記録（保存前に変化させない）
  late int _maxPhotos;

  @override void initState() {
    super.initState();
    _selectedPetId = widget.provider.activePet?.id ?? -1;
    // ✅ 開いた時点のquotaを固定（途中でrewardが変わっても表示がおかしくならない）
    _maxPhotos = widget.provider.isPro ? 30 : widget.provider.quotaTotal - widget.provider.quotaUsed;
    if (_maxPhotos < 0) _maxPhotos = 0;
  }

  // ✅ ファイル確認後のみ追加（キャンセルは何もしない）
  Future<void> _pickMedia({bool video = false, ImageSource source = ImageSource.gallery}) async {
    if (_picking) return;
    setState(() => _picking = true);
    try {
      final picker = ImagePicker();
      if (video) {
        final f = await picker.pickVideo(source: source);
        // ✅ nullチェック・ファイル存在確認してから追加
        if (f != null && await File(f.path).exists()) {
          if (mounted) setState(() => _confirmedMedia.add(f.path));
        }
      } else {
        final files = await picker.pickMultiImage();
        // ✅ キャンセル（空リスト）でも何もしない
        final valid = <String>[];
        for (final f in files) {
          if (await File(f.path).exists()) valid.add(f.path);
        }
        if (valid.isNotEmpty && mounted) setState(() => _confirmedMedia.addAll(valid));
      }
    } catch (e) {
      debugPrint('pick error: $e');
    } finally {
      // ✅ 必ずfalseに戻す
      if (mounted) setState(() => _picking = false);
    }
  }

  void _showPickOptions() {
    showDialog(context: context, builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Text('写真・動画を追加'),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        ListTile(leading: const Icon(Icons.photo_library, color: AppColors.caramel), title: const Text('写真をギャラリーから'), onTap: () { Navigator.pop(ctx); _pickMedia(); }),
        ListTile(leading: const Icon(Icons.videocam, color: AppColors.caramel), title: const Text('動画をギャラリーから'), onTap: () { Navigator.pop(ctx); _pickMedia(video: true); }),
        ListTile(leading: const Icon(Icons.camera_alt, color: AppColors.caramel), title: const Text('カメラで撮影'), onTap: () { Navigator.pop(ctx); _pickMedia(source: ImageSource.camera); }),
      ]),
    ));
  }

  @override Widget build(BuildContext context) {
    // ✅ 追加できる枚数は _maxPhotos - 現在追加枚数
    final canAddMore = _confirmedMedia.length < _maxPhotos;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: SingleChildScrollView(child: Padding(padding: const EdgeInsets.all(20), child: Column(
        crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
        const Text('📝 新しい記録を追加', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textDark)),
        const SizedBox(height: 14),
        // 対象ペット
        const Text('対象', style: TextStyle(fontSize: 12, color: AppColors.textLight)), const SizedBox(height: 6),
        SingleChildScrollView(scrollDirection: Axis.horizontal, child: Row(children: [
          _PetChip(label: '🌐 共通', selected: _selectedPetId == -1, onTap: () => setState(() => _selectedPetId = -1)),
          const SizedBox(width: 6),
          ...widget.provider.activePets.map((pet) => Padding(padding: const EdgeInsets.only(right: 6),
            child: _PetChip(label: '${pet.species.emoji} ${pet.name}', selected: _selectedPetId == pet.id, onTap: () => setState(() => _selectedPetId = pet.id!)))),
        ])),
        const SizedBox(height: 12),
        // 気分タグ
        const Text('気分タグ', style: TextStyle(fontSize: 12, color: AppColors.textLight)), const SizedBox(height: 6),
        SizedBox(height: 44, child: ListView(scrollDirection: Axis.horizontal, children: DiaryMood.values.map((m) => GestureDetector(
          onTap: () => setState(() => _mood = m),
          child: Container(margin: const EdgeInsets.only(right: 6), padding: const EdgeInsets.all(5),
            decoration: BoxDecoration(shape: BoxShape.circle, color: _mood == m ? AppColors.caramelPale : Colors.transparent, border: Border.all(color: _mood == m ? AppColors.caramel : Colors.transparent, width: 1.5)),
            child: Text(m.emoji, style: const TextStyle(fontSize: 26))),
        )).toList())),
        const SizedBox(height: 12),
        // 本文
        const Text('本文', style: TextStyle(fontSize: 12, color: AppColors.textLight)), const SizedBox(height: 4),
        TextField(controller: _bodyCtrl, maxLines: 3, decoration: const InputDecoration(hintText: '今日の様子を書いてみよう…', hintStyle: TextStyle(color: AppColors.textLight))),
        const SizedBox(height: 12),
        // 写真・動画
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text(
            widget.provider.isPro
              ? '写真・動画（${_confirmedMedia.length}枚）'
              : '写真・動画（${_confirmedMedia.length} / ${_maxPhotos}枚）',
            style: const TextStyle(fontSize: 12, color: AppColors.textLight)),
          if (_picking) const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.caramel)),
        ]),
        const SizedBox(height: 6),
        // プレビュー
        if (_confirmedMedia.isNotEmpty) ...[
          SizedBox(height: 80, child: ListView.builder(scrollDirection: Axis.horizontal, itemCount: _confirmedMedia.length, itemBuilder: (ctx, i) {
            final isVideo = _confirmedMedia[i].endsWith('.mp4') || _confirmedMedia[i].endsWith('.mov');
            return Stack(children: [
              Container(width: 80, height: 80, margin: const EdgeInsets.only(right: 8),
                child: ClipRRect(borderRadius: BorderRadius.circular(10), child: isVideo
                    ? Container(color: Colors.black87, child: const Center(child: Icon(Icons.play_circle, color: Colors.white, size: 32)))
                    : Image.file(File(_confirmedMedia[i]), fit: BoxFit.cover, errorBuilder: (_,__,___) => Container(color: AppColors.caramelPale)))),
              Positioned(top: 2, right: 10, child: GestureDetector(onTap: () => setState(() => _confirmedMedia.removeAt(i)),
                child: Container(width: 18, height: 18, decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle), child: const Icon(Icons.close, color: Colors.white, size: 12)))),
            ]);
          })),
          const SizedBox(height: 8),
        ],
        // ✅ 追加ボタン：_pickingがtrueでもボタンは残す（ローディング表示）
        // ✅ canAddMoreがfalseでもPro以外は上限に達したメッセージを表示
        if (canAddMore)
          ElevatedButton.icon(
            onPressed: _picking ? null : _showPickOptions,
            icon: _picking
                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Icon(Icons.add_photo_alternate, size: 20),
            label: Text(_picking ? '読み込み中...' : '📷 写真・動画を追加', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 48),
              backgroundColor: AppColors.sage, foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
          )
        else if (!widget.provider.isPro && _maxPhotos > 0)
          Container(
            width: double.infinity, padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: Colors.orange.shade50, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.orange.shade200)),
            child: const Text('📷 今日の写真枠が上限に達しました\n動画広告を見ると枠を増やせます', style: TextStyle(fontSize: 12, color: Colors.orange), textAlign: TextAlign.center),
          ),
        const SizedBox(height: 16),
        Row(children: [
          Expanded(child: OutlinedButton(
            onPressed: _saving ? null : () => Navigator.pop(context),
            child: const Text('キャンセル', style: TextStyle(color: AppColors.textMid)))),
          const SizedBox(width: 12),
          // ✅ 保存ボタン：常に押せる（本文のみでもOK）
          Expanded(child: ElevatedButton(
            onPressed: _saving ? null : () async {
              setState(() => _saving = true);
              try {
                await widget.provider.addDiaryEntry(
                  petId: _selectedPetId, mood: _mood,
                  body: _bodyCtrl.text, photoUris: _confirmedMedia);
                if (mounted) Navigator.pop(context);
              } catch (e) {
                debugPrint('save error: $e');
                if (mounted) setState(() => _saving = false);
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.caramel, minimumSize: const Size(double.infinity, 48)),
            child: _saving
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Text('✓ 保存する', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
          )),
        ]),
      ]))),
    );
  }
}

// ─── ペット選択チップ ─────────────────────────────────

class _PetChip extends StatelessWidget {
  final String label; final bool selected; final VoidCallback onTap;
  const _PetChip({required this.label, required this.selected, required this.onTap});
  @override Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(color: selected ? AppColors.caramel : AppColors.caramelPale, borderRadius: BorderRadius.circular(20)),
      child: Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: selected ? Colors.white : AppColors.textMid))),
  );
}

// ─── 日記編集 Dialog ─────────────────────────────────────

class _EditDiaryDialog extends StatefulWidget {
  final DiaryEntry entry; final List<Pet> pets;
  const _EditDiaryDialog({required this.entry, required this.pets});
  @override State<_EditDiaryDialog> createState() => _EditDiaryDialogState();
}
class _EditDiaryDialogState extends State<_EditDiaryDialog> {
  late DiaryMood _mood;
  late TextEditingController _bodyCtrl;
  late List<String> _media;
  late int _selectedPetId;
  bool _picking = false;
  bool _saving = false;

  @override void initState() {
    super.initState();
    _mood = widget.entry.mood;
    _bodyCtrl = TextEditingController(text: widget.entry.body);
    _media = List.from(widget.entry.photoUris);
    _selectedPetId = widget.entry.petId;
  }

  Future<void> _pickMedia({bool video = false}) async {
    if (_picking) return;
    setState(() => _picking = true);
    try {
      final picker = ImagePicker();
      if (video) {
        final f = await picker.pickVideo(source: ImageSource.gallery);
        if (f != null && await File(f.path).exists() && mounted) setState(() => _media.add(f.path));
      } else {
        final files = await picker.pickMultiImage();
        final valid = <String>[];
        for (final f in files) { if (await File(f.path).exists()) valid.add(f.path); }
        if (valid.isNotEmpty && mounted) setState(() => _media.addAll(valid));
      }
    } finally { if (mounted) setState(() => _picking = false); }
  }

  @override Widget build(BuildContext context) => Dialog(
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
    child: SingleChildScrollView(child: Padding(padding: const EdgeInsets.all(20), child: Column(
      crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
      const Text('✏️ 日記を編集', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textDark)),
      const SizedBox(height: 14),
      SingleChildScrollView(scrollDirection: Axis.horizontal, child: Row(children: [
        _PetChip(label: '🌐 共通', selected: _selectedPetId == -1, onTap: () => setState(() => _selectedPetId = -1)),
        const SizedBox(width: 6),
        ...widget.pets.map((pet) => Padding(padding: const EdgeInsets.only(right: 6),
          child: _PetChip(label: '${pet.species.emoji} ${pet.name}', selected: _selectedPetId == pet.id, onTap: () => setState(() => _selectedPetId = pet.id!)))),
      ])),
      const SizedBox(height: 12),
      SizedBox(height: 44, child: ListView(scrollDirection: Axis.horizontal, children: DiaryMood.values.map((m) => GestureDetector(
        onTap: () => setState(() => _mood = m),
        child: Container(margin: const EdgeInsets.only(right: 6), padding: const EdgeInsets.all(5),
          decoration: BoxDecoration(shape: BoxShape.circle, color: _mood == m ? AppColors.caramelPale : Colors.transparent, border: Border.all(color: _mood == m ? AppColors.caramel : Colors.transparent, width: 1.5)),
          child: Text(m.emoji, style: const TextStyle(fontSize: 26))),
      )).toList())),
      const SizedBox(height: 12),
      TextField(controller: _bodyCtrl, maxLines: 3, decoration: const InputDecoration(hintText: '本文', hintStyle: TextStyle(color: AppColors.textLight))),
      const SizedBox(height: 12),
      if (_media.isNotEmpty) ...[
        SizedBox(height: 80, child: ListView.builder(scrollDirection: Axis.horizontal, itemCount: _media.length, itemBuilder: (ctx, i) {
          final isVideo = _media[i].endsWith('.mp4') || _media[i].endsWith('.mov');
          return Stack(children: [
            Container(width: 80, height: 80, margin: const EdgeInsets.only(right: 8),
              child: ClipRRect(borderRadius: BorderRadius.circular(10), child: isVideo
                  ? Container(color: Colors.black87, child: const Center(child: Icon(Icons.play_circle, color: Colors.white, size: 32)))
                  : Image.file(File(_media[i]), fit: BoxFit.cover, errorBuilder: (_,__,___) => Container(color: AppColors.caramelPale)))),
            Positioned(top: 2, right: 10, child: GestureDetector(onTap: () => setState(() => _media.removeAt(i)),
              child: Container(width: 18, height: 18, decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle), child: const Icon(Icons.close, color: Colors.white, size: 12)))),
          ]);
        })),
        const SizedBox(height: 8),
      ],
      ElevatedButton.icon(
        onPressed: _picking ? null : () => showDialog(context: context, builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('メディアを追加'),
          content: Column(mainAxisSize: MainAxisSize.min, children: [
            ListTile(leading: const Icon(Icons.photo_library, color: AppColors.caramel), title: const Text('写真'), onTap: () { Navigator.pop(ctx); _pickMedia(); }),
            ListTile(leading: const Icon(Icons.videocam, color: AppColors.caramel), title: const Text('動画'), onTap: () { Navigator.pop(ctx); _pickMedia(video: true); }),
          ]))),
        icon: _picking
            ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
            : const Icon(Icons.add_photo_alternate, size: 18),
        label: Text(_picking ? '読み込み中...' : '写真・動画を追加', style: const TextStyle(fontWeight: FontWeight.bold)),
        style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 44), backgroundColor: AppColors.sage, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)))),
      const SizedBox(height: 16),
      Row(children: [
        Expanded(child: OutlinedButton(onPressed: _saving ? null : () => Navigator.pop(context), child: const Text('キャンセル', style: TextStyle(color: AppColors.textMid)))),
        const SizedBox(width: 12),
        Expanded(child: ElevatedButton(
          onPressed: _saving ? null : () async {
            setState(() => _saving = true);
            try {
              await context.read<AppProvider>().updateDiaryEntry(widget.entry.copyWith(petId: _selectedPetId, mood: _mood, body: _bodyCtrl.text, photoUris: _media));
              if (mounted) Navigator.pop(context);
            } catch (e) {
              if (mounted) setState(() => _saving = false);
            }
          },
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.caramel, minimumSize: const Size(double.infinity, 44)),
          child: _saving
              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : const Text('✓ 保存', style: TextStyle(fontWeight: FontWeight.bold)),
        )),
      ]),
    ]))),
  );
}
