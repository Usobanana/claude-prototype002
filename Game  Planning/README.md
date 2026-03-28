# Game Planning — ドキュメント一覧
> 最終更新: 2026-03-28

---

## プロジェクト概要

**タイトル（仮）**: 未定  
**ジャンル**: PvPvE エクストラクション アクション  
**エンジン**: Godot 4.x / HD-2D Isometric

### エレベーターピッチ
> 「自分だけの拠点を育てながら、危険なフィールドへ乗り込み、資源を持ち帰れ。  
> 死ねばすべてを失う。生き残れ。」

---

## コアゲームループ

```
拠点（ロビー）
  ↓ 装備を整える・施設を強化する
フィールド（マッチ）
  ↓ 資源・武器を集める、エネミーを倒す、他プレイヤーと戦う
脱出ポイントへ到達
  ↓ 持ち帰った資源で拠点を強化
拠点（ロビー） へ戻る

※死亡した場合 → 持ち込んだ所持品をすべてロスト → 拠点へ強制帰還
```

---

## ドキュメント構成

### 📁 overview/ — ゲーム概要
| ファイル | 内容 |
|---|---|
| [GDD_v0.1.md](./overview/GDD_v0.1.md) | ゲームデザインドキュメント。クラス・武器・戦闘・マッチメイキング・技術スタックなど全体設計 |

### 📁 specs/ — 各要素の仕様書
| ファイル | 内容 |
|---|---|
| [field_rules.md](./specs/field_rules.md) | フィールドルール。マッチの流れ・脱出ポイント・収束円の仕様 |
| [death_system.md](./specs/death_system.md) | 死亡・ダウンシステム。状態遷移・保険スロット・観戦モードの仕様 |
| [skill_system.md](./specs/skill_system.md) | スキルシステム。マッチ内レベルアップ・スキル進化・ビルドのリプレイ性 |

### 📁 reference/ — 開発リファレンス
| ファイル | 内容 |
|---|---|
| [claude_godot_capabilities.md](./reference/claude_godot_capabilities.md) | Claude × Godot の対応範囲。Claudeが直接できること・できないことの整理 |

---

## 今後追加予定のドキュメント

- `specs/class_system.md` — クラス別詳細仕様
- `specs/weapon_system.md` — 武器・攻撃判定の詳細
- `specs/hub_system.md` — 拠点・施設強化の仕様
- `specs/enemy_system.md` — エネミーAI・種類の詳細
- `specs/item_system.md` — アイテム・レアリティの詳細
- `glossary.md` — 用語集

---

*このREADMEはドキュメントの追加・変更に合わせて随時更新する*
