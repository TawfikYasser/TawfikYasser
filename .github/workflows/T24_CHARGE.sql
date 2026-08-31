SELECT COUNT(*) FROM (
    SELECT hash_prep.*,
        CASE WHEN HASH_PREP.HASH_KEY = FIRST_VALUE(HASH_PREP.HASH_KEY) OVER(
            PARTITION BY HASH_PREP.Account_Number ORDER BY HASH_PREP.strt_dt ASC
            ROWS BETWEEN 1 PRECEDING AND 1 PRECEDING)
        THEN 1 ELSE 0 END AS FK_UP
    FROM (
        SELECT BUS_QRY.*,
            sha2(
coalesce(Arrangment_Number, '') ||
coalesce(charge_activity, '') ||
coalesce(charge_descr, '') ||
coalesce(charge_rate, '') ||
coalesce(charge_Amount, '')
            , 256) AS HASH_KEY
        FROM (
            select stg.* ,mod.Hash_key as old_hash_key,null as end_dt
                       ,CURRENT_TIMESTAMP                          AS  STRT_DTTM
                       ,current_date as strt_dt
            		                ,CURRENT_TIMESTAMP                          AS  Tec_Insrt_Dttm
            		   ,CURRENT_TIMESTAMP                          AS  Tec_Upd_Dttm
            		   ,null                          AS  DR_Dttm
            		   ,null                          AS  DR_Flg
            from
            ( 
            select  
            BASE.*
            ,sha2(coalesce(Arrangment_Number,'')||coalesce(charge_activity,'')||coalesce(charge_descr,'')||coalesce(charge_rate,'')||coalesce(charge_Amount,'')
            ||coalesce(charge_date,''), 256) Hash_key
            
            from(select 
            recid Account_Number,
            arrangementid Arrangment_Number,
            chrg_activity charge_activity,
            chrg_descr charge_descr,
            charge_rate,
            chrg_amount as charge_Amount,
            charge_date
            from 
            (SELECT
            *
            FROM
            ( select recid ,arrangementid , row_number()over(PARTITION BY recid ORDER BY k_processingtime DESC) r 
            From ${stg_schema}.fodb_account a
            ) a where r=1 ) a
             join 
            (
            SELECT DISTINCT * FROM (
            SELECT
            idcomp_d_1 K_ENTITYID,
            idcomp_d_2 chrg_descr,
            activity chrg_activity,
            cast(regexp_replace(substring(substring(b.k_entityid, 1, instr(b.k_entityid, '.') - 1), -8), '(\\d{4})(\\d{2})(\\d{2})' , '$\1-\$2-\$3') as date) charge_date,
            CAST(substring(b.k_entityid, instr(b.k_entityid, '.') + 1) AS FLOAT),
            case when b.chargerate in ('','null') then null else b.chargerate end as charge_Rate,
            case when a.fixedamount in ('','null') then null else b.chargerate end as chrg_amount,
            rank() OVER (PARTITION BY idcomp_d_1 ORDER BY substring(substring(b.k_entityid, 1, instr(b.k_entityid, '.') - 1), -8) DESC,
            CAST(substring(b.k_entityid, instr(b.k_entityid, '.') + 1) AS FLOAT) DESC,
            B.K_EMITTEDTIME DESC) R
            FROM ${stg_schema}.fodb_aa_arr_charge a
            INNER JOIN ${stg_schema}.fodb_aa_arr_charge_calctiertype b
            ON a.recid = b.recid AND a.k_eventid = b.k_eventid
            AND a.context_cobdate = b.context_cobdate
            AND a.context_bankingdate = b.context_bankingdate
            where idcomp_d_2 is not null 
            ) d WHERE R = 1
            )chrg
            on a.arrangementid = chrg.K_ENTITYID
            )BASE
            )as stg
            LEFT JOIN ${mod_schema}.${table_name}  mod
            on  stg.Hash_key =mod.Hash_key and stg.Account_Number =mod.Account_Number 
            AND MOD.end_dt is  null  
            where  mod.Account_Number is  null
            
            union 
            
            select stg.* ,mod.Hash_key as old_hash_key,null as end_dt
                       ,CURRENT_TIMESTAMP                          AS  STRT_DTTM
                       ,current_date as strt_dt
            		                ,CURRENT_TIMESTAMP                          AS  Tec_Insrt_Dttm
            		   ,CURRENT_TIMESTAMP                          AS  Tec_Upd_Dttm
            		   ,null                          AS  DR_Dttm
            		   ,null                          AS  DR_Flg
            from
            ( 
            select  
            BASE.*
            ,sha2(coalesce(Arrangment_Number,'')||coalesce(charge_activity,'')||coalesce(charge_descr,'')||coalesce(charge_rate,'')||coalesce(charge_Amount,'')
            ||coalesce(charge_date,''), 256) Hash_key
            
            from(select 
            recid Account_Number,
            arrangementid Arrangment_Number,
            chrg_activity charge_activity,
            chrg_descr charge_descr,
            charge_rate,
            chrg_amount as charge_Amount,
            charge_date
            from 
            (SELECT
            *
            FROM
            ( select recid ,arrangementid , row_number()over(PARTITION BY recid ORDER BY k_processingtime DESC) r 
            From ${stg_schema}.fodb_account a
            ) a where r=1 ) a
             join 
            (
            SELECT DISTINCT * FROM (
            SELECT
            idcomp_d_1 K_ENTITYID,
            idcomp_d_2 chrg_descr,
            activity chrg_activity,
            cast(regexp_replace(substring(substring(b.k_entityid, 1, instr(b.k_entityid, '.') - 1), -8), '(\\d{4})(\\d{2})(\\d{2})' , '$\1-\$2-\$3') as date) charge_date,
            CAST(substring(b.k_entityid, instr(b.k_entityid, '.') + 1) AS FLOAT),
            case when b.chargerate in ('','null') then null else b.chargerate end as charge_Rate,
            case when a.fixedamount in ('','null') then null else b.chargerate end as chrg_amount,
            rank() OVER (PARTITION BY idcomp_d_1 ORDER BY substring(substring(b.k_entityid, 1, instr(b.k_entityid, '.') - 1), -8) DESC,
            CAST(substring(b.k_entityid, instr(b.k_entityid, '.') + 1) AS FLOAT) DESC,
            B.K_EMITTEDTIME DESC) R
            FROM ${stg_schema}.fodb_aa_arr_charge a
            INNER JOIN ${stg_schema}.fodb_aa_arr_charge_calctiertype b
            ON a.recid = b.recid AND a.k_eventid = b.k_eventid
            AND a.context_cobdate = b.context_cobdate
            AND a.context_bankingdate = b.context_bankingdate
            where idcomp_d_2 is not null 
            ) d WHERE R = 1
            )chrg
            on a.arrangementid = chrg.K_ENTITYID
            )BASE
            )as stg
            right JOIN ${mod_schema}.${table_name}  mod 
            on  stg.Hash_key =mod.Hash_key and stg.Account_Number =mod.Account_Number 
            AND MOD.end_dt is  null  
            where  stg.Account_Number is  null
        ) BUS_QRY
    ) HASH_PREP
) FINAL WHERE FK_UP <> 1
