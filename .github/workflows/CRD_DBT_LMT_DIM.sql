SELECT COUNT(*) FROM (
    SELECT hash_prep.*,
        CASE WHEN HASH_PREP.HASH_KEY = FIRST_VALUE(HASH_PREP.HASH_KEY) OVER(
            PARTITION BY HASH_PREP.CRD_PRD_KEY ORDER BY HASH_PREP.strt_dt ASC
            ROWS BETWEEN 1 PRECEDING AND 1 PRECEDING)
        THEN 1 ELSE 0 END AS FK_UP
    FROM (
        SELECT BUS_QRY.*,
            sha2(
coalesce(TRX_CD, '') ||
coalesce(CYCLE_LEN, '') ||
coalesce(CSH_AMT, '') ||
coalesce(CSH_TRX, '') ||
coalesce(PURCH_AMT, '') ||
coalesce(PURCH_TRX, '') ||
coalesce(TOT_PURCH_AMT, '') ||
coalesce(TOT_PURCH_TRX, '') ||
coalesce(VIP_MUL, '')
            , 256) AS HASH_KEY
        FROM (
            select stg.* ,mod.hash_key as old_hash_key
            ,current_timestamp as ins_dttm ,null as end_dttm ,current_timestamp as  strt_dttm,current_date as strt_dt
            ,CURRENT_TIMESTAMP                          AS  Tec_Insrt_Dttm
            		   ,CURRENT_TIMESTAMP                          AS  Tec_Upd_Dttm
            		   ,null                          AS  DR_Dttm
            		   ,null                          AS  DR_Flg
            from
            ( 
            SELECT 
            	PLMT.CRDPRODUCT_ID						AS	CRD_PRD_KEY		-- PK
            	,PLMT.LIMIT_TXNS						AS	TRX_CD
            	,CASE WHEN PLMT.CYCLE_LEN='0'  THEN 'None'
            		  WHEN PLMT.CYCLE_LEN='80' THEN 'Weekly'
            		  WHEN PLMT.CYCLE_LEN='81' THEN 'Fortnightly (every 2 weeks)'
            		  WHEN PLMT.CYCLE_LEN='82' THEN 'Bi-Monthly'
            		  WHEN PLMT.CYCLE_LEN='83' THEN 'Monthly'
            		  WHEN PLMT.CYCLE_LEN='84' THEN 'Quarterly'
            		  WHEN PLMT.CYCLE_LEN='85' THEN 'Bi-Yearly'
            		  WHEN PLMT.CYCLE_LEN='86' THEN 'Yearly' END AS CYCLE_LEN
            	,PLMT.CASHLIM_AMT		AS	CSH_AMT
            	,PLMT.CASHLIM_NUM 		AS	CSH_TRX
            	,PLMT.PURCHLIM_AMT		AS	PURCH_AMT
            	,PLMT.PURCHLIM_NUM 		AS	PURCH_TRX
            	,PLMT.TOTLIM_AMT 		AS	TOT_PURCH_AMT
            	,PLMT.TOTLIM_NUM 		AS	TOT_PURCH_TRX
            	,PLMT.VIP_MUL
            	,md5(  concat(  PLMT.LIMIT_TXNS						
            	,CASE WHEN PLMT.CYCLE_LEN='0'  THEN 'None'
            		  WHEN PLMT.CYCLE_LEN='80' THEN 'Weekly'
            		  WHEN PLMT.CYCLE_LEN='81' THEN 'Fortnightly (every 2 weeks)'
            		  WHEN PLMT.CYCLE_LEN='82' THEN 'Bi-Monthly'
            		  WHEN PLMT.CYCLE_LEN='83' THEN 'Monthly'
            		  WHEN PLMT.CYCLE_LEN='84' THEN 'Quarterly'
            		  WHEN PLMT.CYCLE_LEN='85' THEN 'Bi-Yearly'
            		  WHEN PLMT.CYCLE_LEN='86' THEN 'Yearly' 
            		  else 'No Data'END 
            		  
            	,PLMT.CASHLIM_AMT		
            	,PLMT.CASHLIM_NUM 		
            	,PLMT.PURCHLIM_AMT		
            	,PLMT.PURCHLIM_NUM 		
            	,PLMT.TOTLIM_AMT 		
            	,PLMT.TOTLIM_NUM 		
            	,PLMT.VIP_MUL)) as hash_key
            
            
            FROM ${stg_schema}.CRDPRODLIM PLMT) as stg
            
            left join 
            
            ( select * from ${mod_schema}.${filename} where end_dttm is null) as mod
            
            on  stg.hash_key =mod.hash_key and stg.CRD_PRD_KEY =mod.CRD_PRD_KEY
            where  mod.CRD_PRD_KEY is null --or  stg.CRD_PRD_KEY is null
            
            union 
            
            select stg.* ,mod.hash_key as old_hash_key
            ,current_timestamp as ins_dttm ,null as end_dttm ,current_timestamp as  strt_dttm,current_date as strt_dt
            ,CURRENT_TIMESTAMP                          AS  Tec_Insrt_Dttm
            		   ,CURRENT_TIMESTAMP                          AS  Tec_Upd_Dttm
            		   ,null                          AS  DR_Dttm
            		   ,null                          AS  DR_Flg
            from
            ( 
            SELECT 
            	PLMT.CRDPRODUCT_ID						AS	CRD_PRD_KEY		-- PK
            	,PLMT.LIMIT_TXNS						AS	TRX_CD
            	,CASE WHEN PLMT.CYCLE_LEN='0'  THEN 'None'
            		  WHEN PLMT.CYCLE_LEN='80' THEN 'Weekly'
            		  WHEN PLMT.CYCLE_LEN='81' THEN 'Fortnightly (every 2 weeks)'
            		  WHEN PLMT.CYCLE_LEN='82' THEN 'Bi-Monthly'
            		  WHEN PLMT.CYCLE_LEN='83' THEN 'Monthly'
            		  WHEN PLMT.CYCLE_LEN='84' THEN 'Quarterly'
            		  WHEN PLMT.CYCLE_LEN='85' THEN 'Bi-Yearly'
            		  WHEN PLMT.CYCLE_LEN='86' THEN 'Yearly' END AS CYCLE_LEN
            	,PLMT.CASHLIM_AMT		AS	CSH_AMT
            	,PLMT.CASHLIM_NUM 		AS	CSH_TRX
            	,PLMT.PURCHLIM_AMT		AS	PURCH_AMT
            	,PLMT.PURCHLIM_NUM 		AS	PURCH_TRX
            	,PLMT.TOTLIM_AMT 		AS	TOT_PURCH_AMT
            	,PLMT.TOTLIM_NUM 		AS	TOT_PURCH_TRX
            	,PLMT.VIP_MUL
            	,md5(  concat(  PLMT.LIMIT_TXNS						
            	,CASE WHEN PLMT.CYCLE_LEN='0'  THEN 'None'
            		  WHEN PLMT.CYCLE_LEN='80' THEN 'Weekly'
            		  WHEN PLMT.CYCLE_LEN='81' THEN 'Fortnightly (every 2 weeks)'
            		  WHEN PLMT.CYCLE_LEN='82' THEN 'Bi-Monthly'
            		  WHEN PLMT.CYCLE_LEN='83' THEN 'Monthly'
            		  WHEN PLMT.CYCLE_LEN='84' THEN 'Quarterly'
            		  WHEN PLMT.CYCLE_LEN='85' THEN 'Bi-Yearly'
            		  WHEN PLMT.CYCLE_LEN='86' THEN 'Yearly' 
            		  else 'No Data'END 
            		  
            	,PLMT.CASHLIM_AMT		
            	,PLMT.CASHLIM_NUM 		
            	,PLMT.PURCHLIM_AMT		
            	,PLMT.PURCHLIM_NUM 		
            	,PLMT.TOTLIM_AMT 		
            	,PLMT.TOTLIM_NUM 		
            	,PLMT.VIP_MUL)) as hash_key
            
            
            FROM ${stg_schema}.CRDPRODLIM PLMT) as stg
            
            right join 
            
            ( select * from ${mod_schema}.${filename} where end_dttm is null) as mod
            
            on  stg.hash_key =mod.hash_key and stg.CRD_PRD_KEY =mod.CRD_PRD_KEY
            where    stg.CRD_PRD_KEY is null
        ) BUS_QRY
    ) HASH_PREP
) FINAL WHERE FK_UP <> 1
