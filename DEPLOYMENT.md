# デプロイメントガイド

このドキュメントでは、Drive Inspectionアプリのビルドとデプロイのプロセスについて詳しく説明します。

## 目次

- [前提条件](#前提条件)
- [Androidデプロイ](#androidデプロイ)
- [iOSデプロイ](#iosデプロイ)
- [トラブルシューティング](#トラブルシューティング)

## 前提条件

### 共通

- Flutter SDK (最新安定版)
- Git
- プロジェクトの依存関係がインストール済み:
  ```bash
  flutter pub get
  ```

### Android固有

- Android Studio または Android SDK CLI tools
- JDK 11以上
- Android SDK API Level 33以上
- 署名キー（リリースビルドの場合）

### iOS固有

- macOS
- Xcode 14以上
- CocoaPods
- Apple Developer アカウント（実機デプロイの場合）
- 有効な開発証明書とプロビジョニングプロファイル

## Androidデプロイ

### 開発環境での実行

#### 1. デバイスまたはエミュレータの準備

**実機の場合:**
1. USBデバッグを有効化
2. USBケーブルでPCに接続
3. 接続を確認:
   ```bash
   flutter devices
   ```

**エミュレータの場合:**
1. 利用可能なエミュレータを確認:
   ```bash
   flutter emulators
   ```

2. エミュレータを起動:
   ```bash
   flutter emulators --launch Pixel_7_API_32
   ```

#### 2. アプリの実行

デバッグモードで実行:
```bash
flutter run -d <device-id>
```

ホットリロード対応で開発がスムーズに進められます。

### リリースビルド

#### 1. 署名設定の準備

`android/key.properties` ファイルが存在し、正しく設定されていることを確認:

```properties
storePassword=your-keystore-password
keyPassword=your-key-password
keyAlias=your-key-alias
storeFile=/path/to/your-keystore.jks
```

**注意:** このファイルは `.gitignore` に含め、リポジトリにコミットしないでください。

#### 2. キーストアファイルの確認

`storeFile` パスに指定されたキーストアファイルが存在することを確認してください。

キーストアが存在しない場合は作成:
```bash
keytool -genkey -v -keystore ~/drive_inspection-upload-keystore.jks \
  -keyalg RSA -keysize 2048 -validity 10000 -alias upload
```

#### 3. APKのビルド

リリースAPKをビルド:
```bash
flutter build apk --release
```

ビルドが成功すると、APKファイルが生成されます:
- 場所: `build/app/outputs/flutter-apk/app-release.apk`
- サイズ: 約45MB

#### 4. デバイスへのインストール

接続されたデバイスにインストール:
```bash
flutter install -d <device-id>
```

または、APKファイルを直接配布することも可能です。

### App Bundleのビルド（Google Play用）

Google Play Storeへの公開には、APKではなくApp Bundleが推奨されます:

```bash
flutter build appbundle --release
```

生成されたファイル:
- 場所: `build/app/outputs/bundle/release/app-release.aab`

### ビルド設定のカスタマイズ

#### バージョン番号の変更

`pubspec.yaml` でバージョンを管理:
```yaml
version: 1.0.0+1  # バージョン名+ビルド番号
```

#### 異なるビルドフレーバー

開発環境と本番環境を分ける場合:
```bash
flutter build apk --release --flavor production -t lib/main_production.dart
```

## iOSデプロイ

### CocoaPodsのセットアップ

#### 初回セットアップ

```bash
cd ios
COCOAPODS_NO_BUNDLER=1 pod install
cd ..
```

**重要:** `COCOAPODS_NO_BUNDLER=1` 環境変数が必要です。これにより、Bundlerの問題を回避できます。

#### Podsの更新

依存関係を更新する場合:
```bash
cd ios
COCOAPODS_NO_BUNDLER=1 pod repo update
COCOAPODS_NO_BUNDLER=1 pod install
cd ..
```

### 開発環境での実行

#### 1. デバイスの準備

**実機の場合:**
1. iPhoneをMacに接続（USB or ワイヤレス）
2. デベロッパーモードを有効化
3. 信頼されたコンピュータとして承認
4. 接続を確認:
   ```bash
   flutter devices
   ```

**シミュレータの場合:**
1. 利用可能なシミュレータを確認:
   ```bash
   flutter emulators
   ```

2. シミュレータを起動:
   ```bash
   open -a Simulator
   ```

#### 2. アプリの実行

デバッグモードで実行:
```bash
flutter run -d <device-id>
```

### リリースビルド

#### 1. 開発チームの設定

Xcodeでプロジェクトを開く:
```bash
open ios/Runner.xcworkspace
```

Xcodeで:
1. Runnerプロジェクトを選択
2. "Signing & Capabilities" タブを開く
3. "Team" で開発チームを選択
4. Bundle Identifierが一意であることを確認

#### 2. iOSアプリのビルド

リリースビルド:
```bash
COCOAPODS_NO_BUNDLER=1 flutter build ios --release
```

ビルド成果物:
- 場所: `build/ios/iphoneos/Runner.app`
- サイズ: 約15MB

#### 3. 実機へのインストール方法

**方法A: Xcodeを使用（推奨）**

1. Xcodeでワークスペースを開く:
   ```bash
   open ios/Runner.xcworkspace
   ```

2. デバイスを選択

3. Product > Run (⌘R) でインストールと実行

**方法B: flutter run を使用**

```bash
COCOAPODS_NO_BUNDLER=1 flutter run -d <device-id> --release
```

#### 4. Archiveの作成（App Store配布用）

Xcodeで:
1. Generic iOS Device を選択
2. Product > Archive を実行
3. Organizer が開いたら:
   - App Store Connect にアップロード、または
   - Ad Hoc / Enterprise配布用にエクスポート

### App Store Connect へのアップロード

#### 前提条件

- Apple Developer Program への登録
- App Store Connect でアプリが作成済み
- 有効な配布証明書とプロビジョニングプロファイル

#### アップロード手順

1. Xcodeでアーカイブを作成（上記参照）

2. Organizer で "Distribute App" を選択

3. "App Store Connect" を選択

4. オプションを設定:
   - Include bitcode: No（Flutter はbitcodeをサポートしていません）
   - Upload symbols: Yes（推奨）

5. 署名を設定して "Upload"

6. App Store Connect でビルドが処理されるまで待機（通常5-15分）

7. TestFlight または本番リリースを設定

## 環境変数の設定

### プロジェクト固有の環境変数

デプロイ時に役立つ環境変数:

```bash
# CocoaPods でBundlerを使用しない
export COCOAPODS_NO_BUNDLER=1

# Flutter のビルド詳細を表示
export FLUTTER_BUILD_MODE=release
export VERBOSE=1
```

### シェル設定ファイルに追加

`~/.zshrc` または `~/.bash_profile` に追加:

```bash
# Flutter/iOS development
export COCOAPODS_NO_BUNDLER=1
```

変更を反映:
```bash
source ~/.zshrc
```

## 自動化スクリプト

### Androidビルド・デプロイスクリプト

`scripts/deploy_android.sh`:

```bash
#!/bin/bash
set -e

echo "🤖 Androidリリースビルドを開始します..."

# クリーンビルド
echo "📦 クリーニング中..."
flutter clean
flutter pub get

# APKビルド
echo "🔨 APKをビルド中..."
flutter build apk --release

# デバイス確認
echo "📱 接続されたデバイス:"
flutter devices

# インストール（デバイスIDを引数で受け取る）
if [ -n "$1" ]; then
    echo "📲 デバイス $1 にインストール中..."
    flutter install -d "$1"
    echo "✅ デプロイ完了！"
else
    echo "⚠️  デバイスIDを指定してください: ./deploy_android.sh <device-id>"
fi
```

### iOSビルド・デプロイスクリプト

`scripts/deploy_ios.sh`:

```bash
#!/bin/bash
set -e

echo "🍎 iOSリリースビルドを開始します..."

# CocoaPods環境変数を設定
export COCOAPODS_NO_BUNDLER=1

# クリーンビルド
echo "📦 クリーニング中..."
flutter clean
flutter pub get

# Podsを更新
echo "🔄 CocoaPodsを更新中..."
cd ios
pod install
cd ..

# iOSビルド
echo "🔨 iOSアプリをビルド中..."
flutter build ios --release

# Xcodeで開く
echo "🚀 Xcodeでワークスペースを開きます..."
open ios/Runner.xcworkspace

echo "✅ ビルド完了！Xcodeからデバイスにデプロイしてください。"
```

使用方法:

```bash
# スクリプトに実行権限を付与
chmod +x scripts/deploy_android.sh
chmod +x scripts/deploy_ios.sh

# 実行
./scripts/deploy_android.sh 5867064351
./scripts/deploy_ios.sh
```

## トラブルシューティング

### Android関連

#### 問題: "Gradle build failed"

**解決策:**
1. Android Studio が最新であることを確認
2. Gradle キャッシュをクリア:
   ```bash
   cd android
   ./gradlew clean
   cd ..
   flutter clean
   ```

#### 問題: "Keystore file not found"

**解決策:**
1. `android/key.properties` のパスが正しいか確認
2. キーストアファイルが存在するか確認
3. パスは絶対パスを使用することを推奨

#### 問題: "INSTALL_FAILED_UPDATE_INCOMPATIBLE"

**解決策:**
既存のアプリをアンインストールしてから再インストール:
```bash
adb uninstall com.example.drive_inspection
flutter install -d <device-id>
```

### iOS関連

#### 問題: "CocoaPods not installed or not in valid state"

**解決策:**
1. `COCOAPODS_NO_BUNDLER=1` 環境変数を使用:
   ```bash
   cd ios
   COCOAPODS_NO_BUNDLER=1 pod install
   cd ..
   ```

2. それでも解決しない場合、Podsをクリーン:
   ```bash
   rm -rf ios/Pods ios/Podfile.lock
   cd ios
   COCOAPODS_NO_BUNDLER=1 pod install
   cd ..
   ```

#### 問題: "Code signing error"

**解決策:**
1. Xcodeで開発チームが選択されているか確認
2. 証明書が有効か確認:
   - Xcode > Preferences > Accounts
   - Manage Certificates...

3. プロビジョニングプロファイルをリフレッシュ

#### 問題: "Module not found" エラー

**解決策:**
1. Podsを再インストール:
   ```bash
   cd ios
   rm -rf Pods Podfile.lock
   COCOAPODS_NO_BUNDLER=1 pod install
   cd ..
   ```

2. Xcodeでクリーンビルド:
   - Product > Clean Build Folder (⇧⌘K)

#### 問題: "Unable to boot simulator"

**解決策:**
1. シミュレータをリセット
2. Xcodeを再起動
3. 別のシミュレータデバイスを試す

### 共通の問題

#### 問題: ビルドが非常に遅い

**解決策:**
1. クリーンビルドを実行:
   ```bash
   flutter clean
   flutter pub get
   ```

2. キャッシュをクリア:
   ```bash
   flutter pub cache repair
   ```

3. 不要な依存関係を削除

#### 問題: センサーデータが取得できない

**解決策:**
1. 実機で実行していることを確認（エミュレータ/シミュレータはセンサーサポートが限定的）
2. 必要な権限が許可されているか確認
3. `AndroidManifest.xml` / `Info.plist` に必要な権限が記載されているか確認

## ベストプラクティス

### リリース前チェックリスト

- [ ] すべてのテストがパス
- [ ] Lintエラーがない
- [ ] バージョン番号を更新
- [ ] リリースノートを準備
- [ ] 署名キー/証明書が有効
- [ ] ターゲットプラットフォームでテスト実施
- [ ] パフォーマンステストを実行
- [ ] メモリリークをチェック

### セキュリティ

- 署名キーやパスワードをリポジトリにコミットしない
- `.gitignore` に以下を含める:
  ```
  android/key.properties
  *.jks
  *.keystore
  ```
- CI/CD環境では環境変数やシークレットマネージャーを使用

### バージョン管理

- セマンティックバージョニングを使用（Major.Minor.Patch）
- 各リリースにGit タグを付ける:
  ```bash
  git tag -a v1.0.0 -m "Release version 1.0.0"
  git push origin v1.0.0
  ```

## さらなる情報

- [Flutter Deployment Documentation](https://docs.flutter.dev/deployment)
- [Android App Signing](https://developer.android.com/studio/publish/app-signing)
- [iOS App Distribution](https://developer.apple.com/documentation/xcode/distributing-your-app-for-beta-testing-and-releases)
- [CocoaPods Guides](https://guides.cocoapods.org/)

