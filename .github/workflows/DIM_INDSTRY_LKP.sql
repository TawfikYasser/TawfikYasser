SELECT COUNT(*) FROM (
    SELECT hash_prep.*,
        CASE WHEN HASH_PREP.HASH_KEY = FIRST_VALUE(HASH_PREP.HASH_KEY) OVER(
            PARTITION BY HASH_PREP.INDSTRY_KEY ORDER BY HASH_PREP.strt_dt ASC
            ROWS BETWEEN 1 PRECEDING AND 1 PRECEDING)
        THEN 1 ELSE 0 END AS FK_UP
    FROM (
        SELECT BUS_QRY.*,
            sha2(
coalesce(INDSTRY_DESCR, '')
            , 256) AS HASH_KEY
        FROM (
            Select 
            INDSTRY_KEY
            ,INDSTRY_DESCR
            ,STRT_DT
             
            FROM 
            (
            	Select 
            	k_entityid as Indstry_key
            	,cast(from_unixtime(cast(CAST(k_processingtime as BIGINT) / 1000 as int), "yyyy-MM-dd") AS DATE) as STRT_DT
            	,description as Indstry_descr
            	,ROW_NUMBER() OVER (PARTITION BY K_ENTITYID ORDER BY K_PROCESSINGTIME desc) AS RNK
            
            	From ${stg_schema}.fodb_industry_description
            	WHERE Case WHEN context_cobdate in ('','null') or context_cobdate is Null THEN context_bankingdate ELSE context_cobdate END  BETWEEN '${strt_dt}' and '${end_dt}'
            		
            )INDSTRY
            WHERE RNK = 1
        ) BUS_QRY
    ) HASH_PREP
) FINAL WHERE FK_UP <> 1
