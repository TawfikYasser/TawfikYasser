SELECT COUNT(*) FROM (
    SELECT hash_prep.*,
        CASE WHEN HASH_PREP.HASH_KEY = FIRST_VALUE(HASH_PREP.HASH_KEY) OVER(
            PARTITION BY HASH_PREP.crd_key, HASH_PREP.acct_key ORDER BY HASH_PREP.strt_dt ASC
            ROWS BETWEEN 1 PRECEDING AND 1 PRECEDING)
        THEN 1 ELSE 0 END AS FK_UP
    FROM (
        SELECT BUS_QRY.*,
            sha2(
coalesce(prio, '')
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
            select 
            	crd.crddet_id					as	crd_key				-- pk
            	,crd.accdet_id					as	acct_key			-- pk
            	,crd.priority					as	prio 
            	, md5(priority) as hash_key
            from ${stg_schema}.crdacc crd) as stg
            
            left join 
            
            (select * from ${mod_schema}.${filename}  where end_dttm is null)   as mod
            
            on  stg.hash_key =mod.hash_key and stg.CRD_KEY =mod.CRD_KEY and stg.acct_key=mod.acct_key
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
            select 
            	crd.crddet_id					as	crd_key				-- pk
            	,crd.accdet_id					as	acct_key			-- pk
            	,crd.priority					as	prio 
            	, md5(priority) as hash_key
            from ${stg_schema}.crdacc crd) as stg
            
            right join 
            
            (select * from ${mod_schema}.${filename}  where end_dttm is null)   as mod
            
            on  stg.hash_key =mod.hash_key and stg.CRD_KEY =mod.CRD_KEY and stg.acct_key=mod.acct_key
            where   stg.CRD_KEY is null
        ) BUS_QRY
    ) HASH_PREP
) FINAL WHERE FK_UP <> 1
