import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../utils/ad_helper.dart';

class PetoCard extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final EdgeInsetsGeometry padding;
  const PetoCard({super.key, required this.child, this.onTap, this.onLongPress, this.padding = const EdgeInsets.all(16)});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        borderRadius: BorderRadius.circular(16),
        child: Padding(padding: padding, child: child),
      ),
    );
  }
}

class SectionTitle extends StatelessWidget {
  final String title;
  final Widget? trailing;
  const SectionTitle({super.key, required this.title, this.trailing});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(children: [
        Expanded(child: Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textDark))),
        if (trailing != null) trailing!,
      ]),
    );
  }
}

class PetoButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final Color? color;
  const PetoButton({super.key, required this.label, this.onPressed, this.color});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity, height: 52,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: color ?? AppColors.caramel,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        child: Text(label, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
      ),
    );
  }
}

// バナー広告（実AdMob）
class BannerAdPlaceholder extends StatelessWidget {
  const BannerAdPlaceholder({super.key});
  @override
  Widget build(BuildContext context) => const BannerAdWidget();
}

class PhotoQuotaBar extends StatelessWidget {
  final int used;
  final int total;
  final bool rewardWatched;
  final VoidCallback onRewardTap;
  const PhotoQuotaBar({super.key, required this.used, required this.total, required this.rewardWatched, required this.onRewardTap});

  @override
  Widget build(BuildContext context) {
    return PetoCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('📷 今日の写真枠', style: TextStyle(fontSize: 12, color: AppColors.textMid)),
            Text('$used / ${total}枚', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.caramel)),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: total > 0 ? (used / total).clamp(0.0, 1.0) : 0,
            minHeight: 8,
            backgroundColor: AppColors.caramelPale,
            valueColor: const AlwaysStoppedAnimation(AppColors.caramel),
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          width: double.infinity,
          child: TextButton(
            onPressed: rewardWatched ? null : onRewardTap,
            style: TextButton.styleFrom(
              backgroundColor: rewardWatched ? Colors.grey.shade100 : AppColors.caramelPale,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: Text(
              rewardWatched ? '✓ 追加枠 +3枚 獲得済み' : '🎬 動画を見て +3枚もらう（最大4枚/日）',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: rewardWatched ? AppColors.textLight : AppColors.caramel),
            ),
          ),
        ),
      ]),
    );
  }
}

Future<bool> showRewardDialog(BuildContext context) async {
  return await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Column(children: [
        Text('🎬', style: TextStyle(fontSize: 48)),
        SizedBox(height: 8),
        Text('動画を見て枠を増やす？', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textDark)),
      ]),
      content: const Column(mainAxisSize: MainAxisSize.min, children: [
        Text('写真の追加枠を +3枚 もらえます', style: TextStyle(color: AppColors.textMid)),
        SizedBox(height: 4),
        Text('（1日1回のみ・今日は最大4枚まで）', style: TextStyle(fontSize: 11, color: AppColors.textLight)),
      ]),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('あとで', style: TextStyle(color: AppColors.textMid))),
        ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('見る（30秒）')),
      ],
    ),
  ) ?? false;
}

class SettingsRow extends StatelessWidget {
  final String icon;
  final String title;
  final String? subtitle;
  final String? trailingText;
  final bool showArrow;
  final bool showProBadge;
  final VoidCallback? onTap;
  final Widget? trailingWidget;
  const SettingsRow({super.key, required this.icon, required this.title, this.subtitle, this.trailingText, this.showArrow = true, this.showProBadge = false, this.onTap, this.trailingWidget});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      leading: Text(icon, style: const TextStyle(fontSize: 20)),
      title: Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textDark)),
      subtitle: subtitle != null ? Text(subtitle!, style: const TextStyle(fontSize: 11, color: AppColors.textLight)) : null,
      trailing: Row(mainAxisSize: MainAxisSize.min, children: [
        if (trailingText != null) Text(trailingText!, style: const TextStyle(color: AppColors.textLight, fontSize: 12)),
        if (trailingWidget != null) trailingWidget!,
        if (showProBadge) Container(
          margin: const EdgeInsets.only(left: 6),
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
          decoration: BoxDecoration(color: AppColors.gold, borderRadius: BorderRadius.circular(10)),
          child: const Text('PRO', style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold)),
        ),
        if (showArrow) const Icon(Icons.chevron_right, color: AppColors.textLight, size: 18),
      ]),
    );
  }
}
