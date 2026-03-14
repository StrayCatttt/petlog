# ペットログ Flutter — ビルド手順

## 必要なもの
- Windows / Mac / Linux PC
- 約 3GB の空き容量

---

## 1. Flutter をインストール

### Windows の場合
1. https://flutter.dev/docs/get-started/install/windows を開く
2. 「Download Flutter SDK」ボタンをクリックしてZIPをダウンロード
3. `C:\flutter` に解凍
4. 「システム環境変数」→「PATH」に `C:\flutter\bin` を追加
5. コマンドプロンプトを**再起動**して確認：
   ```
   flutter --version
   ```

### Mac の場合
```bash
brew install --cask flutter
flutter --version
```

---

## 2. Android SDK のセットアップ

Flutterのインストール後：
```
flutter doctor
```
と打つと何が足りないか教えてくれます。Android SDKが必要な場合は Android Studio をインストールすると自動で入ります。

---

## 3. プロジェクトを展開してAPKをビルド

```bash
# ZIPを解凍してフォルダへ移動
cd C:\petlog_flutter      # Windowsの場合
# cd ~/petlog_flutter     # Macの場合

# パッケージをインストール（初回のみ・数分かかります）
flutter pub get

# APKをビルド
flutter build apk --release

# 完了！APKはここにあります：
# build/app/outputs/flutter-apk/app-release.apk
```

---

## 4. APKをスマホに転送してインストール

1. Androidスマホの「設定」→「セキュリティ」→「提供元不明のアプリ」をON
2. `app-release.apk` をスマホに転送（USBケーブル or メール or Google Drive）
3. スマホでAPKファイルをタップ → インストール

---

## トラブルシューティング

| エラー | 対処 |
|--------|------|
| `flutter: command not found` | PATHの設定を確認してターミナルを再起動 |
| `SDK not found` | `flutter doctor` の指示に従いSDKをインストール |
| `Gradle build failed` | `flutter clean` してから再度 `flutter build apk` |
| ビルドが重い | 初回は10〜20分かかります。Wi-Fi環境で実行推奨 |

---

## エミュレーターで確認する場合

```bash
# 接続済みデバイスを確認
flutter devices

# エミュレーターを起動
flutter emulators --launch <emulator_id>

# デバッグ実行
flutter run
```
