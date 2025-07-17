# RAW Photo Editor

プロフェッショナルRAW現像アプリ（Flutter + C++ LibRaw）

## 🚀 VSCodeでのエミュレーター実行方法

### 1. 前提条件
- Flutter SDK (3.16+)
- Android Studio & Android SDK
- VSCode + Flutter拡張機能
- Android エミュレーターまたは実機

### 2. 依存関係のインストール
```bash
cd raw_photo_editor
flutter pub get
```

### 3. エミュレーター起動
```bash
# 利用可能なエミュレーターを確認
flutter emulators

# エミュレーターを起動
flutter emulators --launch <emulator_id>

# または Android Studio から起動
```

### 4. VSCodeでの実行

#### 方法1: F5キーでデバッグ実行
1. VSCodeでプロジェクトを開く
2. `lib/main.dart` を開く
3. F5キーを押すか、メニューから「実行 > デバッグの開始」
4. デバイスを選択（エミュレーターまたは実機）

#### 方法2: コマンドパレットから実行
1. `Ctrl+Shift+P` (Windows/Linux) または `Cmd+Shift+P` (Mac)
2. 「Flutter: Launch Emulator」を選択
3. エミュレーターを選択
4. 「Flutter: Run Flutter App」を実行

#### 方法3: ターミナルから実行
```bash
# デバッグモードで実行
flutter run

# リリースモードで実行
flutter run --release

# プロファイルモードで実行
flutter run --profile
```

### 5. ホットリロード
- `r` キー: ホットリロード
- `R` キー: ホットリスタート
- `q` キー: 終了

## 📱 アプリ機能

### 現在実装済み
- ✅ RAW画像一覧表示
- ✅ 画像検索・ソート・フィルター
- ✅ 基本的な現像UI（露出、コントラスト等）
- ✅ ダークモード対応
- ✅ SQLiteデータベース
- ✅ C++ネイティブ処理エンジン（アーキテクチャのみ）

### 今後実装予定
- ⏳ 実際のRAW現像処理
- ⏳ HSL調整
- ⏳ トーンカーブ
- ⏳ プリセット管理
- ⏳ エクスポート機能

## 🏗️ アーキテクチャ

```
┌─────────────────────────────────────────┐
│           Flutter UI Layer              │ ← Material Design 3
├─────────────────────────────────────────┤
│        Dart Business Logic Layer        │ ← Provider状態管理
├─────────────────────────────────────────┤
│         Native Processing Layer         │ ← C++ LibRaw + OpenCV
├─────────────────────────────────────────┤
│            Data Storage Layer           │ ← SQLite
└─────────────────────────────────────────┘
```

## 🔧 開発時のポイント

### ネイティブライブラリについて
現在のバージョンではC++ネイティブライブラリ（LibRaw, OpenCV）は**アーキテクチャのみ**実装されています。実際にRAW画像を処理するには：

1. LibRaw/OpenCVライブラリを`android/app/libs/`に配置
2. CMakeLists.txtのパス調整
3. ビルド設定の調整

### エミュレーターでの制限
- RAW画像ファイルへのアクセスは制限される場合があります
- 実機での実行を推奨

### VSCodeデバッグ設定
- `.vscode/launch.json`: デバッグ構成
- `.vscode/settings.json`: エディター設定
- `.vscode/tasks.json`: ビルドタスク

## 🐛 トラブルシューティング

### ビルドエラーが発生する場合
```bash
flutter clean
flutter pub get
flutter run
```

### パッケージエラーの場合
```bash
flutter doctor
flutter doctor --android-licenses
```

### エミュレーターが表示されない場合
```bash
flutter devices
flutter emulators
```

## 📄 ライセンス

このプロジェクトはMITライセンスです。

## 🤝 開発者向け

- コード整形: `flutter format lib/`
- 静的解析: `flutter analyze`
- テスト実行: `flutter test`

---

**注意**: このアプリはプロトタイプ版です。実際のRAW現像機能を使用するには、ネイティブライブラリの追加設定が必要です。