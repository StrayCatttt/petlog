import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../repositories/app_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/common_widgets.dart';

// ─── アルバム画面 ─────────────────────────────────────

class AlbumScreen extends StatelessWidget {
  const AlbumScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            title: const Text('📷 フォトアルバム', style: TextStyle(fontWeight: FontWeight.bold)),
            backgroundColor: const Color(0xFFFBF0DE),
            floating: true,
          ),
          const SliverFillRemaining(
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('📷', style: TextStyle(fontSize: 56)),
                  SizedBox(height: 12),
                  Text('写真・動画へのアクセスを\n許可するとここに表示されます', textAlign: TextAlign.center, style: TextStyle(color: AppColors.textLight)),
                  SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── 設定画面 ─────────────────────────────────────────

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final pet = provider.activePet;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            title: const Text('⚙️ 設定', style: TextStyle(fontWeight: FontWeight.bold)),
            backgroundColor: const Color(0xFFFBF0DE),
            floating: true,
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // ペットプロフィールカード
                  if (pet != null)
                    PetoCard(
                      child: Row(
                        children: [
                          GestureDetector(
                            onTap: () => _showIconPicker(context, provider),
                            child: Container(
                              width: 64, height: 64,
                              decoration: BoxDecoration(shape: BoxShape.circle, color: AppColors.caramelPale, border: Border.all(color: AppColors.goldRing, width: 3)),
                              child: ClipOval(child: Center(child: Text(pet.species.emoji, style: const TextStyle(fontSize: 32)))),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(pet.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textDark)),
                                Text('${pet.species.emoji} ${pet.species.label}・${pet.gender.label}', style: const TextStyle(fontSize: 12, color: AppColors.textLight)),
                                const SizedBox(height: 5),
                                if (pet.welcomeDate != null)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                                    decoration: BoxDecoration(color: AppColors.caramelPale, borderRadius: BorderRadius.circular(10)),
                                    child: Text('🎂 お迎えから${pet.daysFromWelcome}日目', style: const TextStyle(fontSize: 11, color: AppColors.caramel, fontWeight: FontWeight.w600)),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                  const SizedBox(height: 12),

                  // Proバナー（フリープランのみ）
                  if (!provider.isPro) ...[
                    _ProBanner(),
                    const SizedBox(height: 16),
                  ],

                  // ペット管理
                  _SettingsGroup(
                    title: 'ペット管理',
                    children: [
                      SettingsRow(icon: '🖼️', title: '${pet?.name ?? 'ペット'}のアイコンを変更', subtitle: '絵文字または写真から選択', onTap: () => _showIconPicker(context, provider)),
                      const Divider(height: 1, indent: 52),
                      SettingsRow(icon: '✏️', title: '${pet?.name ?? 'ペット'}のプロフィール編集'),
                      const Divider(height: 1, indent: 52),
                      SettingsRow(icon: '🐾', title: 'ペットを追加', subtitle: '現在${provider.pets.length}匹 / フリーは1匹まで', showProBadge: !provider.isPro),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // アプリ設定
                  _SettingsGroup(
                    title: 'アプリ設定',
                    children: [
                      SettingsRow(icon: '🔔', title: '通知設定', trailingText: 'ON'),
                      const Divider(height: 1, indent: 52),
                      const SettingsRow(icon: '📋', title: 'アプリ情報', trailingText: 'v1.0.0'),
                      const Divider(height: 1, indent: 52),
                      const SettingsRow(icon: '✉️', title: 'お問い合わせ'),
                    ],
                  ),

                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showIconPicker(BuildContext context, AppProvider provider) {
    final pet = provider.activePet;
    if (pet == null) return;
    final emojis = ['🐶', '🐱', '🐰', '🐦', '🦎', '🐟', '🐹', '🐾', '🦴', '🐩', '😺', '🐈', '🦜', '🐠', '🦋'];
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('🖼️ アイコンを選ぶ', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textDark)),
        content: SingleChildScrollView(
          child: Wrap(
            spacing: 8, runSpacing: 8,
            children: emojis.map((e) => GestureDetector(
              onTap: () {
                provider.updatePet(pet.copyWith(clearPhoto: true));
                Navigator.pop(ctx);
              },
              child: Container(
                width: 52, height: 52,
                decoration: BoxDecoration(shape: BoxShape.circle, color: const Color(0xFFF5F0E8)),
                child: Center(child: Text(e, style: const TextStyle(fontSize: 28))),
              ),
            )).toList(),
          ),
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('キャンセル', style: TextStyle(color: AppColors.textMid)))],
      ),
    );
  }
}

// ─── 設定グループ ─────────────────────────────────────

class _SettingsGroup extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _SettingsGroup({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(title.toUpperCase(), style: const TextStyle(fontSize: 10, color: AppColors.textLight, letterSpacing: 1)),
        ),
        Material(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          child: Column(children: children),
        ),
      ],
    );
  }
}

// ─── Pro バナー ───────────────────────────────────────

class _ProBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(color: const Color(0xFF3D2E1E), borderRadius: BorderRadius.circular(20)),
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('ぺとろぐ PRO', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.goldRing, letterSpacing: 2)),
                const SizedBox(height: 5),
                const Text('広告なし・ウィジェット\n写真1日30枚まで', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                const SizedBox(height: 4),
                const Text('¥380/月（初月無料）', style: TextStyle(fontSize: 12, color: Colors.white70)),
                const SizedBox(height: 14),
                ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.gold, foregroundColor: const Color(0xFF3D2E1E), padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8)),
                  child: const Text('✨ アップグレード', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
          const Text('🐾', style: TextStyle(fontSize: 60, color: Colors.white12)),
        ],
      ),
    );
  }
}
