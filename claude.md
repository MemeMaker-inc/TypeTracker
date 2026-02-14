# TypeTracker — macOS メニューバーアプリ 実装計画書

> **作成日**: 2026-02-14  
> **対象**: macOS 13 Ventura 以上  
> **言語**: Swift 5.9 / SwiftUI  
> **調査ベース**: Apple Developer Forums / Apple公式ドキュメント / 実測データ

---

## 1. アプリ概要

### コンセプト
メニューバーに常駐し、「今日どれだけタイピングしたか」「カーソルをどれだけ動かしたか」をリアルタイムで可視化する。単なる数値ではなく、ハリーポッターやフルマラソンなど「わかりやすい比較対象」で達成率を表示することで、ゲーム感覚で毎日の入力量を楽しめるアプリ。

### ターゲットユーザー
- コーダー・ライター・デザイナーなど日常的にMacを使うプロ
- 自分の生産性を可視化したいユーザー
- ガジェット好き・データ好きなユーザー

---

## 2. 技術的実現可能性（調査結果）

### 2-1. キーストローク監視

**採用API**: `CGEventTap` (CoreGraphics) — `listenOnly` オプション  
**必要な権限**: **Input Monitoring** (`Privacy_ListenEvent`)  
**調査結果のポイント**:

| 方法 | 必要権限 | サンドボックス対応 | App Store配布 |
|------|---------|------------------|---------------|
| `NSEvent.addGlobalMonitorForEvents` | Accessibility | ❌ 非対応 | ❌ 不可 |
| `CGEventTap` (listenOnly) | **Input Monitoring** | ✅ **対応** | ✅ **可能** |

Apple Developer Technical Support（Quinn "The Eskimo!"）の公式回答により、**`CGEventTap` の `listenOnly` モードを使えばサンドボックス環境・Mac App Store配布が可能**であることが確認済み（2024年時点）。

```swift
// 権限チェックAPI（公式）
CGPreflightListenEventAccess()  // Bool を返す
CGRequestListenEventAccess()    // ダイアログ表示してリクエスト
```

**キーカウント方法**: `keyDown` イベント (`kCGEventKeyDown`) の発火回数を積算。**キーの内容（文字）は一切記録しない**。カウントのみ。

---

### 2-2. マウス/トラックパッド移動距離

**採用API**: `CGEventTap` — `.mouseMoved` イベント  
**同一タップで監視可能**（キーボードと兼用）

**物理距離への変換方法（ファクトベース）**:

```swift
// カーソルの絶対座標を取得（加速補正なし・正確）
let x = event.location(in: nil).x
let y = event.location(in: nil).y

// 1フレーム前との差分でユークリッド距離を計算（論理ポイント単位）
let dx = currentX - previousX
let dy = currentY - previousY
let distanceInPoints = sqrt(dx * dx + dy * dy)

// 論理ポイント → mm 変換
let displayID = CGMainDisplayID()
let physicalSize = CGDisplayScreenSize(displayID)  // mm単位の物理サイズ
let bounds = CGDisplayBounds(displayID)            // 論理解像度（points）
let mmPerPoint = physicalSize.width / bounds.width

let distanceInMM = distanceInPoints * mmPerPoint
```

**重要な設計判断**: `NSEvent.deltaX/Y`（加速補正済み）ではなく、**絶対座標の差分**を使用することで物理的に正確な距離が取得できる。ただしスクリーン端でのラッピングには注意が必要（クランプ処理で対応）。

MacBook Pro 14"の実例:
- 物理画面サイズ: 308mm × 196mm
- 論理解像度: 1512 × 982 points
- → 1 point ≈ 0.204mm

---

### 2-3. メニューバー常駐

**採用API**: `MenuBarExtra` (SwiftUI) — macOS 13以上  
**フォールバック**: `NSStatusItem` (AppKit) — macOS 12以下対応時

```swift
@main
struct TypeTrackerApp: App {
    var body: some Scene {
        MenuBarExtra("TypeTracker", systemImage: "keyboard") {
            ContentView()
        }
        .menuBarExtraStyle(.window)  // ポップオーバーウィンドウ形式
    }
}
```

---

### 2-4. データ永続化とリセット

| 要件 | 実装方法 |
|------|---------|
| 日次データ保存 | `UserDefaults` / `JSON` in `ApplicationSupport` |
| 日付をまたいだリセット | `midnight Timer` + `DateComponents` |
| スリープ前の保存 | `NSWorkspace.willSleepNotification` |
| 週次・月次履歴 | `JSON` ファイルに日付ごとに保存 |
| ログイン時自動起動 | `SMAppService.mainApp.register()` (macOS 13+) |

---

### 2-5. 配布方法

| 方法 | 権限要件 | 難易度 | 推奨 |
|------|---------|--------|------|
| Mac App Store | Input Monitoring エンタイトルメント申請 | 中 | ◯ |
| 直接配布 (DMG) | Developer ID 署名 + Notarization | 低 | ◎ 最初はこちら |
| TestFlight (macOS) | App Store Connect 登録 | 中 | △ |

