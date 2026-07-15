# AGENTS.md

## 專案定位

My Garage 是一個機車保養與車庫管理 App，核心功能包含：

- 機車保養紀錄管理。
- 加油紀錄管理。
- 油耗分析與統計。
- 支援新增與管理複數車輛。
- 以 Garage 概念整合車輛、保養、加油與分析資料。

開發時請優先維持「多車輛管理」作為資料模型與 UI 流程的基礎假設，不要只針對單一車輛硬寫邏輯。

## 技術棧

本專案使用：

- Flutter
- MVVM
- Riverpod
- Supabase

新增功能或重構時，請遵守上述架構，不要引入其他狀態管理框架或後端服務，除非使用者明確要求。

## 架構規則

- UI 層只負責畫面呈現、使用者互動與呼叫 ViewModel。
- ViewModel 負責畫面狀態、表單狀態、載入狀態、錯誤狀態與使用案例協調。
- Repository 負責資料來源抽象，包含 Supabase 查詢、寫入與資料轉換。
- Model/Entity 負責描述車輛、保養紀錄、加油紀錄、油耗統計等核心資料。
- Riverpod provider 應集中管理依賴注入與狀態暴露，避免在 widget 中直接建立 repository 或 service。
- Supabase client 初始化應集中管理，不要在各個 widget 或 ViewModel 中重複初始化。

建議目錄方向：

```text
lib/
  core/
    config/
    errors/
    utils/
  features/
    garage/
    vehicles/
    maintenance/
    fuel/
    analytics/
  shared/
    widgets/
    providers/
```

實際實作時可以依現有程式碼調整，但應保持 feature-first 與 MVVM 分層清楚。

## 資料與功能規則

- 所有保養紀錄與加油紀錄都必須能關聯到特定 vehicle。
- 支援複數車輛，因此列表、查詢、統計與新增表單都應考慮 `vehicleId`。
- 油耗分析應以加油紀錄為基礎，避免在多處重複計算同一份邏輯。
- 日期、里程、金額、油量等欄位應使用明確型別與驗證，避免用自由文字儲存可計算資料。
- 涉及 Supabase 的資料表、欄位名稱與 RLS 規則時，請保持命名一致並記錄必要 schema 假設。

## Flutter 與 Riverpod 規則

- 優先使用 `ConsumerWidget`、`ConsumerStatefulWidget` 或 Riverpod code generation 風格，依專案既有模式決定。
- ViewModel 狀態應使用不可變資料結構，避免直接修改 shared mutable state。
- 非同步狀態應清楚呈現 loading、data、empty、error。
- UI 元件應保持可重用，常用元件放在 `shared/widgets` 或 feature 內的 `widgets`。
- 表單驗證應靠近表單或 ViewModel 管理，不要散落在 repository。

## Supabase 規則

- Supabase 存取應透過 repository/service 封裝。
- 不要在 UI widget 中直接呼叫 Supabase query。
- 涉及登入使用者資料時，所有查詢都應考慮目前 user scope。
- 對資料新增、修改、刪除時，應明確處理錯誤並讓 ViewModel 將錯誤回饋給 UI。
- 不要將 Supabase URL、anon key 或其他敏感設定硬編碼在業務邏輯中；應集中於設定層或環境設定。

## 開發品質

- 修改程式後，優先執行 `flutter analyze`。
- 新增核心邏輯時，補上對應 unit test 或 widget test。
- 保持檔案與 class 命名清楚，例如 `Vehicle`, `MaintenanceRecord`, `FuelRecord`, `FuelEfficiencySummary`。
- 不要為了短期方便破壞 MVVM 分層。
- 避免一次混入大量無關重構；變更應聚焦在當前需求。

## 溝通偏好

- 回覆使用繁體中文。
- 說明程式修改時，請簡潔列出主要變更、受影響檔案與驗證結果。
- 如果需要新增套件、建立 Supabase schema 或調整資料表，請先說明原因與影響。
