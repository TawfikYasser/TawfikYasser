SELECT COUNT(*) FROM (
    SELECT hash_prep.*,
        CASE WHEN HASH_PREP.HASH_KEY = FIRST_VALUE(HASH_PREP.HASH_KEY) OVER(
            PARTITION BY HASH_PREP.CRD_KEY ORDER BY HASH_PREP.strt_dt ASC
            ROWS BETWEEN 1 PRECEDING AND 1 PRECEDING)
        THEN 1 ELSE 0 END AS FK_UP
    FROM (
        SELECT BUS_QRY.*,
            sha2(
coalesce(CRD_PRD_KEY, '') ||
coalesce(TRX_CD, '') ||
coalesce(CYCLE_LEN, '') ||
coalesce(CYCLE_BEGIN, '') ||
coalesce(CSH_AMT, '') ||
coalesce(CSH_TRX, '') ||
coalesce(PURCH_AMT, '') ||
coalesce(PURCH_TRX, '') ||
coalesce(TOT_PURCH_AMT, '') ||
coalesce(TOT_PURCH_TRX, '') ||
coalesce(VIP_MUL, '') ||
coalesce(CSH_AMT_TD, '') ||
coalesce(CSH_NUM_TD, '') ||
coalesce(PURCH_AMT_TD, '') ||
coalesce(PURCH_NUM_TD, '')
            , 256) AS HASH_KEY
        FROM (
            select stg.* ,mod.hash_key as old_hash_key
            ,current_timestamp as ins_dttm ,null as end_dttm ,current_timestamp as  str_dttm,current_date as strt_dt
            ,CURRENT_TIMESTAMP                          AS  Tec_Insrt_Dttm
            		   ,CURRENT_TIMESTAMP                          AS  Tec_Upd_Dttm
            		   ,null                          AS  DR_Dttm
            		   ,null                          AS  DR_Flg
            from
            ( 
            SELECT 
            	LMT.CRDDET_ID		AS	CRD_KEY			-- PK
            	,PRD.ID				AS	CRD_PRD_KEY
            	,PLMT.LIMIT_TXNS	AS	TRX_CD
            	,CASE WHEN LMT.CYCLE_LEN='0'  THEN 'None'
            		  WHEN LMT.CYCLE_LEN='80' THEN 'Weekly'
            		  WHEN LMT.CYCLE_LEN='81' THEN 'Fortnightly (every 2 weeks)'
            		  WHEN LMT.CYCLE_LEN='82' THEN 'Bi-Monthly'
            		  WHEN LMT.CYCLE_LEN='83' THEN 'Monthly'
            		  WHEN LMT.CYCLE_LEN='84' THEN 'Quarterly'
            		  WHEN LMT.CYCLE_LEN='85' THEN 'Bi-Yearly'
            		  WHEN LMT.CYCLE_LEN='86' THEN 'Yearly'else 'not matched' END AS CYCLE_LEN
            	,LMT.CYCLE_BEGIN
            	,CASE WHEN LMT.CASHLIM_AMT=0 THEN PLMT.CASHLIM_AMT ELSE LMT.CASHLIM_AMT END AS	CSH_AMT
            	,CASE WHEN LMT.CASHLIM_NUM=0 THEN PLMT.CASHLIM_NUM ELSE LMT.CASHLIM_NUM END AS	CSH_TRX
            	,CASE WHEN LMT.PURCHLIM_AMT=0 THEN PLMT.PURCHLIM_AMT ELSE LMT.PURCHLIM_AMT END AS	PURCH_AMT
            	,CASE WHEN LMT.PURCHLIM_NUM=0 THEN PLMT.PURCHLIM_NUM ELSE LMT.PURCHLIM_NUM END AS	PURCH_TRX
            	,CASE WHEN LMT.TOTLIM_AMT=0 THEN PLMT.TOTLIM_AMT ELSE LMT.TOTLIM_AMT END AS	TOT_PURCH_AMT
            	,CASE WHEN LMT.TOTLIM_NUM=0 THEN PLMT.TOTLIM_NUM ELSE LMT.TOTLIM_NUM END AS	TOT_PURCH_TRX
            	,PLMT.VIP_MUL
            	,LMT.CASH_AMT_TD		AS	CSH_AMT_TD
            	,LMT.CASH_NUM_TD		AS	CSH_NUM_TD
            	,LMT.PURCH_AMT_TD
            	,LMT.PURCH_NUM_TD
            --  ,md5(LMT.CRDDET_ID) as hash_key
               ,md5(concat(PRD.ID				
            	,PLMT.LIMIT_TXNS	
            	,CASE WHEN LMT.CYCLE_LEN='0'  THEN 'None'
            		  WHEN LMT.CYCLE_LEN='80' THEN 'Weekly'
            		  WHEN LMT.CYCLE_LEN='81' THEN 'Fortnightly (every 2 weeks)'
            		  WHEN LMT.CYCLE_LEN='82' THEN 'Bi-Monthly'
            		  WHEN LMT.CYCLE_LEN='83' THEN 'Monthly'
            		  WHEN LMT.CYCLE_LEN='84' THEN 'Quarterly'
            		  WHEN LMT.CYCLE_LEN='85' THEN 'Bi-Yearly'
            		  WHEN LMT.CYCLE_LEN='86' THEN 'Yearly' else 'not matched' END 
            	,LMT.CYCLE_BEGIN
            	,CASE WHEN LMT.CASHLIM_AMT=0 THEN PLMT.CASHLIM_AMT ELSE LMT.CASHLIM_AMT END 
            	,CASE WHEN LMT.CASHLIM_NUM=0 THEN PLMT.CASHLIM_NUM ELSE LMT.CASHLIM_NUM END 
            	,CASE WHEN LMT.PURCHLIM_AMT=0 THEN PLMT.PURCHLIM_AMT ELSE LMT.PURCHLIM_AMT END 
            	,CASE WHEN LMT.PURCHLIM_NUM=0 THEN PLMT.PURCHLIM_NUM ELSE LMT.PURCHLIM_NUM END 
            	,CASE WHEN LMT.TOTLIM_AMT=0 THEN PLMT.TOTLIM_AMT ELSE LMT.TOTLIM_AMT END 
            	,CASE WHEN LMT.TOTLIM_NUM=0 THEN PLMT.TOTLIM_NUM ELSE LMT.TOTLIM_NUM END 
            	,PLMT.VIP_MUL
            	,LMT.CASH_AMT_TD	
            	,LMT.CASH_NUM_TD	
            	,LMT.PURCH_AMT_TD
            	,LMT.PURCH_NUM_TD)) as hash_key
              
            FROM ${stg_schema}.CRDLIMIT LMT 
            INNER JOIN ${stg_schema}.CRDDET CRD
            	ON CRD.ID = LMT.CRDDET_ID
            INNER JOIN ${stg_schema}.CRDPRODUCT PRD 
            	ON CRD.CRDPRODUCT_ID = PRD.ID
            INNER JOIN ${stg_schema}.CRDPRODLIM PLMT
            	ON	PRD.ID = PLMT.CRDPRODUCT_ID) as stg
            
            left join 
            
            (select * from  ${mod_schema}.${filename} where end_dttm is null )as mod
            
            on  stg.hash_key =mod.hash_key and stg.CRD_KEY =mod.CRD_KEY
            where  mod.CRD_KEY is null --or  stg.CRD_KEY is null
            
            union 
            
            
            select stg.* ,mod.hash_key as old_hash_key
            ,current_timestamp as ins_dttm ,null as end_dttm ,current_timestamp as  str_dttm,current_date as strt_dt
            ,CURRENT_TIMESTAMP                          AS  Tec_Insrt_Dttm
            		   ,CURRENT_TIMESTAMP                          AS  Tec_Upd_Dttm
            		   ,null                          AS  DR_Dttm
            		   ,null                          AS  DR_Flg
            from
            ( 
            SELECT 
            	LMT.CRDDET_ID		AS	CRD_KEY			-- PK
            	,PRD.ID				AS	CRD_PRD_KEY
            	,PLMT.LIMIT_TXNS	AS	TRX_CD
            	,CASE WHEN LMT.CYCLE_LEN='0'  THEN 'None'
            		  WHEN LMT.CYCLE_LEN='80' THEN 'Weekly'
            		  WHEN LMT.CYCLE_LEN='81' THEN 'Fortnightly (every 2 weeks)'
            		  WHEN LMT.CYCLE_LEN='82' THEN 'Bi-Monthly'
            		  WHEN LMT.CYCLE_LEN='83' THEN 'Monthly'
            		  WHEN LMT.CYCLE_LEN='84' THEN 'Quarterly'
            		  WHEN LMT.CYCLE_LEN='85' THEN 'Bi-Yearly'
            		  WHEN LMT.CYCLE_LEN='86' THEN 'Yearly'else 'not matched' END AS CYCLE_LEN
            	,LMT.CYCLE_BEGIN
            	,CASE WHEN LMT.CASHLIM_AMT=0 THEN PLMT.CASHLIM_AMT ELSE LMT.CASHLIM_AMT END AS	CSH_AMT
            	,CASE WHEN LMT.CASHLIM_NUM=0 THEN PLMT.CASHLIM_NUM ELSE LMT.CASHLIM_NUM END AS	CSH_TRX
            	,CASE WHEN LMT.PURCHLIM_AMT=0 THEN PLMT.PURCHLIM_AMT ELSE LMT.PURCHLIM_AMT END AS	PURCH_AMT
            	,CASE WHEN LMT.PURCHLIM_NUM=0 THEN PLMT.PURCHLIM_NUM ELSE LMT.PURCHLIM_NUM END AS	PURCH_TRX
            	,CASE WHEN LMT.TOTLIM_AMT=0 THEN PLMT.TOTLIM_AMT ELSE LMT.TOTLIM_AMT END AS	TOT_PURCH_AMT
            	,CASE WHEN LMT.TOTLIM_NUM=0 THEN PLMT.TOTLIM_NUM ELSE LMT.TOTLIM_NUM END AS	TOT_PURCH_TRX
            	,PLMT.VIP_MUL
            	,LMT.CASH_AMT_TD		AS	CSH_AMT_TD
            	,LMT.CASH_NUM_TD		AS	CSH_NUM_TD
            	,LMT.PURCH_AMT_TD
            	,LMT.PURCH_NUM_TD
            --  ,md5(LMT.CRDDET_ID) as hash_key
               ,md5(concat(PRD.ID				
            	,PLMT.LIMIT_TXNS	
            	,CASE WHEN LMT.CYCLE_LEN='0'  THEN 'None'
            		  WHEN LMT.CYCLE_LEN='80' THEN 'Weekly'
            		  WHEN LMT.CYCLE_LEN='81' THEN 'Fortnightly (every 2 weeks)'
            		  WHEN LMT.CYCLE_LEN='82' THEN 'Bi-Monthly'
            		  WHEN LMT.CYCLE_LEN='83' THEN 'Monthly'
            		  WHEN LMT.CYCLE_LEN='84' THEN 'Quarterly'
            		  WHEN LMT.CYCLE_LEN='85' THEN 'Bi-Yearly'
            		  WHEN LMT.CYCLE_LEN='86' THEN 'Yearly' else 'not matched' END 
            	,LMT.CYCLE_BEGIN
            	,CASE WHEN LMT.CASHLIM_AMT=0 THEN PLMT.CASHLIM_AMT ELSE LMT.CASHLIM_AMT END 
            	,CASE WHEN LMT.CASHLIM_NUM=0 THEN PLMT.CASHLIM_NUM ELSE LMT.CASHLIM_NUM END 
            	,CASE WHEN LMT.PURCHLIM_AMT=0 THEN PLMT.PURCHLIM_AMT ELSE LMT.PURCHLIM_AMT END 
            	,CASE WHEN LMT.PURCHLIM_NUM=0 THEN PLMT.PURCHLIM_NUM ELSE LMT.PURCHLIM_NUM END 
            	,CASE WHEN LMT.TOTLIM_AMT=0 THEN PLMT.TOTLIM_AMT ELSE LMT.TOTLIM_AMT END 
            	,CASE WHEN LMT.TOTLIM_NUM=0 THEN PLMT.TOTLIM_NUM ELSE LMT.TOTLIM_NUM END 
            	,PLMT.VIP_MUL
            	,LMT.CASH_AMT_TD	
            	,LMT.CASH_NUM_TD	
            	,LMT.PURCH_AMT_TD
            	,LMT.PURCH_NUM_TD)) as hash_key
              
            FROM ${stg_schema}.CRDLIMIT LMT 
            INNER JOIN ${stg_schema}.CRDDET CRD
            	ON CRD.ID = LMT.CRDDET_ID
            INNER JOIN ${stg_schema}.CRDPRODUCT PRD 
            	ON CRD.CRDPRODUCT_ID = PRD.ID
            INNER JOIN ${stg_schema}.CRDPRODLIM PLMT
            	ON	PRD.ID = PLMT.CRDPRODUCT_ID) as stg
            
            right join 
            
            (select * from  ${mod_schema}.${filename} where end_dttm is null )as mod
            
            on  stg.hash_key =mod.hash_key and stg.CRD_KEY =mod.CRD_KEY
            where   stg.CRD_KEY is null
        ) BUS_QRY
    ) HASH_PREP
) FINAL WHERE FK_UP <> 1
