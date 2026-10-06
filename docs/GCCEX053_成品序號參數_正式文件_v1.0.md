# GCCEX053 合同BOM(成品/料件)明細表：新增成品序號參數 正式文件

> 文件版本：v1.0  
> 最後更新：2026-10-06  
> 文件狀態：Draft（尚未編譯與測試）

## 1. 系統概述

`GCCEX053:合同BOM(成品/料件)明細表` 是 EBS Concurrent Program，由 `APPS.GCCEX053_PKG.MAIN` 產生以 `|` 分隔的文字輸出。報表格式分兩種：

- `P_G_MARK = '4'`：成品明細，資料來源 `FL_GCC_HZ_EXG_ITEM`
- `P_G_MARK = '3'`：料件明細，資料來源 `FL_GCC_HZ_IMG_ITEM`

## 2. 需求範圍與設計摘要

新增兩個查詢參數，可依成品序號範圍篩選報表：

| 參數畫面名稱 | 程式參數 | 型態 | 必填 |
|---|---|---|---|
| 成品序號(起) | `P_FG_EMS_G_NO_S` | NUMBER | 否 |
| 成品序號(迄) | `P_FG_EMS_G_NO_E` | NUMBER | 否 |

- 參數留空代表那一邊不限制。
- 兩個都有輸入時，成品序號(起)不可大於成品序號(迄)，否則報表以錯誤結束。
- 原有參數與輸出欄位都不變。

## 3. 影響範圍與物件清單

| 物件 | 類型 | 異動 |
|---|---|---|
| `APPS.GCCEX053_PKG`（`GCCEX053_PKG.pks`） | Package Spec | `MAIN` 新增 2 個參數 |
| `APPS.GCCEX053_PKG`（`GCCEX053_PKG.pkb`） | Package Body | 新增參數、起迄檢核，並在 `HZ_EXG`、`HZ_IMG` cursor 加篩選條件 |
| GCCEX053 | Concurrent Program | 新增 2 個參數定義 |

原始檔為 Big5 編碼、CRLF 換行，部署時請維持相同編碼，避免中文註解變成亂碼。

## 4. 設計細節

### 4.1 欄位對應

| 報表格式 | 篩選欄位 | 欄位型態 |
|---|---|---|
| 成品（4） | `FL_GCC_HZ_EXG_ITEM.EMS_G_NO` | NUMBER(19,0) |
| 料件（3） | `FL_GCC_HZ_IMG_ITEM.FG_EMS_G_NO` | VARCHAR2(20) |

### 4.2 成品明細條件（HZ_EXG）

```sql
AND (P_FG_EMS_G_NO_S IS NULL OR FHE.EMS_G_NO >= P_FG_EMS_G_NO_S)
AND (P_FG_EMS_G_NO_E IS NULL OR FHE.EMS_G_NO <= P_FG_EMS_G_NO_E)
```

### 4.3 料件明細條件（HZ_IMG）

`FG_EMS_G_NO` 是文字欄位，先確認是純數字再轉換，其他值視為 NULL。這樣可以避免 ORA-01722，也能用數字順序比較（1, 2, …, 10）。

```sql
AND (P_FG_EMS_G_NO_S IS NULL OR
     TO_NUMBER(CASE WHEN REGEXP_LIKE(TRIM(FHI.FG_EMS_G_NO), '^[0-9]+$')
                    THEN TRIM(FHI.FG_EMS_G_NO) END) >= P_FG_EMS_G_NO_S)
AND (P_FG_EMS_G_NO_E IS NULL OR
     TO_NUMBER(CASE WHEN REGEXP_LIKE(TRIM(FHI.FG_EMS_G_NO), '^[0-9]+$')
                    THEN TRIM(FHI.FG_EMS_G_NO) END) <= P_FG_EMS_G_NO_E)
```

> **Note**：有輸入序號範圍時，`FG_EMS_G_NO` 為非數字或空值的料件不會出現在報表中；沒輸入範圍時照常全部列出。

### 4.4 起迄檢核

`MAIN` 一開始先檢查：兩個參數都有輸入，且起大於迄時，不產生報表資料，直接結束。

```sql
IF P_FG_EMS_G_NO_S IS NOT NULL AND P_FG_EMS_G_NO_E IS NOT NULL
   AND P_FG_EMS_G_NO_S > P_FG_EMS_G_NO_E THEN
   ERRBUF  := '成品序號(起) ' || P_FG_EMS_G_NO_S || ' 不可大於成品序號(迄) ' || P_FG_EMS_G_NO_E;
   RETCODE := 2;
   FND_FILE.PUT_LINE(FND_FILE.LOG, ERRBUF);
   FND_FILE.PUT_LINE(FND_FILE.OUTPUT, ERRBUF);
   RETURN;
END IF;
```

- `RETCODE := 2`：Concurrent Request 狀態為 **Error**，Completion Text 顯示錯誤訊息。
- 錯誤訊息同時寫入 Log 和 Output，使用者直接看 Output 也能知道原因。
- 只有一邊有輸入時不檢核。

## 5. 權限與相依設定

- Package 仍在 `APPS` 底下，沒有新增 Table 或 View，不需要額外授權。
- Concurrent Program 參數（System Administrator → Concurrent → Program → Define → Parameters）：

