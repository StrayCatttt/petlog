import 'dart:async';
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

// ─── リワード広告 ─────────────────────────────────────
// ✅ Completerで「広告終了まで待機」してから結果を返す
// ✅ onUserEarnedReward が呼ばれた場合のみ true（視聴完了）

class RewardAdManager {
  RewardedAd? _ad;
  bool _loading = false;

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

  /// 広告を表示し、視聴完了なら true を返す。
  /// 途中で閉じた・アプリ切り替えなど → false を返す。
  Future<bool> show(BuildContext context) async {
    if (_ad == null) {
      loadAd();
      return false; // 広告未準備は付与しない
    }

    // ✅ Completerで終了を待つ
    final completer = Completer<bool>();
    bool _rewarded = false;

    _ad!.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        _ad = null;
        loadAd(); // 次回用に先読み
        // ✅ 広告が閉じられた時点で結果を確定（視聴完了していれば true）
        if (!completer.isCompleted) completer.complete(_rewarded);
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        ad.dispose();
        _ad = null;
        if (!completer.isCompleted) completer.complete(false);
      },
    );

    await _ad!.show(
      onUserEarnedReward: (ad, reward) {
        // ✅ 視聴完了コールバック：ここだけでフラグON
        _rewarded = true;
      },
    );

    // 広告が閉じられるまで待機
    return completer.future;
  }
}

final rewardAdManager = RewardAdManager();
