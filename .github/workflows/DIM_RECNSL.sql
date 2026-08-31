SELECT COUNT(*) FROM (
    SELECT hash_prep.*,
        CASE WHEN HASH_PREP.HASH_KEY = FIRST_VALUE(HASH_PREP.HASH_KEY) OVER(
            PARTITION BY HASH_PREP.ACCT_KEY ORDER BY HASH_PREP.strt_dt ASC
            ROWS BETWEEN 1 PRECEDING AND 1 PRECEDING)
        THEN 1 ELSE 0 END AS FK_UP
    FROM (
        SELECT BUS_QRY.*,
            sha2(
coalesce(Consl_key, '') ||
coalesce(tec_sts, '')
            , 256) AS HASH_KEY
        FROM (
            
            
            SELECT
            ACCT_KEY AS ACCT_KEY  --KEY 
            ,Consl_key
            ,cob_dt as strt_dt
            ,tec_sts
            FROM 
            
            (
            
            	SELECT * 
            	FROM 
            	(
            		SELECT
            
            		Applid as acct_key
            		,SPLIT(k_entityid, ";")[0] AS consl_key
            		,from_unixtime(unix_timestamp(case when context_cobdate in ('','null') OR context_cobdate IS NULL then context_bankingdate else context_cobdate end ,'yyyyMMdd'),'yyyy-MM-dd') COB_DT	
            		,ROW_NUMBER () over (Partition by SPLIT(k_entityid, ";")[0], Applid, case when context_cobdate in ('','null') OR context_cobdate IS NULL then context_bankingdate else context_cobdate end order by k_processingtime DESC ) AS RNK
            		,CASE WHEN context_operation = 'WRITE' THEN 'Active' ELSE 'Deleted' end as TEC_STS
            
            		FROM STG_T24.fodb_re_consol_contract_applid
            		WHERE from_unixtime(unix_timestamp(case when context_cobdate in ('','null') OR context_cobdate IS NULL then context_bankingdate else context_cobdate end ,'yyyyMMdd'),'yyyy-MM-dd') 
            			between  '${strt_dt}'  and  '${end_dt}'
                )RECNSL
            	WHERE RNK = 1
            )BASE
        ) BUS_QRY
    ) HASH_PREP
) FINAL WHERE FK_UP <> 1
