SELECT COUNT(*) FROM (
    SELECT hash_prep.*,
        CASE WHEN HASH_PREP.HASH_KEY = FIRST_VALUE(HASH_PREP.HASH_KEY) OVER(
            PARTITION BY HASH_PREP.lmt_key, HASH_PREP.rec_index ORDER BY HASH_PREP.strt_dt ASC
            ROWS BETWEEN 1 PRECEDING AND 1 PRECEDING)
        THEN 1 ELSE 0 END AS FK_UP
    FROM (
        SELECT BUS_QRY.*,
            sha2(
coalesce(cust_key, '')
            , 256) AS HASH_KEY
        FROM (
            
            SELECT
                k_entityid as lmt_key,
                rec_index,
                customernumber as cust_key,
                from_unixtime(unix_timestamp(CASE WHEN context_cobdate IN ('','null') OR context_cobdate IS NULL THEN context_bankingdate ELSE context_cobdate END ,'yyyyMMdd'),'yyyy-MM-dd') AS strt_dt
            FROM (
                SELECT
                    k_entityid,
                    rec_index,
                    customernumber,
                    context_cobdate,
                    context_bankingdate,
                    ROW_NUMBER() OVER (
                        PARTITION BY k_entityid, rec_index, CASE WHEN context_cobdate IN ('','null') OR context_cobdate IS NULL THEN context_bankingdate ELSE context_cobdate END 
                        ORDER BY k_processingtime DESC
                    ) AS RNK
                FROM STG_T24.fodb_limit_customernumber
                WHERE from_unixtime(unix_timestamp(CASE WHEN context_cobdate IN ('', 'null') OR context_cobdate IS NULL THEN context_bankingdate ELSE context_cobdate END ,'yyyyMMdd'),'yyyy-MM-dd') BETWEEN '${strt_dt}' AND '${end_dt}'
            ) Lmt_cust
            WHERE RNK = 1
        ) BUS_QRY
    ) HASH_PREP
) FINAL WHERE FK_UP <> 1
