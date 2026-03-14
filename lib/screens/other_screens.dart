import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import '../repositories/app_provider.dart';
import '../models/models.dart';
import '../theme/app_theme.dart';
import '../widgets/common_widgets.dart';

// ─── アルバム（album_screen.dartに移動済み） ────────────

// ─── 設定画面 ─────────────────────────────────────────

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
              onTap: () => _pickAndCropIcon(context, provider, pet),
              child: Stack(children: [
                Container(
                  width: 64, height: 64,
                  decoration: BoxDecoration(shape: BoxShape.circle, color: AppColors.caramelPale, border: Border.all(color: AppColors.goldRing, width: 3)),
                  child: ClipOval(child: pet.profilePhotoPath != null
                      ? Image.file(File(pet.profilePhotoPath!), fit: BoxFit.cover, errorBuilder: (_, __, ___) => Center(child: Text(pet.species.emoji, style: const TextStyle(fontSize: 32))))
                      : Center(child: Text(pet.species.emoji, style: const TextStyle(fontSize: 32)))),
                ),
                Positioned(right: 0, bottom: 0, child: Container(
                  width: 22, height: 22,
                  decoration: BoxDecoration(color: AppColors.caramel, shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 2)),
                  child: const Icon(Icons.camera_alt, color: Colors.white, size: 12),
                )),
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
                child: Text('🎂 お迎えから${pet.daysFromWelcome}日目', style: const TextStyle(fontSize: 11, color: AppColors.caramel, fontWeight: FontWeight.w600)),
              ),
            ])),
          ])),

          const SizedBox(height: 12),

          // Proバナー
          if (!provider.isPro) ...[
            _ProBanner(onUpgrade: () => _showProTrialDialog(context, provider)),
            const SizedBox(height: 16),
          ] else ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: AppColors.sagePale, borderRadius: BorderRadius.circular(16)),
              child: Row(children: [
                const Text('✨', style: TextStyle(fontSize: 24)),
                const SizedBox(width: 12),
                const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('ぺとろぐ PRO 有効中', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textDark)),
                  Text('全機能をお楽しみください', style: TextStyle(fontSize: 12, color: AppColors.textMid)),
                ])),
                TextButton(onPressed: () => provider.setIsPro(false), child: const Text('解除', style: TextStyle(color: AppColors.textLight, fontSize: 12))),
              ]),
            ),
            const SizedBox(height: 16),
          ],

          // ペット管理
          _SettingsGroup(title: 'ペット管理', children: [
            SettingsRow(icon: '🖼️', title: '${pet?.name ?? 'ペット'}のアイコンを変更', subtitle: 'タップして写真を選択・トリミング', onTap: pet != null ? () => _pickAndCropIcon(context, provider, pet) : null),
            const Divider(height: 1, indent: 52),
            SettingsRow(icon: '✏️', title: '${pet?.name ?? 'ペット'}のプロフィール編集'),
            const Divider(height: 1, indent: 52),
            SettingsRow(icon: '🐾', title: 'ペットを追加', subtitle: '現在${provider.pets.length}匹 / フリーは1匹まで', showProBadge: !provider.isPro, onTap: provider.isPro ? () {} : null),
          ]),

          const SizedBox(height: 12),

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

  Future<void> _pickAndCropIcon(BuildContext context, AppProvider provider, Pet pet) async {
    final picker = ImagePicker();
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (ctx) => SafeArea(child: Column(mainAxisSize: MainAxisSize.min, children: [
        ListTile(leading: const Icon(Icons.photo_library, color: AppColors.caramel), title: const Text('ギャラリーから選ぶ'), onTap: () => Navigator.pop(ctx, ImageSource.gallery)),
        ListTile(leading: const Icon(Icons.camera_alt, color: AppColors.caramel), title: const Text('カメラで撮影'), onTap: () => Navigator.pop(ctx, ImageSource.camera)),
      ])),
    );
    if (source == null) return;

    final picked = await picker.pickImage(source: source);
    if (picked == null) return;

    final cropped = await ImageCropper().cropImage(
      sourcePath: picked.path,
      aspectRatio: const CropAspectRatio(ratioX: 1, ratioY: 1),
      uiSettings: [
        AndroidUiSettings(
          toolbarTitle: 'アイコンをトリミング',
          toolbarColor: AppColors.caramel,
          toolbarWidgetColor: Colors.white,
          lockAspectRatio: true,
        ),
      ],
    );
    if (cropped == null) return;
    await provider.updatePet(pet.copyWith(profilePhotoPath: cropped.path));
  }

  void _showProTrialDialog(BuildContext context, AppProvider provider) {
    showDialog(context: context, builder: (ctx) => AlertDialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Column(children: [
        Text('✨', style: TextStyle(fontSize: 48)),
        SizedBox(height: 8),
        Text('ぺとろぐ PRO', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textDark)),
      ]),
      content: const Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('PRO機能：', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textDark)),
        SizedBox(height: 8),
        Text('✓ 広告なし\n✓ 写真1日30枚まで\n✓ ペット無制限\n✓ ホーム画面ウィジェット', style: TextStyle(color: AppColors.textMid, height: 1.8)),
        SizedBox(height: 12),
        Text('¥380/月（初月無料）', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.caramel, fontSize: 16)),
        SizedBox(height: 4),
        Text('※これは試用版です。実際の課金は発生しません。', style: TextStyle(fontSize: 10, color: AppColors.textLight)),
      ]),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('キャンセル', style: TextStyle(color: AppColors.textMid))),
        ElevatedButton(
          onPressed: () {
            Navigator.pop(ctx);
            provider.setIsPro(true);
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('✨ PRO機能が有効になりました！'), backgroundColor: AppColors.caramel));
          },
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.gold, foregroundColor: AppColors.textDark),
          child: const Text('試用する（無料）', style: TextStyle(fontWeight: FontWeight.bold)),
        ),
      ],
    ));
  }
}

class _SettingsGroup extends StatelessWidget {
  final String title;
  final List<Widget> children;
  const _SettingsGroup({required this.title, required this.children});
  @override
  Widget build(BuildContext context) {
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
  @override
  Widget build(BuildContext context) {
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
          ElevatedButton(
            onPressed: onUpgrade,
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.gold, foregroundColor: const Color(0xFF3D2E1E), padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8)),
            child: const Text('✨ 試してみる', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ])),
        const Text('🐾', style: TextStyle(fontSize: 60, color: Colors.white12)),
      ]),
    );
  }
}
