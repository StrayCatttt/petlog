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

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    return Scaffold(
      backgroundColor: AppColors.background,
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddSheet(context, provider),
        backgroundColor: AppColors.caramel,
        child: const Icon(Icons.add, color: Colors.white, size: 28),
      ),
      body: CustomScrollView(slivers: [
        const SliverAppBar(title: Text('📅 思い出カレンダー', style: TextStyle(fontWeight: FontWeight.bold)), backgroundColor: Color(0xFFFBF0DE), floating: true),
        if (provider.diaryEntries.isEmpty)
          const SliverFillRemaining(child: Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
            Text('🐾', style: TextStyle(fontSize: 48)),
            SizedBox(height: 12),
            Text('まだ日記がありません\n＋ボタンで記録してみよう', textAlign: TextAlign.center, style: TextStyle(color: AppColors.textLight)),
          ])))
        else
          SliverPadding(
            padding: const EdgeInsets.only(bottom: 100),
            sliver: SliverList(delegate: SliverChildBuilderDelegate(
              (ctx, i) => _DiaryCard(entry: provider.diaryEntries[i]),
              childCount: provider.diaryEntries.length,
            )),
          ),
        if (!provider.isPro) const SliverToBoxAdapter(child: Padding(padding: EdgeInsets.symmetric(vertical: 8), child: Center(child: BannerAdWidget()))),
      ]),
    );
  }

  void _showAddSheet(BuildContext context, AppProvider provider) {
    if (!provider.isPro && provider.quotaRemaining <= 0) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('写真枠が上限に達しました'),
          content: const Text('今日の写真は追加できません。\n動画広告を見て枠を増やすか、Proにアップグレードしてください。'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('閉じる')),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(ctx);
                final rewarded = await rewardAdManager.show(context);
                if (rewarded) {
                  provider.applyRewardBonus();
                  if (context.mounted) showModalBottomSheet(context: context, isScrollControlled: true, backgroundColor: Colors.transparent, builder: (_) => const _AddDiarySheet());
                }
              },
              child: const Text('動画を見る'),
            ),
          ],
        ),
      );
      return;
    }
    showModalBottomSheet(context: context, isScrollControlled: true, backgroundColor: Colors.transparent, builder: (_) => const _AddDiarySheet());
  }
}

class _DiaryCard extends StatelessWidget {
  final DiaryEntry entry;
  const _DiaryCard({required this.entry});

  @override
  Widget build(BuildContext context) {
    final firstPhoto = entry.photoUris.isNotEmpty ? entry.photoUris.first : null;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: PetoCard(
        onTap: () {},
        onLongPress: () => _showOptions(context),
        child: Row(children: [
          // 日付
          SizedBox(width: 40, child: Column(children: [
            Text('${entry.date.day}', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: AppColors.caramel, height: 1)),
            Text(DateFormat('E', 'ja').format(entry.date), style: const TextStyle(fontSize: 11, color: AppColors.textLight)),
          ])),
          Container(width: 1, height: 52, color: AppColors.caramelLight, margin: const EdgeInsets.symmetric(horizontal: 12)),
          // 本文
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(entry.mood.emoji, style: const TextStyle(fontSize: 18)),
            const SizedBox(height: 2),
            Text(entry.body.isEmpty ? '（本文なし）' : entry.body, style: const TextStyle(fontSize: 12, color: AppColors.textMid), maxLines: 2, overflow: TextOverflow.ellipsis),
          ])),
          // サムネイル（写真があるときのみ表示）
          if (firstPhoto != null) ...[
            const SizedBox(width: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.file(File(firstPhoto), width: 56, height: 56, fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const SizedBox(width: 56, height: 56)),
            ),
          ],
        ]),
      ),
    );
  }

  void _showOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          ListTile(leading: const Icon(Icons.edit, color: AppColors.caramel), title: const Text('編集'), onTap: () {
            Navigator.pop(ctx);
            showModalBottomSheet(context: context, isScrollControlled: true, backgroundColor: Colors.transparent, builder: (_) => _EditDiarySheet(entry: entry));
          }),
          ListTile(leading: const Icon(Icons.delete, color: Colors.red), title: const Text('削除', style: TextStyle(color: Colors.red)), onTap: () {
            Navigator.pop(ctx);
            _confirmDelete(context);
          }),
        ]),
      ),
    );
  }

  void _confirmDelete(BuildContext context) {
    showDialog(context: context, builder: (ctx) => AlertDialog(
      title: const Text('日記を削除しますか？'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('キャンセル')),
        ElevatedButton(
          onPressed: () { Navigator.pop(ctx); context.read<AppProvider>().deleteEntry(entry.id!); },
          style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
          child: const Text('削除'),
        ),
      ],
    ));
  }
}

// ─── 日記追加シート ───────────────────────────────────

class _AddDiarySheet extends StatefulWidget {
  const _AddDiarySheet();
  @override
  State<_AddDiarySheet> createState() => _AddDiarySheetState();
}

class _AddDiarySheetState extends State<_AddDiarySheet> {
  DiaryMood _mood = DiaryMood.happy;
  final _bodyCtrl = TextEditingController();
  final List<String> _photos = [];
  final _picker = ImagePicker();

