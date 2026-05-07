SELECT 
    tjfConForSearch.contract_no,            -- 証券番号
    tjfConForSearch.dairiten_id,            -- 代理店コード
    tjfConForSearch.bank_siten_id,          -- 支店番号
    tjfConForSearch.contract_date,          -- 契約日
    tjfConForSearch.contr_indv_family_name_kana, -- 契約者カナ姓
    tjfConForSearch.contr_indv_given_name_kana,  -- 契約者カナ名
    ... (他、被保険者情報、商品名、フラグ類一式) ...,
    tjPetName.pet_name                      -- ペットネーム（愛称/商品表示名）
FROM 
    T_J_F_CONTRACT_FOR_SEARCH tjfConForSearch
LEFT OUTER JOIN 
    T_J_PET_NAME tjPetName 
ON 
    -- 代理店・プランIDが一致し、かつ契約の申込日が商品名（ペットネーム）の有効期間内であること
    tjfConForSearch.dairiten_id = tjPetName.dairiten_id
    AND tjPetName.plan_id = NVL(TRIM(tjfConForSearch.old_plan_id), tjfConForSearch.plan_id)
    AND tjfConForSearch.app_date >= tjPetName.dl_kaishibi   -- 取扱開始日
    AND tjfConForSearch.app_date <= tjPetName.dl_shuryobi   -- 取扱終了日

WHERE 
    1=1
    -- 【必須条件】
    AND tjfConForSearch.dairiten_id = ? /* param.getAgencyCode() ログイン中の代理店コードで強制絞り込み */

    -- 【動的条件：証券番号がある場合（最優先・他条件は無視）】
    [IF param.getContractNo() != null]
        AND tjfConForSearch.contract_no = ?
    
    -- 【動的条件：証券番号がなく、その他の条件がある場合】
    [IF param.getContractNo() == null]
        [IF getContractorLastNameKana != null] 
            AND tjfConForSearch.contr_indv_family_name_kana LIKE '?%' /* 前方一致(MatchMode.START) */
        [IF getContractorFirstNameKana != null]
            AND tjfConForSearch.contr_indv_given_name_kana LIKE '?%'
        [IF getInsuredLastNameKana != null]
            AND tjfConForSearch.insured_indv_family_name_kana LIKE '?%'
        [IF getInsuredFirstNameKana != null]
            AND tjfConForSearch.insured_indv_given_name_kana LIKE '?%'
        [IF param.getBranchCode() != null]
            AND tjfConForSearch.bank_siten_id = ? /* 完全一致 */

ORDER BY 
    tjfConForSearch.contr_indv_family_name_kana ASC,  -- カナ姓 昇順
    tjfConForSearch.contr_indv_given_name_kana ASC,   -- カナ名 昇順
    tjfConForSearch.contract_date ASC,                -- 契約日 昇順
    tjfConForSearch.contract_no ASC                   -- 証券番号 昇順