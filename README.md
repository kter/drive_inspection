# Drive Inspection

運転中の加速度データを記録・可視化するFlutterアプリケーションです。

## 機能

- リアルタイム加速度データの表示
- 運転セッションの記録と履歴管理
- 軌跡の可視化
- ダークモード対応
- センサーデータの永続化

## 必要な環境

- Flutter SDK (最新安定版)
- Android開発の場合:
  - Android Studio
  - Android SDK
  - JDK 11以上
- iOS開発の場合:
  - Xcode
  - CocoaPods
  - macOS

## セットアップ

### 1. 依存関係のインストール

```bash
flutter pub get
```

### 2. iOS用CocoaPodsのセットアップ

```bash
cd ios
COCOAPODS_NO_BUNDLER=1 pod install
cd ..
```

## ビルドとデプロイ

### Android

#### デバッグビルド

```bash
flutter run -d <device-id>
```

#### リリースビルド

1. APKファイルのビルド:

```bash
flutter build apk --release
```

ビルドされたAPKは `build/app/outputs/flutter-apk/app-release.apk` に生成されます。

2. 接続されたデバイスの確認:

```bash
flutter devices
```

3. デバイスへのインストール:

```bash
flutter install -d <device-id>
```

#### 署名設定

リリースビルドには署名が必要です。`android/key.properties` に以下の設定があることを確認してください:

```properties
storePassword=<your-keystore-password>
keyPassword=<your-key-password>
keyAlias=<your-key-alias>
storeFile=<path-to-keystore-file>
```

### iOS

#### 前提条件

- CocoaPodsが正しくインストールされている
- Xcodeで開発チームが設定されている
- iOS実機にデベロッパー証明書がインストールされている

#### デバッグビルド

```bash
flutter run -d <device-id>
```

#### リリースビルド

1. iOSアプリのビルド:

```bash
COCOAPODS_NO_BUNDLER=1 flutter build ios --release
```

ビルドされたアプリは `build/ios/iphoneos/Runner.app` に生成されます。

2. Xcodeでのデプロイ:

```bash
open ios/Runner.xcworkspace
```

Xcodeが開いたら:
- デバイスを選択
- Product > Archive を実行
- Organizer からデバイスにデプロイ

#### CocoaPods のトラブルシューティング

CocoaPodsでエラーが発生する場合:

```bash
# Podsディレクトリをクリーン
rm -rf ios/Pods ios/Podfile.lock

# 再インストール
cd ios
COCOAPODS_NO_BUNDLER=1 pod install
cd ..
```

## デバイスの確認

接続されているデバイスやエミュレータの一覧:

```bash
flutter devices
```

利用可能なエミュレータの一覧:

```bash
flutter emulators
```

エミュレータの起動:

```bash
flutter emulators --launch <emulator-id>
```

## 開発

### アーキテクチャ

```
lib/
├── main.dart                    # アプリのエントリーポイント
├── models/                      # データモデル
├── screens/                     # 画面UI
├── services/                    # ビジネスロジック
├── theme/                       # テーマ設定
└── widgets/                     # 再利用可能なウィジェット
```

### 主要なサービス

- `AccelerometerService`: 加速度センサーデータの取得
- `DatabaseService`: SQLiteデータベース管理
- `SessionManager`: 運転セッション管理
- `PermissionService`: 権限管理
- `ThemeService`: テーマ切り替え

## トラブルシューティング

### よくある問題

1. **CocoaPods のエラー (iOS)**
   - `COCOAPODS_NO_BUNDLER=1` 環境変数を使用してください
   - Podfileをクリーンして再インストールしてください

2. **センサーが利用できない**
   - 実機で実行していることを確認してください（エミュレータはセンサーが制限されています）
   - 必要な権限が許可されているか確認してください

3. **ビルドエラー**
   - `flutter clean` を実行してから再ビルドしてください
   - `flutter pub get` で依存関係を更新してください

## リソース

- [Flutter Documentation](https://docs.flutter.dev/)
- [Dart Documentation](https://dart.dev/guides)
- [sensors_plus Package](https://pub.dev/packages/sensors_plus)