  Future<void> _pickPhoto() async {
    final provider = context.read<AppProvider>();
    final limit = provider.isPro ? 30 : provider.quotaRemaining;
    final remaining = limit - _photos.length;
    if (remaining <= 0) return;
    final files = await _picker.pickMultiImage(limit: remaining);
    if (files.isNotEmpty) setState(() => _photos.addAll(files.map((f) => f.path)));
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final limit = provider.isPro ? 30 : provider.quotaRemaining;
    return Container(
      decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      padding: EdgeInsets.only(left: 20, right: 20, top: 20, bottom: MediaQuery.of(context).viewInsets.bottom + 40),
      child: SingleChildScrollView(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('📝 新しい記録を追加', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textDark)),
        const SizedBox(height: 20),
        const Text('気分タグ', style: TextStyle(fontSize: 12, color: AppColors.textLight)),
        const SizedBox(height: 8),
        SizedBox(height: 48, child: ListView(scrollDirection: Axis.horizontal, children: DiaryMood.values.map((m) => GestureDetector(
          onTap: () => setState(() => _mood = m),
          child: Container(
            margin: const EdgeInsets.only(right: 8), padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(shape: BoxShape.circle, color: _mood == m ? AppColors.caramelPale : Colors.transparent, border: Border.all(color: _mood == m ? AppColors.caramel : Colors.transparent, width: 1.5)),
            child: Text(m.emoji, style: const TextStyle(fontSize: 28)),
          ),
        )).toList())),
        const SizedBox(height: 16),
        const Text('本文', style: TextStyle(fontSize: 12, color: AppColors.textLight)),
        const SizedBox(height: 6),
        TextField(controller: _bodyCtrl, maxLines: 4, decoration: const InputDecoration(hintText: '今日の様子を書いてみよう…')),
        const SizedBox(height: 16),
        Text('写真・動画（残り ${limit - _photos.length} 枚）', style: const TextStyle(fontSize: 12, color: AppColors.textLight)),
        const SizedBox(height: 6),
        if (_photos.isNotEmpty) ...[
          SizedBox(height: 80, child: ListView(scrollDirection: Axis.horizontal, children: _photos.map((p) =>
            Container(width: 80, height: 80, margin: const EdgeInsets.only(right: 8),
              child: ClipRRect(borderRadius: BorderRadius.circular(10), child: Image.file(File(p), fit: BoxFit.cover)))
          ).toList())),
          const SizedBox(height: 8),
        ],
        if (_photos.length < limit)
          OutlinedButton.icon(
            onPressed: _pickPhoto,
            icon: const Icon(Icons.photo_library, color: AppColors.caramelLight),
            label: const Text('📷 ギャラリーから選択', style: TextStyle(color: AppColors.caramelLight, fontWeight: FontWeight.bold)),
            style: OutlinedButton.styleFrom(minimumSize: const Size(double.infinity, 52), side: const BorderSide(color: AppColors.caramelLight, width: 2), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
          ),
        const SizedBox(height: 20),
        PetoButton(label: '✓ 保存する', onPressed: () async {
          await provider.addDiaryEntry(mood: _mood, body: _bodyCtrl.text, photoUris: _photos);
          if (mounted) Navigator.pop(context);
        }),
      ])),
    );
  }
}

// ─── 日記編集シート ───────────────────────────────────

class _EditDiarySheet extends StatefulWidget {
  final DiaryEntry entry;
  const _EditDiarySheet({required this.entry});
  @override
  State<_EditDiarySheet> createState() => _EditDiarySheetState();
}

class _EditDiarySheetState extends State<_EditDiarySheet> {
  late DiaryMood _mood;
  late TextEditingController _bodyCtrl;
  late List<String> _photos;
  final _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _mood = widget.entry.mood;
    _bodyCtrl = TextEditingController(text: widget.entry.body);
    _photos = List.from(widget.entry.photoUris);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      padding: EdgeInsets.only(left: 20, right: 20, top: 20, bottom: MediaQuery.of(context).viewInsets.bottom + 40),
      child: SingleChildScrollView(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('✏️ 日記を編集', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textDark)),
        const SizedBox(height: 20),
        SizedBox(height: 48, child: ListView(scrollDirection: Axis.horizontal, children: DiaryMood.values.map((m) => GestureDetector(
          onTap: () => setState(() => _mood = m),
          child: Container(margin: const EdgeInsets.only(right: 8), padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(shape: BoxShape.circle, color: _mood == m ? AppColors.caramelPale : Colors.transparent, border: Border.all(color: _mood == m ? AppColors.caramel : Colors.transparent, width: 1.5)),
            child: Text(m.emoji, style: const TextStyle(fontSize: 28))),
        )).toList())),
        const SizedBox(height: 16),
        TextField(controller: _bodyCtrl, maxLines: 4, decoration: const InputDecoration(hintText: '今日の様子を書いてみよう…')),
        const SizedBox(height: 20),
        PetoButton(label: '✓ 保存する', onPressed: () async {
          final updated = widget.entry.copyWith(mood: _mood, body: _bodyCtrl.text, photoUris: _photos);
          await context.read<AppProvider>().updateDiaryEntry(updated);
          if (mounted) Navigator.pop(context);
        }),
      ])),
    );
  }
}