| Seq | Parameter | Prompt | Value Set | Required | Range | Display Size |
|---|---|---|---|---|---|---|
| 60 | P_FG_EMS_G_NO_S | 成品序號(起) | `FND_NUMBER` | No | Low | 15 |
| 70 | P_FG_EMS_G_NO_E | 成品序號(迄) | `FND_NUMBER` | No | High | 15 |

- `FND_NUMBER` 在本環境的設定（已查核 `FND_FLEX_VALUE_SETS`）：Format Type Number、Maximum Size 15、Precision 0、Min Value 0、Validation Type None。也就是只允許 0 以上的整數，符合「成品序號為整數」的需求。
- Range 設 Low／High：兩個都有輸入且迄小於起時，在參數畫面按 OK 就會被擋下。程式內的起迄檢核保留，用來處理不經參數畫面送出的情況。
- Default Type 空白、Enable Security 不勾，Token 不用填。

> **Warning**：參數 Sequence 必須排在「報表格式:成品或料件」之後，因為程式是照順序傳參數。順序錯誤會造成參數錯位，或發生 `PLS-00306`。

## 6. 部署步驟

| 步驟 | 執行者 | 動作 | 成功判斷 | 失敗處置 |
|---|---|---|---|---|
| 1 | DBA／開發 | 備份正式區現有 `GCCEX053_PKG` 原始碼（見附錄 10.1） | 取得 spec 與 body 原始碼 | 停止部署 |
| 2 | DBA／開發 | 以 APPS 編譯 `GCCEX053_PKG.pks` | 無編譯錯誤 | 查 `USER_ERRORS` |
| 3 | DBA／開發 | 以 APPS 編譯 `GCCEX053_PKG.pkb` | 無編譯錯誤 | 查 `USER_ERRORS` |
| 4 | DBA／開發 | 確認物件狀態（見附錄 10.2） | 兩筆都是 `VALID` | 重新編譯或 rollback |
| 5 | EBS 系統管理員 | Concurrent Program 新增兩個參數（見第 5 節） | 參數畫面出現兩個新欄位 | 檢查 Seq 與 Value Set |
| 6 | 使用者 | 執行第 7 節驗證 | 結果符合預期 | 依第 8 節 rollback |

步驟 2 到 5 之間，舊的參數定義和新的 Package 不一致，送出報表會失敗，請在離峰時段一次完成。

## 7. UAT 與上線後驗證

| # | 報表格式 | 成品序號(起) | 成品序號(迄) | 預期結果 |
|---|---|---|---|---|
| 1 | 成品 | 空 | 空 | 與修改前相同 |
| 2 | 成品 | 1 | 10 | 只列出成品序號 1–10 |
| 3 | 成品 | 5 | 空 | 只列出成品序號 ≥ 5 |
| 4 | 料件 | 空 | 空 | 與修改前相同 |
| 5 | 料件 | 2 | 2 | 只列出成品序號 2 的料件 |
| 6 | 料件 | 1 | 10 | 包含成品序號 10 的料件（確認不是文字排序） |
| 7 | 成品或料件 | 10 | 5 | Request 狀態為 Error，Log 和 Output 顯示「成品序號(起) 10 不可大於成品序號(迄) 5」 |

## 8. Rollback Plan

1. 用步驟 1 的備份重新編譯 `GCCEX053_PKG` 的 spec 與 body。
2. 在 Concurrent Program 刪除或停用兩個新參數。
3. 用修改前的參數送出報表，確認可以正常執行。

## 9. 常見問題與維運排查

| 現象 | 可能原因 | 排查 |
|---|---|---|
| 送出報表時發生 `PLS-00306` | 參數數量或順序和 Package 不一致 | 核對 Concurrent Program 參數 Seq |
| 料件報表少了部分資料 | `FG_EMS_G_NO` 有非數字值 | 執行附錄 10.3 |
| Request 狀態為 Error，訊息為「成品序號(起) … 不可大於成品序號(迄) …」 | 起大於迄 | 重新輸入正確範圍 |
| 報表沒有任何資料 | 該範圍內沒有對應的成品序號 | 確認合同號與序號範圍 |

## 10. 附錄：SQL Scripts

### 10.1 備份現有原始碼（唯讀）

```sql
SELECT TYPE, LINE, TEXT
  FROM ALL_SOURCE
 WHERE OWNER = 'APPS' AND NAME = 'GCCEX053_PKG'
 ORDER BY TYPE, LINE;
```

### 10.2 確認編譯狀態（唯讀）

```sql
SELECT OBJECT_NAME, OBJECT_TYPE, STATUS
  FROM ALL_OBJECTS
 WHERE OWNER = 'APPS' AND OBJECT_NAME = 'GCCEX053_PKG';
```

### 10.3 查 FG_EMS_G_NO 非數字資料（唯讀）

```sql
SELECT FG_EMS_G_NO, COUNT(*)
  FROM FL_GCC_HZ_IMG_ITEM
 WHERE NOT REGEXP_LIKE(TRIM(FG_EMS_G_NO), '^[0-9]+$')
    OR FG_EMS_G_NO IS NULL
 GROUP BY FG_EMS_G_NO;
```
