import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'ad_config.dart';

// ─── バナー広告 ───────────────────────────────────────

class BannerAdWidget extends StatefulWidget {
  const BannerAdWidget({super.key});
  @override State<BannerAdWidget> createState() => _BannerAdWidgetState();
}
class _BannerAdWidgetState extends State<BannerAdWidget> {
  BannerAd? _ad;
  bool _loaded = false;
  @override void initState() { super.initState(); _load(); }
  void _load() {
    BannerAd(adUnitId: AdConfig.banner, request: const AdRequest(), size: AdSize.banner,
      listener: BannerAdListener(
        onAdLoaded: (ad) { if (mounted) setState(() { _ad = ad as BannerAd; _loaded = true; }); },
        onAdFailedToLoad: (ad, _) => ad.dispose(),
      ))..load();
  }
  @override void dispose() { _ad?.dispose(); super.dispose(); }
  @override Widget build(BuildContext context) {
    if (!_loaded || _ad == null) return const SizedBox(height: 50);
    return SizedBox(width: _ad!.size.width.toDouble(), height: _ad!.size.height.toDouble(), child: AdWidget(ad: _ad!));
  }
}

// ─── リワード広告（視聴完了のみ付与） ────────────────

class RewardAdManager {
  RewardedAd? _ad;
  bool _loading = false;
  // ✅ 視聴中フラグ（アプリを閉じて戻っても報酬付与しない）
  bool _earnedDuringSession = false;

  void loadAd() {
    if (_loading || _ad != null) return;
    _loading = true;
    RewardedAd.load(
      adUnitId: AdConfig.reward,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) { _ad = ad; _loading = false; },
        onAdFailedToLoad: (_) { _loading = false; },
      ),
    );
  }

  /// 広告を表示。
  /// ✅ onUserEarnedReward が呼ばれた場合のみ true を返す。
  /// アプリ再起動・途中離脱では false を返す。
  Future<bool> show(BuildContext context) async {
    _earnedDuringSession = false;

    if (_ad == null) {
      // 広告未ロード時はフォールバック（開発用）
      loadAd();
      // 本番では false を返してフォールバックしない
      return false;
    }

    bool earned = false;
    final completer = Future<bool>.value(false); // unused but typed

    _ad!.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose(); _ad = null; loadAd();
        // ✅ dismiss時点でearnedがtrueでなければ付与しない
      },
      onAdFailedToShowFullScreenContent: (ad, _) {
        ad.dispose(); _ad = null;
      },
    );

    await _ad!.show(
      onUserEarnedReward: (ad, reward) {
        // ✅ 視聴完了コールバックのみでフラグON
        earned = true;
        _earnedDuringSession = true;
      },
    );

    return earned;
  }
}

// グローバルシングルトン
final rewardAdManager = RewardAdManager();
