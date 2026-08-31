SELECT COUNT(*) FROM (
    SELECT hash_prep.*,
        CASE WHEN HASH_PREP.HASH_KEY = FIRST_VALUE(HASH_PREP.HASH_KEY) OVER(
            PARTITION BY HASH_PREP.ARRANGEMENT_NO ORDER BY HASH_PREP.strt_dt ASC
            ROWS BETWEEN 1 PRECEDING AND 1 PRECEDING)
        THEN 1 ELSE 0 END AS FK_UP
    FROM (
        SELECT BUS_QRY.*,
            sha2(
coalesce(ACCT_REF, '') ||
coalesce(DRMNCY_STS, '')
            , 256) AS HASH_KEY
        FROM (
            SELECT DISTINCT
            ACCTS_DRMNCY.k_entityid AS ARRANGEMENT_NO
            ,ACCT.linkedapplid AS ACCT_REF
            ,ACCTS_DRMNCY.DRMNCY_DT
            ,ACCTS_DRMNCY.DRMNCY_STS
            ,cast(current_timestamp as string) as tec_insrt_dttm		
            	,cast(current_timestamp as string) as tec_upd_dttm		
            	,null as dr_dttm		
            	,null as dr_flg
            
            FROM
            (
               SELECT *
               FROM
               (
            		SELECT
            		k_entityid
            		,DORMANCYSTATUS AS DRMNCY_STS
            		,from_unixtime(unix_timestamp(DORMANCYDATE ,'yyyyMMdd'),'yyyy-MM-dd')  AS DRMNCY_DT
            		,ROW_NUMBER() over (partition by k_entityid ORDER BY DORMANCYDATE DESC) RNK
            		
            	 FROM stg_t24.fodb_aa_account_details_dormancystatus
            	WHERE DORMANCYSTATUS = 'INACTIVE' 
            	and cast(regexp_replace( (case WHEN context_cobdate = 'null' THEN context_bankingdate WHEN context_cobdate is null THEN context_bankingdate when context_cobdate = '' then context_bankingdate else context_cobdate END),  '(\\d{4})(\\d{2})(\\d{2})' ,  '$\1-\$2-\$3') as date) = CAST(date_SUB(CURRENT_TIMESTAMP(),1) AS DATE)
            
            	)DRMNCY
            	WHERE DRMNCY.RNK = 1
            )ACCTS_DRMNCY
             
            LEFT JOIN
            (
            	SELECT k_entityid
            	,linkedapplid				
            	
            	FROM stg_t24.FODB_AA_ARRANGEMENT_LINKEDAPPL
            )ACCT
            ON ACCT.k_entityid = ACCTS_DRMNCY.k_entityid
        ) BUS_QRY
    ) HASH_PREP
) FINAL WHERE FK_UP <> 1
