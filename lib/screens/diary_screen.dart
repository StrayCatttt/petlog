import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import '../repositories/app_provider.dart';
import '../models/models.dart';
import '../theme/app_theme.dart';
import '../widgets/common_widgets.dart';

class DiaryScreen extends StatelessWidget {
  const DiaryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();

    return Scaffold(
      backgroundColor: AppColors.background,
      floatingActionButton: FloatingActionButton(
        onPressed: () => showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (_) => const _AddDiarySheet(),
        ),
        backgroundColor: AppColors.caramel,
        child: const Text('＋', style: TextStyle(fontSize: 28, color: Colors.white)),
      ),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            title: const Text('📅 思い出カレンダー', style: TextStyle(fontWeight: FontWeight.bold)),
            backgroundColor: const Color(0xFFFBF0DE),
            floating: true,
          ),
          if (provider.diaryEntries.isEmpty)
            const SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('🐾', style: TextStyle(fontSize: 48)),
                    SizedBox(height: 12),
                    Text('まだ日記がありません\n＋ボタンで記録してみよう', textAlign: TextAlign.center, style: TextStyle(color: AppColors.textLight)),
                  ],
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.only(bottom: 100),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (ctx, i) => _DiaryCard(entry: provider.diaryEntries[i]),
                  childCount: provider.diaryEntries.length,
                ),
              ),
            ),
          if (!provider.isPro)
            const SliverToBoxAdapter(child: BannerAdPlaceholder()),
        ],
      ),
    );
  }
}

class _DiaryCard extends StatelessWidget {
  final DiaryEntry entry;
  const _DiaryCard({required this.entry});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: PetoCard(
        onTap: () {},
        child: Row(
          children: [
            // 日付
            SizedBox(
              width: 40,
              child: Column(
                children: [
                  Text('${entry.date.day}', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: AppColors.caramel, height: 1)),
                  Text(DateFormat('E', 'ja').format(entry.date), style: const TextStyle(fontSize: 11, color: AppColors.textLight)),
                ],
              ),
            ),
            Container(width: 1, height: 52, color: AppColors.caramelLight, margin: const EdgeInsets.symmetric(horizontal: 12)),
            // 本文
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(entry.mood.emoji, style: const TextStyle(fontSize: 18)),
                  const SizedBox(height: 2),
                  Text(
                    entry.body.isEmpty ? '（本文なし）' : entry.body,
                    style: const TextStyle(fontSize: 12, color: AppColors.textMid),
                    maxLines: 2, overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            // サムネイル
            Container(
              width: 56, height: 56,
              decoration: BoxDecoration(borderRadius: BorderRadius.circular(10), color: AppColors.caramelPale),
              child: entry.photoUris.isNotEmpty
                  ? ClipRRect(borderRadius: BorderRadius.circular(10), child: Image.asset(entry.photoUris.first, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const Center(child: Text('🐾', style: TextStyle(fontSize: 26)))))
                  : const Center(child: Text('🐾', style: TextStyle(fontSize: 26))),
            ),
          ],
        ),
      ),
    );
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
    if (_photos.length >= provider.quotaRemaining && !provider.isPro) {
      final ok = await showRewardDialog(context);
      if (ok && mounted) provider.applyRewardBonus();
      return;
    }
    final files = await _picker.pickMultiImage(limit: provider.isPro ? 30 : provider.quotaRemaining - _photos.length);
    if (files.isNotEmpty) setState(() => _photos.addAll(files.map((f) => f.path)));
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final limit = provider.isPro ? 30 : provider.quotaRemaining;

    return Container(
      decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      padding: EdgeInsets.only(left: 20, right: 20, top: 20, bottom: MediaQuery.of(context).viewInsets.bottom + 40),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('📝 新しい記録を追加', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textDark)),
            const SizedBox(height: 20),

            // 気分タグ
            const Text('気分タグ', style: TextStyle(fontSize: 12, color: AppColors.textLight)),
            const SizedBox(height: 8),
            SizedBox(
              height: 48,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: DiaryMood.values.map((m) => GestureDetector(
                  onTap: () => setState(() => _mood = m),
                  child: Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _mood == m ? AppColors.caramelPale : Colors.transparent,
                      border: Border.all(color: _mood == m ? AppColors.caramel : Colors.transparent, width: 1.5),
                    ),
                    child: Text(m.emoji, style: const TextStyle(fontSize: 28)),
                  ),
                )).toList(),
              ),
            ),

            const SizedBox(height: 16),
            const Text('本文', style: TextStyle(fontSize: 12, color: AppColors.textLight)),
            const SizedBox(height: 6),
            TextField(
              controller: _bodyCtrl,
              maxLines: 4,
              decoration: const InputDecoration(hintText: '今日の様子を書いてみよう…'),
            ),

            const SizedBox(height: 16),
            Text('写真・動画（残り ${limit - _photos.length} 枚）', style: const TextStyle(fontSize: 12, color: AppColors.textLight)),
            const SizedBox(height: 6),
            if (_photos.isNotEmpty) ...[
              SizedBox(
                height: 80,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: _photos.map((p) => Container(
                    width: 80, height: 80, margin: const EdgeInsets.only(right: 8),
                    child: ClipRRect(borderRadius: BorderRadius.circular(10), child: Image.asset(p, fit: BoxFit.cover, errorBuilder: (_, __, ___) => Container(color: AppColors.caramelPale, child: const Icon(Icons.image)))),
                  )).toList(),
                ),
              ),
              const SizedBox(height: 8),
            ],
            if (_photos.length < limit)
              OutlinedButton.icon(
                onPressed: _pickPhoto,
                icon: const Icon(Icons.photo_library, color: AppColors.caramelLight),
                label: const Text('📷 ギャラリーから選択', style: TextStyle(color: AppColors.caramelLight, fontWeight: FontWeight.bold)),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 52),
                  side: const BorderSide(color: AppColors.caramelLight, width: 2),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),

            const SizedBox(height: 20),
            PetoButton(
              label: '✓ 保存する',
              onPressed: () async {
                await provider.addDiaryEntry(mood: _mood, body: _bodyCtrl.text, photoUris: _photos);
                if (mounted) Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }
}
