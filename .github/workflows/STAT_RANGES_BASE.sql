SELECT COUNT(*) FROM (
    SELECT hash_prep.*,
        CASE WHEN HASH_PREP.HASH_KEY = FIRST_VALUE(HASH_PREP.HASH_KEY) OVER(
            PARTITION BY HASH_PREP.RNG_KEY, HASH_PREP.Asst_Val ORDER BY HASH_PREP.strt_dt ASC
            ROWS BETWEEN 1 PRECEDING AND 1 PRECEDING)
        THEN 1 ELSE 0 END AS FK_UP
    FROM (
        SELECT BUS_QRY.*,
            sha2(
coalesce(Strt_Rng, '') ||
coalesce(END_RNG, '') ||
coalesce(DESCR, '') ||
coalesce(APP_KEY, '') ||
coalesce(Consol_fld, '') ||
coalesce(Typ, '')
            , 256) AS HASH_KEY
        FROM (
            
                                  SELECT 
                                    STAT_RNG.k_entityid As RNG_KEY 
                                    --PK
                                    , 
                                    CASE WHEN startrange RLIKE '^[0-9]+$' THEN 'NA' ELSE startrange END AS Asst_Val 
                                    --PK
                                    , 
                                    -- CASE WHEN startrange RLIKE '^[0-9]+$' THEN startrange ELSE NULL END AS Strt_Rng, 
                                    CAST(CASE WHEN startrange RLIKE '^[0-9]+$' THEN startrange ELSE NULL END AS int) AS Strt_Rng,
                                    CAST(END_RNG AS int) as END_RNG, 
                                    DESCR, 
                                    APP_KEY, 
                                    consolfield as Consol_fld, 
                                    CASE WHEN consolfield in ('CATEGORY', 'ASSET.TYPE') then 'ASST' ELSE 'PRFT' END Typ, 
                                    CAST(STAT_RNG.COB_DT AS DATE) as strt_dt 
                                  FROM 
                                    (
                                      SELECT 
                                        * 
                                      From 
                                        (
                                          SELECT 
                                            k_entityid, 
                                            CASE WHEN applicid IN ('', 'null') then null else applicid End As App_Key, 
                                            CASE WHEN endrange IN ('', 'null') then null else endrange End AS END_RNG, 
                                            from_unixtime(
                                              unix_timestamp(
                                                CASE WHEN context_cobdate in('', 'null') 
                                                or context_cobdate is null THEN context_bankingdate ELSE context_cobdate END, 
                                                'yyyyMMdd'
                                              ), 
                                              'yyyy-MM-dd'
                                            ) as COB_DT, 
                                            RANK() OVER(
                                              PARTITION BY k_entityid, 
                                              CASE WHEN context_cobdate in('', 'null') 
                                              or context_cobdate is null THEN context_bankingdate ELSE context_cobdate END 
                                              ORDER BY 
                                                k_processingtime DESC
                                            ) RNK 
                                          FROM 
                                            stg_t24.f_re_stat_range 
                                          WHERE 
                                            from_unixtime(
                                              unix_timestamp(
                                                CASE WHEN context_cobdate in('', 'null') 
                                                or context_cobdate is null THEN context_bankingdate ELSE context_cobdate END, 
                                                'yyyyMMdd'
                                              ), 
                                              'yyyy-MM-dd'
                                            ) BETWEEN '${STRT_DT}' 
                                            and '${END_DT}'
                                        ) rsr 
                                      WHERE 
                                        RNK = 1
                                    ) STAT_RNG 
                                    LEFT JOIN (
                                      SELECT 
                                        *, 
                                        COALESCE(
                                          DATE_ADD(
                                            LEAD(strt_dt) OVER (
                                              PARTITION BY k_entityid 
                                              order by 
                                                strt_dt
                                            ), 
                                            -1
                                          ), 
                                          DATE '2999-12-31'
                                        ) AS end_dt 
                                      FROM 
                                        (
                                          SELECT 
                                            k_entityid, 
                                            description AS DESCR, 
                                            from_unixtime(
                                              unix_timestamp(
                                                CASE WHEN context_cobdate in('', 'null') 
                                                or context_cobdate is null THEN context_bankingdate ELSE context_cobdate END, 
                                                'yyyyMMdd'
                                              ), 
                                              'yyyy-MM-dd'
                                            ) as STRT_DT, 
                                            RANK() OVER(
                                              PARTITION BY k_entityid, 
                                              CASE WHEN context_cobdate in('', 'null') 
                                              or context_cobdate is null THEN context_bankingdate ELSE context_cobdate END 
                                              ORDER BY 
                                                k_processingtime DESC
                                            ) RNK 
                                          FROM 
                                            stg_t24.f_re_stat_range_description
                                        ) RSR_DESCR 
                                      WHERE 
                                        RNK = 1
                                    ) RNG_DESCR ON RNG_DESCR.k_entityid = STAT_RNG.k_entityid 
                                    and STAT_RNG.COB_DT BETWEEN RNG_DESCR.STRT_DT 
                                    AND RNG_DESCR.END_DT 
                                    LEFT JOIN (
                                      SELECT 
                                        *, 
                                        COALESCE(
                                          DATE_ADD(
                                            LEAD(strt_dt) OVER (
                                              PARTITION BY k_entityid 
                                              order by 
                                                strt_dt
                                            ), 
                                            -1
                                          ), 
                                          DATE '2999-12-31'
                                        ) AS end_dt 
                                      FROM 
                                        (
                                          SELECT 
                                            k_entityid, 
                                            consolfield, 
                                            from_unixtime(
                                              unix_timestamp(
                                                CASE WHEN context_cobdate in('', 'null') 
                                                or context_cobdate is null THEN context_bankingdate ELSE context_cobdate END, 
                                                'yyyyMMdd'
                                              ), 
                                              'yyyy-MM-dd'
                                            ) as STRT_DT, 
                                            RANK() OVER(
                                              PARTITION BY k_entityid, 
                                              CASE WHEN context_cobdate in('', 'null') 
                                              or context_cobdate is null THEN context_bankingdate ELSE context_cobdate END 
                                              ORDER BY 
                                                k_processingtime DESC
                                            ) RNK 
                                          FROM 
                                            stg_t24.f_re_stat_range_consolfield
                                        ) RSR_DESCR 
                                      WHERE 
                                        RNK = 1
                                    ) RNG_CONSOL ON RNG_CONSOL.k_entityid = STAT_RNG.k_entityid 
                                    and STAT_RNG.COB_DT BETWEEN RNG_CONSOL.STRT_DT 
                                    AND RNG_CONSOL.END_DT 
                                    LEFT JOIN (
                                      SELECT 
                                        *, 
                                        COALESCE(
                                          DATE_ADD(
                                            LEAD(strt_dt) OVER (
                                              PARTITION BY k_entityid, 
                                              rec_index 
                                              order by 
                                                strt_dt
                                            ), 
                                            -1
                                          ), 
                                          DATE '2999-12-31'
                                        ) AS end_dt 
                                      FROM 
                                        (
                                          SELECT 
                                            distinct k_entityid, 
                                            rec_index, 
                                            startrange, 
                                            from_unixtime(
                                              unix_timestamp(
                                                CASE WHEN context_cobdate in('', 'null') 
                                                or context_cobdate is null THEN context_bankingdate ELSE context_cobdate END, 
                                                'yyyyMMdd'
                                              ), 
                                              'yyyy-MM-dd'
                                            ) as STRT_DT, 
                                            RANK() OVER(
                                              PARTITION BY k_entityid, 
                                              rec_index, 
                                              CASE WHEN context_cobdate in('', 'null') 
                                              or context_cobdate is null THEN context_bankingdate ELSE context_cobdate END 
                                              ORDER BY 
                                                k_processingtime DESC
                                            ) RNK 
                                          FROM 
                                            stg_t24.f_re_stat_range_startrange
                                        ) RSR_DESCR 
                                      WHERE 
                                        RNK = 1
                                    ) RNG ON RNG.k_entityid = STAT_RNG.k_entityid 
                                    and STAT_RNG.COB_DT BETWEEN RNG.STRT_DT 
                                    AND RNG.END_DT
        ) BUS_QRY
    ) HASH_PREP
) FINAL WHERE FK_UP <> 1
