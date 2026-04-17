erDiagram
    %% ==========================================
    %% 1. マスタデータ層（Read-Only / 補完用）
    %% ==========================================
    AGENT ["AGENT (募集人マスタ)"] {
        varchar AGENT_ID PK "募集人コード (内部Key: 補完のゴール)"
        varchar AGENT_INS_TYPE_1 UK "生保募集人登録番号 (CSV E列と合致するか検索)"
        varchar AGENT_EMPLOYEE_CODE "社員番号 (補完対象)"
        varchar AGENT_PRIMARY_CO "幹事代理店コード"
    }

```mermaid
erDiagram
    %% ==========================================
    %% 1. マスタデータ層（Read-Only / 補完用）
    %% ==========================================
    AGENT ["AGENT (募集人マスタ)"] {
        varchar AGENT_ID PK "募集人コード (内部Key: 補完のゴール)"
        varchar AGENT_INS_TYPE_1 UK "生保募集人登録番号 (CSV E列と合致するか検索)"
        varchar AGENT_EMPLOYEE_CODE "社員番号 (補完対象)"
        varchar AGENT_PRIMARY_CO "幹事代理店コード"
    }

    AGTLIC ["AGTLIC (募集人販売資格マスタ)"] {
        varchar AGTLIC_AGENT_ID PK, FK "募集人コード"
        varchar AGTLIC_LIC_TYPE PK "資格種別 (FC:外貨 等)"
        varchar AGTLIC_LICENSE_NO "資格番号 (補完対象)"
        date AGTLIC_EFF_DATE "資格有効開始日"
        date AGTLIC_REN_TRM_DATE "資格有効終了日"
    }

    CONSTANT ["CONSTANT (固定値マスタ)"] {
        varchar CONST_KEY PK "キー (002等)"
        varchar CONST_VALUE "設定値 (ユーザーID生成用の 'NVS' 等)"
    }

    %% ==========================================
    %% 2. トランザクション/履歴層（Audit / Backup）
    %% ==========================================
    ID_ENTRY_FILE ["ID_ENTRY_FILE (取込ファイル履歴)"] {
        varchar ID_ENTRY_FILE_NAME PK "【自動取得】ファイル名 (例: ID_2604...csv)"
        date FILE_IMPORT_DATE "システム日付"
        number FILE_IMPORT_COUNT "CSVの総行数"
        varchar AGENCYCODE "CSV ヘッダE列から取得"
        varchar CHANGED_BY "ログイン画面のユーザーID"
    }

    ID_ENTRY_FILE_DTIL ["ID_ENTRY_FILE_DTIL (取込ファイル明細履歴)"] {
        varchar ID_ENTRY_FILE_NAME PK, FK "【PK①】ファイル名"
        number ID_ENTRY_FILE_SEQ_NO PK "【PK②】自動採番: 取込連番 (1, 2, 3...)"
        varchar GW_ID "CSV B列 (共同GW利用ID: B0116...)"
        varchar BS_TOROKU_ID "CSV E列 (生保募集人登録番号)"
        varchar USER_ID "生成: [NVS] + GW_ID"
        varchar PASSWORD "生成: USER_IDの反転文字列から10文字"
        varchar AGENT_EMPLOYEE_CODE "マスタ補完: 社員番号"
    }

    %% ==========================================
    %% 3. ワーク層（Processing / To-Beでは廃止推奨）
    %% ==========================================
    ID_ENTRY_FILE_INPUT_WORK ["ID_ENTRY_FILE_INPUT_WORK (取込ワーク)"] {
        varchar ID_ENTRY_FILE_NAME PK, FK "【PK①】ファイル名"
        number ID_ENTRY_FILE_SEQ_NO PK "【PK②】自動採番: 取込連番 (1, 2, 3...)"
        varchar GW_ID "CSV B列 (共同GW利用ID: B0116...)"
        varchar USER_ID "生成: 定数[NVS] + B列"
        varchar PASSWORD "生成: USER_ID反転前10桁"
        varchar BS_TOROKU_ID "CSV E列 (生保募集人登録番号)"
        varchar AGENT_ID "マスタ補完: AGENT_ID"
        varchar FC_LICENSE_NO "マスタ補完: 外貨資格番号"
    }

    %% ==========================================
    %% 4. コア/ターゲット層（Final Destination）
    %% ==========================================
    USER_INFO ["USER_INFO (ユーザIDマスタ)"] {
        varchar USER_ID PK "【PK】生成: [NVS] + CSV B列 (NWL Key)"
        varchar UI_GW_ID "CSV B列 (CGW Key)"
        varchar UI_AGENTCODE FK "補完: AGENT_ID (FIMMAS Key)"
        varchar UI_AGENCYCODE "CSV ヘッダE列 または マスタ補完"
        varchar UI_PASSWORD "生成: USER_ID反転前10桁"
        varchar UI_USER_NAME "CSV D列 (氏名: 山崎慶太)"
        varchar UI_BS_TOROKU_ID "CSV E列 (生保募集人登録番号: 20DR...)"
        varchar UI_SYAIN_NO "補完: 社員番号"
        varchar UI_DELETE_FLAG "処理区分により 0(有効) or 1(削除)"
    }

    %% ==========================================
    %% リレーションシップ
    %% ==========================================
    AGENT ||--o{ AGTLIC : "1人の募集人は複数の資格を持つ"
    
    ID_ENTRY_FILE ||--|{ ID_ENTRY_FILE_DTIL : "1ファイルは複数の明細履歴を持つ"
    ID_ENTRY_FILE ||--|{ ID_ENTRY_FILE_INPUT_WORK : "1ファイルは複数のワークデータを持つ"
    
    %% データの照合・補完関係（論理的リレーション）
    ID_ENTRY_FILE_INPUT_WORK }o..|| AGENT : "CSV E列でAGENTを検索しAGENT_IDを取得"
    ID_ENTRY_FILE_INPUT_WORK }o..o| AGTLIC : "取得したAGENT_IDで資格を検索"
    
    %% 最終統合（MERGE）
    ID_ENTRY_FILE_INPUT_WORK }|..|| USER_INFO : "USER_IDをキーにMERGE(Upsert)"
```