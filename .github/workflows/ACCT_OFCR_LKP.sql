SELECT COUNT(*) FROM (
    SELECT hash_prep.*,
        CASE WHEN HASH_PREP.HASH_KEY = FIRST_VALUE(HASH_PREP.HASH_KEY) OVER(
            PARTITION BY HASH_PREP.Acct_OFCR_kEY ORDER BY HASH_PREP.strt_dt ASC
            ROWS BETWEEN 1 PRECEDING AND 1 PRECEDING)
        THEN 1 ELSE 0 END AS FK_UP
    FROM (
        SELECT BUS_QRY.*,
            sha2(
coalesce(ACCT_OFCR_NAME, '') ||
coalesce(Dept_CODE, '') ||
coalesce(Dept, '') ||
coalesce(area, '') ||
coalesce(Authrzr, '') ||
coalesce(Chnl_Key, '') ||
coalesce(Dept_Key, '')
            , 256) AS HASH_KEY
        FROM (
            Select
             
            Acct_OFCR_kEY
             
            ,ACCT_OFCR_NAME
             
            ,Dept_CODE
             
            ,Dept
             
            ,area
             
            ,Authrzr
             
            ,Chnl_Key
             
            ,Dept_Key
             
            ,STRT_DT
            
            FROM
             
            (
             
            	select
             
            	k_entityid as Acct_OFCR_kEY
             
            	,cast(from_unixtime(cast(CAST(k_processingtime as BIGINT) / 1000 as int), "yyyy-MM-dd") AS DATE) as STRT_DT
             
            	,name as ACCT_OFCR_NAME
             
            	,deptlevel as Dept_CODE
             
            	,deliverypoint as Dept
             
            	,area
             
            	,authoriser as Authrzr
             
            	,cocode as Chnl_Key
             
            	,deptcode as Dept_Key
             
            	,ROW_NUMBER() OVER (PARTITION BY K_ENTITYID ORDER BY K_PROCESSINGTIME desc) AS RNK
             
             
            	from stg_t24.f_dept_acct_officer
            
            )DEPT_ACCT_OFCR
             
            WHERE RNK = 1
        ) BUS_QRY
    ) HASH_PREP
) FINAL WHERE FK_UP <> 1