**結論**: 最初は **Developer ID 署名 + Notarization** で直接配布が最も現実的。App Store展開は後工程で検討。

---

## 3. 比較対象データ（ファクトベース）

### 3-1. キーストローク比較リスト

| 比較対象 | キーストローク数 | ソース |
|---------|----------------|--------|
| ✉️ Twitter 1ツイート（日本語） | ~140キー | X仕様 |
| 📄 A4 1枚（800文字） | ~800キー | 一般基準 |
| 📚 ハリーポッター 第1巻（英語, 86,000語） | 約516,000キー | 多読サイト調査値 |
| 📚 **ハリーポッター 全7巻（英語）** | **約6,506,000キー** | **総語数1,084,335語 × 平均6打鍵で算出** |
| 📗 ハリーポッター 全巻（日本語版, 11冊）| 約3,960,000キー | 1冊約36万字 × 11冊 |
| 🏛️ 源氏物語（日本語） | 約1,000,000キー | 総文字数約100万字 |
| ✝️ 聖書（英語KJV） | 約4,700,000キー | 総語数783,137語 |
| 📖 ONE PIECE 全巻（推定） | 約2,000,000キー | セリフ文字数推計 |
| 🧬 ヒトゲノム（塩基数） | 3,000,000,000キー | 公式データ |

**実装時の推奨比較セット**（バランス重視）:
1. ハリーポッター第1巻（約516,000キー） ← 1日がんばれば見えてくるライン
2. ハリーポッター全7巻（約650万キー） ← 究極目標
3. 源氏物語（約100万キー） ← 和風・中間目標
4. Twitter 1ツイート（140キー） ← 最小単位・センス枠

---

### 3-2. マウス移動距離 比較リスト

| 比較対象 | 距離 | ソース |
|---------|------|--------|
| 🖥️ 27インチiMac 画面横断 | 約 600mm | 実測 |
| ⚽️ サッカーフィールド1往復 | 約 210m | FIFA規格 |
| 🗼 東京タワー（高さ） | 333m | 公式 |
| 🗻 富士山（標高） | 3,776m | 国土地理院 |
| 🏃 フルマラソン | **42,195m** | IAAF公式 |
| 🗾 東京→大阪（直線） | 約 400km | 地図実測 |
| 🌏 東京→ニューヨーク（直線） | 約 10,838km | 地図実測 |
| 🌍 地球一周 | 40,075km | IERS |
| 🌕 月までの距離 | 384,400km | NASA |

**実装時の推奨比較セット**:
1. 富士山（3,776m） ← 数日で届く感覚
2. フルマラソン（42,195m） ← 週単位の目標
3. 東京→大阪（400km） ← 月単位の目標
4. 地球一周（40,075km） ← 年間の究極目標

---

## 4. アーキテクチャ設計

```
TypeTracker.app
├── App Layer
│   ├── TypeTrackerApp.swift          // @main, MenuBarExtra定義
│   └── AppDelegate.swift             // NSApplicationDelegate
│
├── Core (ビジネスロジック)
│   ├── EventMonitor.swift            // CGEventTap ラッパー
│   │   ├── startMonitoring()
│   │   ├── stopMonitoring()
│   │   └── onKeyDown / onMouseMoved コールバック
│   ├── StatsManager.swift            // カウント管理・日次リセット
│   │   ├── @Published keyCount: Int
│   │   ├── @Published distanceMM: Double
│   │   └── resetAtMidnight()
│   └── DataStore.swift               // UserDefaults / JSON 永続化
│       ├── saveDailyStats()
│       ├── loadHistory() -> [DailyRecord]
│       └── DailyRecord: Codable
│
├── Conversion
│   ├── DistanceConverter.swift       // point → mm → 比較対象
│   └── KeystrokeConverter.swift      // count → 達成率・比較
│
└── UI (SwiftUI)
    ├── MenuBarView.swift             // メニューバー表示（ミニ表示）
    ├── PopoverView.swift             // クリック後のポップオーバー
    │   ├── KeystrokeSectionView
    │   └── DistanceSectionView
    ├── AchievementBadgeView.swift    // 達成率バッジ・プログレスバー
    └── HistoryView.swift             // 週次・月次グラフ
```

---

## 5. UI/UX 仕様

### 5-1. メニューバー表示（常時）

```
⌨️ 12,456  🖱 2.3km
```
- キーストローク数（カンマ区切り）
- 当日のマウス移動距離（m / km 自動切替）

### 5-2. クリック後ポップオーバー

```
┌─────────────────────────────────┐
│  ⌨️ 今日のタイピング              │
│                                 │
│  12,456 キー                    │
│  ████████░░░░░░░░░  48%        │
│  ハリーポッター 第1巻まで          │
│  あと 13,544 キー!              │
│                                 │
│  🖱 今日のカーソル移動             │
│                                 │
│  23.4 km                        │
│  ████████████░░░░  55%         │
│  フルマラソン 達成!               │
│  次の目標: 東京→大阪 まで 376km  │
│                                 │
│  📅 今日: 2026-02-14           │
│  ━━━━━━━━━━━━━━━━━━━━━━━       │
│  [履歴] [設定] [終了]           │
└─────────────────────────────────┘
```

