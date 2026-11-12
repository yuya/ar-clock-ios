# AR Clock for iOS

Web アプリ [yuya/ar-clock](https://github.com/yuya/ar-clock) を「元のコード」として扱い、取り込み → iOS アプリのビルドまでを一続きで行うためのリポジトリです。

## しくみ

```
ar-clock（Web・元のコード）
   │  scripts/sync-web.sh が指定した版を Web/ に取り込む
   ▼
ar-clock-ios
   ├─ Web/        取り込んだ Web 一式（コミットしない）
   ├─ App/        ネイティブの殻（Swift）
   ├─ project.yml Xcode プロジェクトの定義（XcodeGen で毎回生成）
   └─ .github/workflows/build.yml  取り込み → 生成 → ビルド
```

- **App/WebScreen.swift** … WKWebView を全画面で出す。カメラの許可は iOS の確認1回に任せる
- **App/AppSchemeHandler.swift** … 同梱した Web を `arclock://app/…` として配る（動画の途中読みに対応）
- **App/LocationBridge.swift** … Web 側の現在地取得を、アプリの位置情報に差し替える
- **App/ARClockApp.swift** … 消音スイッチでも鳴るようにし、画面を消さない

## ビルド

GitHub Actions（`Build`）が次のときに走り、シミュレータ用のアプリ（`ARClock-simulator.zip`）を成果物として残します。

- このリポジトリの `main` に push したとき
- 手動実行（取り込む ar-clock の版を指定できる）
- 1日1回（最新の Web で作り直す）
- ar-clock 側からの合図（`repository_dispatch` の `web-updated`。下記）

手元の Mac でビルドする場合：

```sh
brew install xcodegen
scripts/sync-web.sh        # Web を取り込む
xcodegen generate          # ARClock.xcodeproj を作る
open ARClock.xcodeproj
```

### ar-clock の更新と同時にビルドしたいとき（任意）

ar-clock 側に、push のたびにこのリポジトリへ合図を送るワークフローを置きます。別リポジトリを動かすには個人アクセストークンが必要なので、未設定です。設定しなくても1日1回は最新で作り直されます。

## 段階

1. **殻＋許可まわり＋自動ビルド**（いまここ）
2. **設定画面をネイティブに** … Web 側に「設定の読み書き」の窓口を作り、アプリ側の画面から操作する。アプリ内では Web の設定パネルを隠す
3. **描画と音の置き換え** … WebGL のシェーダ → Metal、Web Audio の音 → AVAudioEngine。Web と同じ見た目・音になるかを比べながら、部品ごとに差し替える

## まだやっていないこと

- 実機・TestFlight 向けのビルド（Apple Developer Program の登録と、署名用の証明書を GitHub のシークレットに登録する必要があります）
- アプリのアイコン
- 実機での動作確認
