SELECT COUNT(*) FROM (
    SELECT hash_prep.*,
        CASE WHEN HASH_PREP.HASH_KEY = FIRST_VALUE(HASH_PREP.HASH_KEY) OVER(
            PARTITION BY HASH_PREP.STAT_REP_LN, HASH_PREP.Report_Cury_Type, HASH_PREP.Cury_Key ORDER BY HASH_PREP.strt_dt ASC
            ROWS BETWEEN 1 PRECEDING AND 1 PRECEDING)
        THEN 1 ELSE 0 END AS FK_UP
    FROM (
        SELECT BUS_QRY.*,
            sha2(
coalesce(TEC_STS, '') ||
coalesce(openbal, '') ||
coalesce(openballcl, '') ||
coalesce(crmovement, '') ||
coalesce(crmvmtlcl, '') ||
coalesce(dbmovement, '') ||
coalesce(dbmvmtlcl, '') ||
coalesce(closingbal, '') ||
coalesce(closingballcl, '') ||
coalesce(mvmtasplit, '') ||
coalesce(mvmtpsplit, '') ||
coalesce(mvmtrsplit, '') ||
coalesce(crmvmtytd, '') ||
coalesce(crmvmtmth, '') ||
coalesce(crmvmtytdlcl, '') ||
coalesce(crmvmtmthlcl, '') ||
coalesce(dbmvmtytd, '') ||
coalesce(dbmvmtmth, '') ||
coalesce(dbmvmtytdlcl, '') ||
coalesce(dbmvmtmthlcl, '')
            , 256) AS HASH_KEY
        FROM (
            
             SELECT 
             Rep_NM||'.'||rep_ln_no  STAT_REP_LN , -- kEY
             Report_Cury_Type ,  -- kEY
             CASE WHEN rep_ln_cury_key='LOCAL' THEN'EGP' ELSE rep_ln_cury_key END  Cury_Key, -- kEY
             Rep_LN_DT  STRT_DT , 
             TEC_STS,  
             openbal,
             openballcl,
             crmovement,
             crmvmtlcl,
             dbmovement,
             dbmvmtlcl,
             closingbal,
             closingballcl,
             mvmtasplit,
             mvmtpsplit,
             mvmtrsplit,
             crmvmtytd,
             crmvmtmth,
             crmvmtytdlcl,
             crmvmtmthlcl,
             dbmvmtytd,
             dbmvmtmth,
             dbmvmtytdlcl,
             dbmvmtmthlcl  
              from
            (
            SELECT * ,
               CASE WHEN  rep_ln_cury_key='EGP' THEN 'LOCAL'  ELSE 'By Currency' END  AS Report_Cury_Type
              ,ROW_NUMBER() OVER(PARTITION BY rep_nm,rep_ln_no,rep_ln_cury_key,rep_ln_dt  ORDER BY rep_ln_dt DESC  ,k_processingtime desc ) RN  
             FROM 
             (
            SELECT 
            k_entityid ,
            substr(k_entityid ,1,5)  Rep_NM ,
            substr(k_entityid ,7,4)  Rep_LN_NO ,
            --substr(k_entityid ,12 ,instr(k_entityid,'-',12)-12)  Rep_LN_cury_key , (impala)
            substr(k_entityid, 12, locate('-', k_entityid, 12) - 12) AS Rep_LN_cury_key, 
            --from_unixtime(unix_timestamp(substr(k_entityid ,instr(k_entityid,'-',-1)+1 )  ,'yyyyMMdd'),'yyyy-MM-dd')    Rep_LN_DT , (impala)
            from_unixtime(unix_timestamp(substr(k_entityid, length(k_entityid) - instr(reverse(k_entityid), '-') + 2), 'yyyyMMdd'), 'yyyy-MM-dd') AS Rep_LN_DT,
            context_companycode,context_transactiontype,context_bankingdate,
             CASE WHEN context_operation='WRITE' THEN 'ACTIVE' ELSE 'DELETED' END TEC_STS ,
             context_cobdate,context_transactionref,
             context_operation,
             k_processingtime, 
             lineccydate,openbal,openballcl,crmovement,crmvmtlcl,dbmovement,dbmvmtlcl,closingbal,closingballcl,
             mvmtasplit,mvmtpsplit,mvmtrsplit,crmvmtytd,crmvmtmth,crmvmtytdlcl,crmvmtmthlcl,dbmvmtytd,dbmvmtmth,
             dbmvmtytdlcl,dbmvmtmthlcl,tec_insrt_dttm,tec_upd_dttm,dr_dttm,dr_flg,insert_date
             FROM  
             stg_t24.fodb_re_stat_line_bal
              
              )BAL_0
            WHERE  Rep_LN_DT BETWEEN DATE '${strt_dt}'  AND DATE '${end_dt}'
              )Base_01
              WHERE RN=1
        ) BUS_QRY
    ) HASH_PREP
) FINAL WHERE FK_UP <> 1