### 5-3. 設定画面

- 比較対象の選択（キー・マウス各5項目から選択可）
- メニューバーの表示形式（アイコンのみ / 数字表示 / フル表示）
- ログイン時自動起動トグル
- データリセットボタン
- 週次サマリー通知（任意）

---

## 6. 実装フェーズ計画

### Phase 1: Core MVP（2〜3週間）
- [ ] Xcodeプロジェクト作成（macOS 13+, SwiftUI）
- [ ] `EventMonitor.swift`: `CGEventTap` でキーカウント + マウス座標取得
- [ ] `StatsManager.swift`: カウント管理・日次リセットロジック
- [ ] `MenuBarExtra` による最小限のメニューバー表示
- [ ] Input Monitoring 権限フロー（初回起動時ガイド）
- [ ] `UserDefaults` での日次データ保存

### Phase 2: 比較機能・UI（1〜2週間）
- [ ] `KeystrokeConverter` / `DistanceConverter` 実装（比較データ定数化）
- [ ] プログレスバー付きポップオーバーUI実装
- [ ] 達成時のアニメーション・通知
- [ ] 比較対象の自動切替ロジック（達成したら次の目標へ）

### Phase 3: 履歴・設定（1週間）
- [ ] `DataStore.swift`: JSON での週次・月次データ保存
- [ ] 履歴ビュー（棒グラフ / 折れ線グラフ） — `Swift Charts` 使用
- [ ] 設定画面実装
- [ ] ログイン時自動起動（`SMAppService`）

### Phase 4: 配布準備（1週間）
- [ ] Developer ID 署名設定
- [ ] Apple Notarization（`xcrun notarytool`）
- [ ] DMG パッケージング
- [ ] ランディングページ作成

---

## 7. 技術的リスクと対策

| リスク | 詳細 | 対策 |
|--------|------|------|
| 権限未付与 | Input Monitoring を拒否されると何も動かない | オンボーディング画面で必要性を丁寧に説明。`CGPreflightListenEventAccess()` でチェックし、設定画面への直リンク提供 |
| マウス座標変換の誤差 | マルチディスプレイ環境での座標跨ぎ | `CGEvent.location` のdisplayID判定、ディスプレイごとのmm/point比率を保持 |
| CPU負荷 | マウスMoved は非常に頻繁に発火 | バッチ処理（100ms間隔で積算）でメインスレッドへの通知を間引く |
| 日付リセットのずれ | スリープ中に日付が変わる場合 | 起動時・フォアグラウンド復帰時にも日付チェックを実施 |
| macOS バージョン対応 | `MenuBarExtra` は macOS 13以上 | 最低対応バージョンを macOS 13 に設定（2024年時点で85%以上がVentura以降） |

---

## 8. 使用ライブラリ・フレームワーク

| ライブラリ | 用途 | ライセンス |
|-----------|------|---------|
| CoreGraphics (Apple) | `CGEventTap` によるイベント監視 | Apple SDK |
| SwiftUI (Apple) | UI全般・`MenuBarExtra` | Apple SDK |
| Swift Charts (Apple) | 履歴グラフ（macOS 13+） | Apple SDK |
| ServiceManagement (Apple) | ログイン時自動起動 | Apple SDK |
| LaunchAtLogin (sindresorhus) | 自動起動の代替（macOS 12対応時） | MIT |

**サードパーティ依存は最小限**（LaunchAtLoginのみ検討）。Swift Package Manager で管理。

---

## 9. プライバシー設計

### 絶対に行わないこと
- キーの内容（文字・単語）の記録・送信
- マウス座標の記録（距離計算後は破棄）
- ネットワーク通信（完全オフライン動作）

### `Info.plist` 記載事項
```xml
<key>NSInputMonitoringUsageDescription</key>
<string>キーストローク数とマウス移動距離を計測するために使用します。
入力内容（文字）は一切記録しません。</string>
```

### App Storeレビュー対策
- Input Monitoring 権限の正当性をReview Notesで明記
- App Store Review Guidelines 2.4.5(iii)（バックグラウンドキー監視）への対応として、カウントのみで内容を記録しないことを強調

---

## 10. 参考リソース

- [Apple Developer Forums: CGEventTap and Input Monitoring](https://developer.apple.com/forums/thread/707680)
- [Apple Documentation: CGEvent.tapCreate](https://developer.apple.com/documentation/coregraphics/cgevent/tapcreate)
- [Apple Documentation: MenuBarExtra](https://developer.apple.com/documentation/swiftui/menubarextra)
- [Apple Documentation: SMAppService](https://developer.apple.com/documentation/servicemanagement/smappservice)
- ハリーポッター全7巻総語数: 1,084,335語（出典: 多読記録 / 原書word count調査）
- フルマラソン公式距離: 42.195km（出典: IAAF）
- 富士山標高: 3,776m（出典: 国土地理院）

---

*本計画書は2026-02-14時点の調査・情報に基づいています。*