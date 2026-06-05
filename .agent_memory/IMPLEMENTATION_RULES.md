# IMPLEMENTATION_RULES.md

本檔記錄實作時需要遵守的技術與專案規則。

## Godot 專案規則

- 修改功能前先確認相關 `.tscn` 與 `.gd`。
- 不要只靠檔名猜測行為。
- 新增節點、訊號、group 時，要檢查現有場景是否需要同步更新。
- 保持 Godot 4.6 相容。

## 現有 group

目前單位相關 group 包含：

- `ally`
- `enemy`
- `player_units`
- `enemy_units`

新增單位時要保持 group 一致，否則可能影響：

- 單位互相攻擊
- 城堡受傷判定
- 節點佔領判定
- 單位數量統計

## 猜數字系統

- 目前由 `guess_engine.gd` 負責。
- 未來要支援 3 位、4 位、5 位答案。
- A/B/C 計算應集中管理，不要散落在 UI 或 `GameController` 中。
- 目前不可重複數字檢查需要重新檢視。

## 戰鬥與單位

- 多個單位腳本目前有重複邏輯。
- 若要新增大量單位能力，應考慮共用基底或統一介面。
- 小功能修改時，不要貿然大重構。

## 城堡傷害

城堡目前會讀取單位的：

- `attack_power`
- 或 `get_attack_power()`

若調整單位攻擊資料，需同步檢查城堡腳本。

## 節點佔領

- `ControlNode.gd` 目前會在士兵位於節點中心並進行佔領時鎖住士兵移動。
- 未來加入士氣推線時，必須確認士氣推線如何與節點佔領鎖定互動。

## 記憶更新規則

每次完成檔案修改後：

- 有新事實：更新 `PROJECT_CONTEXT.md`
- 有新規則：更新 `IMPLEMENTATION_RULES.md`
- 有使用者確認的設計：更新 `DESIGN_DECISIONS.md`
- 有新問題：更新 `OPEN_QUESTIONS.md`
- 有未來功能調整：更新 `FEATURE_BACKLOG.md`
- 有修改檔案：更新 `WORK_LOG.md`

若沒有修改檔案，則不需要更新 `WORK_LOG.md`。
