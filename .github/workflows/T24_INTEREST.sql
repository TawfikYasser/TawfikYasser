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
coalesce(interest_descr, '') ||
coalesce(interest_activity, '') ||
coalesce(interest_rate, '') ||
coalesce(interest_amount, '') ||
coalesce(margin_rate, '')
            , 256) AS HASH_KEY
        FROM (
            select stg.* ,mod.HASH_KEY as old_hash_key,null as end_dT,
               CURRENT_DATE   AS  strt_dt,
               CURRENT_TIMESTAMP	AS	STRT_DTTM
                 ,CURRENT_TIMESTAMP                          AS  Tec_Insrt_Dttm
            		   ,CURRENT_TIMESTAMP                          AS  Tec_Upd_Dttm
            		   ,null                          AS  DR_Dttm
            		   ,null                          AS  DR_Flg
            
            from
            ( 
            SELECT 
            A.*, sha2(coalesce(Arrangment_Number,'')||coalesce(interest_descr,'')||coalesce(interest_activity,'')||coalesce(interest_rate,'')||coalesce(interest_amount,'')
            ||coalesce(interest_date,'')||coalesce(margin_rate,''), 256) HASH_KEY
            
            from (select 
            recid Account_Number,
            arrangementid Arrangment_Number,
            intrst_descr as interest_descr,
            intrst_activity as interest_activity,
            interest_rate,
            accrualamt as interest_amount,
            interest_date,
            margin_rate
            
            from 
            (SELECT
            *
            FROM
            ( select recid ,arrangementid , row_number()over(PARTITION BY recid ORDER BY k_processingtime DESC) r 
            From ${stg_schema}.fodb_account a
            ) a where r=1 ) a
             join (
            SELECT distinct * FROM (
            SELECT
            EFFECTIVERATE Interest_Rate,
            idcomp_d_1 K_ENTITYID,
            idcomp_d_2 intrst_descr,
            accrualamt,
            activity intrst_activity,
            cast(regexp_replace(substring(substring(b.k_entityid, 1, instr(b.k_entityid, '.') - 1), -8), '(\\d{4})(\\d{2})(\\d{2})' , '$\1-\$2-\$3') as date) interest_date,
            CAST(substring(b.k_entityid, instr(b.k_entityid, '.') + 1) AS FLOAT),
            case when c.marginrate in ('','null') then null else c.marginrate end margin_rate,
            ROW_NUMBER () OVER (PARTITION BY idcomp_d_1 , idcomp_d_2 ORDER BY substring(substring(b.k_entityid, 1, instr(b.k_entityid, '.') - 1), -8) DESC,
            CAST(substring(b.k_entityid, instr(b.k_entityid, '.') + 1) AS FLOAT) DESC,
            B.K_EMITTEDTIME DESC) R
            FROM ${stg_schema}.fodb_aa_arr_interest a
            INNER JOIN ${stg_schema}.fodb_aa_arr_interest_fixedrate b
            ON a.recid = b.recid AND a.k_eventid = b.k_eventid
            AND a.context_cobdate = b.context_cobdate
            AND a.context_bankingdate = b.context_bankingdate
            
            join ${stg_schema}.fodb_aa_arr_interest_fixedrate_margintype c
            ON a.recid = c.recid AND a.k_eventid = c.k_eventid
            AND a.context_cobdate = c.context_cobdate
            AND a.context_bankingdate = c.context_bankingdate
            
            join ${stg_schema}.fodb_aa_interest_accruals_fromdate_accrualamt  d
            ON CONCAT(substring(a.k_entityid,1,instr(a.k_entityid,'-')-1),'-',SUBSTRING( substring(a.k_entityid,instr(a.k_entityid,'-')+1),1,instr(substring(a.k_entityid,instr(a.k_entityid,'-')+1),'-')-1)) = d.recid
            AND a.k_eventid = d.k_eventid
            AND a.context_cobdate = d.context_cobdate
            AND a.context_bankingdate = d.context_bankingdate
            
            where idcomp_d_2 is not null 
            ) d WHERE R = 1
            ) intr_rt
            on a.arrangementid = intr_rt.K_ENTITYID
            ) A 
            ) as stg
            LEFT JOIN ${mod_schema}.${table_name}   mod
            on  stg.hash_key  =mod.hash_key  and stg.Account_Number = mod.Account_Number
              
            where  mod.Account_Number is  null and MOD.end_dt is  null 
            
            union 
            
            select stg.*,mod.HASH_KEY as old_hash_key,null as end_dT,
               CURRENT_DATE   AS  strt_dt,
               CURRENT_TIMESTAMP	AS	STRT_DTTM
                 ,CURRENT_TIMESTAMP                          AS  Tec_Insrt_Dttm
            		   ,CURRENT_TIMESTAMP                          AS  Tec_Upd_Dttm
            		   ,null                          AS  DR_Dttm
            		   ,null                          AS  DR_Flg
               
            from
            ( 
            SELECT 
            A.*, sha2(coalesce(Arrangment_Number,'')||coalesce(interest_descr,'')||coalesce(interest_activity,'')||coalesce(interest_rate,'')||coalesce(interest_amount,'')
            ||coalesce(interest_date,'')||coalesce(margin_rate,''), 256) HASH_KEY
            
            from (select 
            recid Account_Number,
            arrangementid Arrangment_Number,
            intrst_descr as interest_descr,
            intrst_activity as interest_activity,
            interest_rate,
            accrualamt as interest_amount,
            interest_date,
            margin_rate
            
            from 
            (SELECT
            *
            FROM
            ( select recid ,arrangementid , row_number()over(PARTITION BY recid ORDER BY k_processingtime DESC) r 
            From ${stg_schema}.fodb_account a
            ) a where r=1 ) a
             join (
            SELECT distinct * FROM (
            SELECT
            EFFECTIVERATE Interest_Rate,
            idcomp_d_1 K_ENTITYID,
            idcomp_d_2 intrst_descr,
            accrualamt,
            activity intrst_activity,
            cast(regexp_replace(substring(substring(b.k_entityid, 1, instr(b.k_entityid, '.') - 1), -8), '(\\d{4})(\\d{2})(\\d{2})' , '$\1-\$2-\$3') as date) interest_date,
            CAST(substring(b.k_entityid, instr(b.k_entityid, '.') + 1) AS FLOAT),
            case when c.marginrate in ('','null') then null else c.marginrate end margin_rate,
            ROW_NUMBER () OVER (PARTITION BY idcomp_d_1 , idcomp_d_2 ORDER BY substring(substring(b.k_entityid, 1, instr(b.k_entityid, '.') - 1), -8) DESC,
            CAST(substring(b.k_entityid, instr(b.k_entityid, '.') + 1) AS FLOAT) DESC,
            B.K_EMITTEDTIME DESC) R
            FROM ${stg_schema}.fodb_aa_arr_interest a
            INNER JOIN ${stg_schema}.fodb_aa_arr_interest_fixedrate b
            ON a.recid = b.recid AND a.k_eventid = b.k_eventid
            AND a.context_cobdate = b.context_cobdate
            AND a.context_bankingdate = b.context_bankingdate
            
            join ${stg_schema}.fodb_aa_arr_interest_fixedrate_margintype c
            ON a.recid = c.recid AND a.k_eventid = c.k_eventid
            AND a.context_cobdate = c.context_cobdate
            AND a.context_bankingdate = c.context_bankingdate
            
            join ${stg_schema}.fodb_aa_interest_accruals_fromdate_accrualamt  d
            ON CONCAT(substring(a.k_entityid,1,instr(a.k_entityid,'-')-1),'-',SUBSTRING( substring(a.k_entityid,instr(a.k_entityid,'-')+1),1,instr(substring(a.k_entityid,instr(a.k_entityid,'-')+1),'-')-1)) = d.recid
            AND a.k_eventid = d.k_eventid
            AND a.context_cobdate = d.context_cobdate
            AND a.context_bankingdate = d.context_bankingdate
            where idcomp_d_2 is not null 
            ) d WHERE R = 1
            ) intr_rt
            on a.arrangementid = intr_rt.K_ENTITYID
            ) A 
            ) as stg
            right JOIN ${mod_schema}.${table_name}  mod
            on  stg.hash_key  =mod.hash_key  and stg.Account_Number = mod.Account_Number
            where  stg.Account_Number  is  null and   MOD.end_dt is  null
        ) BUS_QRY
    ) HASH_PREP
) FINAL WHERE FK_UP <> 1
