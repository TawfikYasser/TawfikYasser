SELECT COUNT(*) FROM (
    SELECT hash_prep.*,
        CASE WHEN HASH_PREP.HASH_KEY = FIRST_VALUE(HASH_PREP.HASH_KEY) OVER(
            PARTITION BY HASH_PREP.account_number ORDER BY HASH_PREP.strt_dt ASC
            ROWS BETWEEN 1 PRECEDING AND 1 PRECEDING)
        THEN 1 ELSE 0 END AS FK_UP
    FROM (
        SELECT BUS_QRY.*,
            sha2(
coalesce(resr_ID, '') ||
coalesce(enddt, '') ||
coalesce(startdt, '')
            , 256) AS HASH_KEY
        FROM (
            select 
            stg.*, 
            mod.HashCode as old_hash_key, 
            null as enddt, 
            CURRENT_TIMESTAMP AS startdt, 
            cast(current_timestamp as string) as tec_insrt_dttm, 
            cast(current_timestamp as string) as tec_upd_dttm, 
            null as dr_dttm, 
            null as dr_flg 
            from 
            (
                SELECT 
                BASE.*, 
                sha2(
                    COALESCE(base.account_number, '') || COALESCE(BASE.resr_ID, ''), 
                    256
                ) HASHCODE 
                from 
                (
                    select 
                    acc.recid account_number, 
                    postres.postingrestrict as resr_ID 
                    from 
                    (
                        select 
                        k_emittedtime, 
                        recid 
                        from 
                        (
                            select 
                            k_emittedtime, 
                            recid, 
                            row_number() over(
                                partition by recid 
                                order by 
                                k_emittedtime desc
                            ) rn 
                            from 
                            ${stg_schema}.fodb_account
                        ) dup 
                        where 
                        dup.rn = 1
                    ) as acc 
                    left join ${stg_schema}.fodb_account_postingrestrict as postres on postres.recid = acc.recid 
                    and postres.k_emittedtime = acc.k_emittedtime
                ) BASE
            ) as stg 
            LEFT JOIN ${mod_schema}.${table_name} mod on stg.HashCode = mod.HashCode 
            and stg.account_number = mod.account_number 
            AND MOD.ENDDT is null 
            where 
            mod.account_number is null 
            union 
            select 
            stg.*, 
            mod.HashCode as old_hash_key, 
            null as enddt, 
            CURRENT_TIMESTAMP AS startdt, 
            cast(current_timestamp as string) as tec_insrt_dttm, 
            null as tec_upd_dttm, 
            null as dr_dttm, 
            null as dr_flg 
            from 
            (
                SELECT 
                BASE.*, 
                sha2(
                    COALESCE(base.account_number, '') || COALESCE(BASE.resr_ID, ''), 
                    256
                ) HASHCODE 
                from 
                (
                    select 
                    acc.recid account_number, 
                    postres.postingrestrict as resr_ID 
                    from 
                    (
                        select 
                        k_emittedtime, 
                        recid 
                        from 
                        (
                            select 
                            k_emittedtime, 
                            recid, 
                            row_number() over(
                                partition by recid 
                                order by 
                                k_emittedtime desc
                            ) rn 
                            from 
                            ${stg_schema}.fodb_account
                        ) dup 
                        where 
                        dup.rn = 1
                    ) as acc 
                    left join ${stg_schema}.fodb_account_postingrestrict as postres on postres.recid = acc.recid 
                    and postres.k_emittedtime = acc.k_emittedtime
                ) BASE
            ) as stg 
            right JOIN ${mod_schema}.${table_name} mod on stg.HashCode = mod.HashCode 
            and stg.account_number = mod.account_number 
            AND MOD.ENDDT is null 
            where 
            stg.account_number is null
        ) BUS_QRY
    ) HASH_PREP
) FINAL WHERE FK_UP <> 1
