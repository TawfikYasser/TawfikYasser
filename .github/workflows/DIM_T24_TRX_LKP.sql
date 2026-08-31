SELECT COUNT(*) FROM (
    SELECT hash_prep.*,
        CASE WHEN HASH_PREP.HASH_KEY = FIRST_VALUE(HASH_PREP.HASH_KEY) OVER(
            PARTITION BY HASH_PREP.trx_cd_key ORDER BY HASH_PREP.strt_dt ASC
            ROWS BETWEEN 1 PRECEDING AND 1 PRECEDING)
        THEN 1 ELSE 0 END AS FK_UP
    FROM (
        SELECT BUS_QRY.*,
            sha2(
coalesce(trx_typ, '') ||
coalesce(shrt_descr, '') ||
coalesce(nrtv, '') ||
coalesce(stmt_typ, '') ||
coalesce(swft_typ, '')
            , 256) AS HASH_KEY
        FROM (
            
            SELECT 
                Trx.trx_cd_key,
                trx.strt_dt,
                trx_typ,
                shrt_descr,        
                coalesce(trx_nrtv.nrtv, trx.nrtv) as nrtv,
                stmt_typ,
                swft_typ
            FROM 
            (
                SELECT *
                FROM (
                    SELECT 
                        K_entityid as trx_cd_key,
                        case when debitcreditind in ('','null') then null else debitcreditind end as trx_typ,            
                        case when shortdesc in ('','null') then null else shortdesc end as shrt_descr,
                        case when stmtnarrref in ('','null') then null else stmtnarrref end as stmt_typ,
                        case when stmtnarr in ('','null') then null else stmtnarr end as nrtv,
                        case when swiftnarrative in ('','null') then null else swiftnarrative end as swft_typ,
                        from_unixtime(unix_timestamp(case when context_cobdate in ('','null') OR context_cobdate IS NULL then context_bankingdate else context_cobdate end ,'yyyyMMdd'),'yyyy-MM-dd') AS strt_Dt,
                        RANK() OVER( PARTITION BY k_entityid, from_unixtime(unix_timestamp(case when context_cobdate in ('','null') OR context_cobdate IS NULL then context_bankingdate else context_cobdate end ,'yyyyMMdd'),'yyyy-MM-dd') ORDER BY k_processingtime DESC ) RNK 
                    FROM stg_t24.fodb_transaction
                    WHERE from_unixtime(unix_timestamp(case when context_cobdate in ('','null') OR context_cobdate IS NULL then context_bankingdate else context_cobdate end ,'yyyyMMdd'),'yyyy-MM-dd') BETWEEN '${strt_dt}' AND '${end_dt}'
                ) FODB_TRX
                WHERE RNK = 1 
            ) TRX
            LEFT JOIN
            (
                SELECT
                    *,
                    COALESCE(
                        DATE_ADD(
                            LEAD(strt_dt) OVER (PARTITION BY trx_cd_key ORDER BY strt_dt), -1
                        ), DATE '2999-12-31'
                    ) AS End_Dt
                FROM
                (
                    SELECT 
                        k_entityid AS trx_cd_key,
                        CASE WHEN narrative IN ('','null') then null else narrative End AS Nrtv,
                        from_unixtime(unix_timestamp(case when context_cobdate in ('','null') OR context_cobdate IS NULL then context_bankingdate else context_cobdate end ,'yyyyMMdd'),'yyyy-MM-dd') AS strt_Dt,
                        RANK() OVER( PARTITION BY k_entityid, from_unixtime(unix_timestamp(case when context_cobdate in ('','null') OR context_cobdate IS NULL then context_bankingdate else context_cobdate end ,'yyyyMMdd'),'yyyy-MM-dd') ORDER BY k_processingtime DESC ) RNK 
                    FROM stg_t24.fodb_transaction_narrative            
                ) NRTV
                WHERE RNK = 1
            ) TRX_NRTV 
            ON trx_nrtv.trx_cd_key = trx.trx_cd_key
            AND trx.strt_dt BETWEEN trx_nrtv.strt_dt AND trx_nrtv.end_dt
            
            UNION ALL
            
            SELECT 
                trx_cd_key, 
                strt_dt,
                cast(null as string) as trx_typ,
                shrt_descr,        
                cast(null as string) as nrtv,
                cast(null as string) as stmt_typ,
                cast(null as string) as swft_typ
            FROM 
            (
                SELECT *
                FROM (
                    SELECT 
                        K_entityid as trx_cd_key,
                        from_unixtime(unix_timestamp(case when context_cobdate in ('','null') OR context_cobdate IS NULL then context_bankingdate else context_cobdate end ,'yyyyMMdd'),'yyyy-MM-dd') AS strt_Dt,    
                        shortdesc as shrt_descr,
                        RANK() OVER( PARTITION BY k_entityid, from_unixtime(unix_timestamp(case when context_cobdate in ('','null') OR context_cobdate IS NULL then context_bankingdate else context_cobdate end ,'yyyyMMdd'),'yyyy-MM-dd') ORDER BY k_processingtime DESC ) RNK 
                    FROM stg_t24.f_re_txn_code_shortdesc
                    WHERE from_unixtime(unix_timestamp(case when context_cobdate in ('','null') OR context_cobdate IS NULL then context_bankingdate else context_cobdate end ,'yyyyMMdd'),'yyyy-MM-dd') BETWEEN '${strt_dt}' AND '${end_dt}'
                    AND rec_index = '0'
                ) Txn_descr
                WHERE RNK = 1 
            ) Txn
        ) BUS_QRY
    ) HASH_PREP
) FINAL WHERE FK_UP <> 1
