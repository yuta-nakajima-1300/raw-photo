# 📱 Android実機テスト設定ガイド

## 🚀 Android実機でのテスト手順

### 1. Android端末の準備

#### 開発者オプションを有効化
1. **設定** > **端末情報** を開く
2. **ビルド番号**を7回連続タップ
3. "開発者になりました" メッセージが表示される

#### USBデバッグを有効化
1. **設定** > **開発者向けオプション** を開く
2. **USBデバッグ**をONにする
3. **USBデバッグ (セキュリティ設定)**もONにする（推奨）

### 2. PC側の準備

#### ADBドライバーのインストール
```bash
# Android SDKが正しくインストールされているか確認
flutter doctor

# ADBが使用可能か確認
adb version
```

#### USB接続の確認
```bash
# 端末をUSBで接続後、認識されているか確認
adb devices
```

**期待される出力例:**
```
List of devices attached
ABC123DEF456    device
```

### 3. Flutterアプリの実機実行

#### 方法1: VSCodeから実行
1. Android端末をUSBで接続
2. VSCodeでプロジェクトを開く
3. `F5`キーまたは「実行 > デバッグの開始」
4. デバイス選択で実機を選択

#### 方法2: コマンドラインから実行
```bash
cd raw_photo_editor

# 接続デバイス確認
flutter devices

# 実機で実行（デバッグモード）
flutter run

# 実機で実行（リリースモード・高速）
flutter run --release

# 特定デバイスを指定して実行
flutter run -d <device_id>
```

### 4. 実機テスト時の注意事項

#### 権限設定
アプリが以下の権限を要求します：
- **ストレージアクセス権限** - RAW画像ファイル読み込み用
- **カメラ権限** - 将来のカメラ連携用

初回起動時に権限を許可してください。

#### パフォーマンス
- **デバッグモード**: 開発・デバッグ用（動作が重い）
- **リリースモード**: 本番相当（高速動作）

実際のパフォーマンステストは`--release`モードで行ってください。

#### ストレージアクセス
Android 11+では、RAW画像ファイルへのアクセスが制限される場合があります：
- 端末の**ファイル**アプリでRAW画像の場所を確認
- アプリに**すべてのファイルへのアクセス**権限を付与（必要に応じて）

### 5. テスト用RAW画像の準備

#### サンプルRAW画像の取得
1. **カメラで撮影** - 実機のカメラでRAW形式で撮影
2. **PC転送** - PCからUSB経由で転送
3. **ダウンロード** - 無料RAWサンプルをダウンロード

#### 対応フォーマット
- Canon: `.cr2`
- Nikon: `.nef`
- Sony: `.arw`
- Adobe: `.dng`
- Fujifilm: `.raf`
- その他多数

### 6. 実機テスト項目

#### 基本機能
- ✅ アプリ起動・終了
- ✅ 画面遷移（ホーム・ギャラリー・設定）
- ✅ ダークモード切り替え
- ✅ 設定変更・保存

#### ファイル機能（現在は模擬データ）
- ✅ 画像一覧表示
- ✅ 検索・フィルター
- ✅ ソート機能

#### 編集機能（現在はUI確認）
- ✅ 編集画面表示
- ✅ スライダー操作
- ✅ パラメータ調整UI

### 7. トラブルシューティング

#### デバイスが認識されない
```bash
# ADBサーバーを再起動
adb kill-server
adb start-server
adb devices
```

#### ビルドエラーが発生する
```bash
# プロジェクトをクリーン
flutter clean
flutter pub get

# Gradleキャッシュクリア（Android）
cd android
./gradlew clean
cd ..

# 再実行
flutter run
```

#### アプリがクラッシュする
```bash
# ログを確認
flutter logs

# またはadbでログ確認
adb logcat
```

### 8. パフォーマンス測定

#### フレームレート測定
```bash
# パフォーマンスプロファイル付きで実行
flutter run --profile

# DevToolsでパフォーマンス分析
flutter pub global run devtools
```

#### メモリ使用量確認
```bash
# メモリ使用量チェック
adb shell dumpsys meminfo com.raweditor.raw_photo_editor
```

### 9. リリースビルドテスト

#### APK作成
```bash
# リリース用APKビルド
flutter build apk --release

# APKインストール
adb install build/app/outputs/flutter-apk/app-release.apk
```

#### Bundle作成（Google Play用）
```bash
# リリース用Bundle作成
flutter build appbundle --release
```

---

## 🎯 実機テストの目的

1. **UI/UX確認** - 実際の画面サイズでの表示確認
2. **パフォーマンス測定** - 実機での動作速度
3. **権限動作** - ストレージアクセス等の確認
4. **バッテリー影響** - 電力消費の確認
5. **メモリ使用量** - 実際のメモリ消費

現在はプロトタイプ版のため、主にUI/UXの確認が中心になります。