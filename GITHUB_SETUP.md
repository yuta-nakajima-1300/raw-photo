# GitHub リポジトリ設定手順

## 1. GitHubでリポジトリ作成

1. [GitHub.com](https://github.com) にアクセス
2. 右上の「+」→「New repository」をクリック
3. リポジトリ設定：
   - **Repository name**: `flutter-raw-photo-editor`
   - **Description**: `Professional RAW photo editing app built with Flutter and C++`
   - **Visibility**: Public または Private
   - **Initialize**: チェックボックスは全て**空のまま**（既存プロジェクトのため）

## 2. リモートリポジトリを追加

```bash
cd flutter_raw_editor/raw_photo_editor

# GitHubリポジトリをリモートに追加（URLは作成したリポジトリのもの）
git remote add origin https://github.com/YOUR_USERNAME/flutter-raw-photo-editor.git

# ブランチ名をmainに変更（Gitデフォルト）
git branch -M main

# 初回プッシュ
git push -u origin main
```

## 3. 認証設定

### Personal Access Token使用の場合:
```bash
# GitHubの設定 > Developer settings > Personal access tokens で作成
git remote set-url origin https://YOUR_TOKEN@github.com/YOUR_USERNAME/flutter-raw-photo-editor.git
```

### SSH使用の場合:
```bash
# SSH鍵が設定済みの場合
git remote set-url origin git@github.com:YOUR_USERNAME/flutter-raw-photo-editor.git
```

## 4. プッシュ完了確認

```bash
git status
git log --oneline
```

## 5. GitHub Actions自動設定（オプション）

リポジトリに以下を追加できます：

### `.github/workflows/flutter.yml`
```yaml
name: Flutter CI

on:
  push:
    branches: [ main ]
  pull_request:
    branches: [ main ]

jobs:
  build:
    runs-on: ubuntu-latest
    
    steps:
    - uses: actions/checkout@v3
    
    - name: Setup Flutter
      uses: subosito/flutter-action@v2
      with:
        flutter-version: '3.16.0'
    
    - name: Install dependencies
      run: flutter pub get
    
    - name: Run tests
      run: flutter test
    
    - name: Build APK
      run: flutter build apk
```

## 6. リポジトリ説明の更新

GitHubリポジトリページで「About」セクションを編集：

- **Description**: Professional RAW photo editing app built with Flutter and C++
- **Website**: （デモサイトがあれば）
- **Topics**: flutter, dart, raw-photo-editing, libraw, opencv, mobile-app, android, ios

## 📱 リポジトリの内容

- ✅ 完全なFlutterアプリコード
- ✅ C++ネイティブエンジン
- ✅ SQLiteデータベース設計
- ✅ Material Design 3 UI
- ✅ VSCode開発環境設定
- ✅ 詳細なREADME

## 🚀 次のステップ

1. GitHub Issues でタスク管理
2. GitHub Projects でプロジェクト管理
3. Pull Request でコード レビュー
4. GitHub Pages でドキュメント公開

---

**注意**: このプロジェクトはプロトタイプです。実際のRAW現像にはネイティブライブラリの追加設定が必要です。