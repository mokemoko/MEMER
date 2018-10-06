## Setup

### 依存ライブラリ導入
```bash
cd ${PROJECT_ROOT}
bundle install
bundle exec pod install
```

### Firebase設定追加
1. https://firebase.google.com/docs/ios/setup を参考に `GoogleService-Info.plist` を取得
2. 1のファイルを `SelfOpenData/GoogleService-Info.plist` として配置

### JINS MEME SDK追加
1. [公式](https://github.com/jins-meme/JinsMemeSDK-Sample-iOS)を参考にSDKをダウンロードし、 `SDK` ディレクトリ配下に配置
2. `SelfOpenData/MEME-Info.plist.sample` の項目を書き換え、 `MEME-Info.plist` にリネーム
