SELECT COUNT(*) FROM (
    SELECT hash_prep.*,
        CASE WHEN HASH_PREP.HASH_KEY = FIRST_VALUE(HASH_PREP.HASH_KEY) OVER(
            PARTITION BY HASH_PREP.LOAN_KEY ORDER BY HASH_PREP.strt_dt ASC
            ROWS BETWEEN 1 PRECEDING AND 1 PRECEDING)
        THEN 1 ELSE 0 END AS FK_UP
    FROM (
        SELECT BUS_QRY.*,
            sha2(
coalesce(ACCT_KEY, '') ||
coalesce(CUST_KEY, '') ||
coalesce(LOAN_DESCR, '') ||
coalesce(LOAN_TYP, '') ||
coalesce(STS, '') ||
coalesce(RVOLVNG_FLG, '') ||
coalesce(TERM, '') ||
coalesce(CCY, '') ||
coalesce(AMT, '') ||
coalesce(INT_RT, '') ||
coalesce(OS_AMT, '') ||
coalesce(month_time, '') ||
coalesce(day_time, '') ||
coalesce(PYMT_PERIOD, '') ||
coalesce(PROD_LINE, '') ||
coalesce(PROD_GRP, '') ||
coalesce(ACCT_CTGY_KEY, '') ||
coalesce(TEC_STS, '')
            , 256) AS HASH_KEY
        FROM (
            SELECT
            AA.k_entityid AS LOAN_KEY
            ,LNKD_ACCT.ACCT_KEY
            ,LNKD_CUST.CUST_KEY
            ,AA.LOAN_DESCR
            ,ACCT_TITL.LOAN_TYP
            ,AA.STS
            ,AA.VAL_DT
            ,AA_TERM.MAT_DT
            ,AA_TERM.RVOLVNG_FLG
            ,AA_TERM.TERM
            ,AA.CCY
            ,AA_TERM.AMT
            ,AA_RT.INT_RT
            ,OS_AMT
            ,COALESCE(
                    CASE UPPER(regexp_extract(term, '([A-Za-z])$', 1))
                        WHEN 'M' THEN CAST(regexp_extract(term, '(\\d+)', 1) AS DOUBLE)
                        WHEN 'Y' THEN CAST(regexp_extract(term, '(\\d+)', 1) AS DOUBLE) * 12
                        WHEN 'W' THEN CAST(regexp_extract(term, '(\\d+)', 1) AS DOUBLE) * 52.0 / 12
                        ELSE 0
                    END,
                0) AS month_time
            ,COALESCE(
                    CASE UPPER(regexp_extract(term, '([A-Za-z])$', 1))
                        WHEN 'D' THEN CAST(regexp_extract(term, '(\\d+)', 1) AS INT)
                        WHEN 'W' THEN CAST(regexp_extract(term, '(\\d+)', 1) AS INT) * 7
                        WHEN 'M' THEN CAST(regexp_extract(term, '(\\d+)', 1) AS INT) * 30
                        WHEN 'Y' THEN CAST(regexp_extract(term, '(\\d+)', 1) AS INT) * 365
                        ELSE 0
                    END,
                0) AS day_time
            
            ,Case
                When PYMT.paymentfreq like '%e1Y%' or PYMT.paymentfreq like '%e12M%' or PYMT.paymentfreq like '%eLYEARF%' then 'A'
                          When PYMT.paymentfreq like '%e1M%' or PYMT.paymentfreq like '%eLMNTHF%' then 'M'
                          When PYMT.paymentfreq like '%e3M%' or PYMT.paymentfreq like '%eLQUATF%' then 'Q'
                          When PYMT.paymentfreq like '%e6M%' then 'S'
                          When PYMT.paymentfreq like '%e1W%' then 'W'
                          When PYMT.paymentfreq like '%e2W%' then 'B'
                          When PYMT.paymentfreq like '%e1D%' or PYMT.paymentfreq like '%eBD%' then 'D'
                          When PYMT.paymentfreq = '' then 'NA'
                          
            End AS PYMT_PERIOD
            ,productline  AS PROD_LINE
            ,productgroup AS PROD_GRP
            ,ACCT_CTGY_KEY
            ,Calendar_dt  AS STRT_DT
            ,CASE WHEN AA.Context_operation = 'DELETE' THEN 'Deleted' else 'Active' end as TEC_STS
            
            --------------===========LENDING INFO===--------------
            
            
            FROM
            (             
                          SELECT Calendar_dt
                          FROM reporting_schema.calendar_base
                
                          WHERE Calendar_dt  BETWEEN '${strt_dt}' AND '${end_dt}'
            
            )BASE
            
            
            INNER JOIN
            (
                          SELECT
                          *
                          ,COALESCE(
                    DATE_ADD(
                        LEAD(strt_dt) OVER (PARTITION BY k_entityid ORDER BY strt_dt),-1
                    ),DATE '2999-12-31'
                 ) AS End_Dt
            
                FROM
                          (
                                         
                    SELECT
                                         k_entityid
                                         ,from_unixtime(unix_timestamp(case when context_cobdate in ('','null') OR context_cobdate IS NULL then context_bankingdate else context_cobdate end ,'yyyyMMdd'),'yyyy-MM-dd') AS strt_Dt
                                  ,FROM_unixtime(unix_timestamp(startdate,'yyyyMMdd'),'yyyy-MM-dd') AS VAL_DT
                                         ,currency AS CCY
                                         ,activeproduct AS LOAN_DESCR
                                         ,arrstatus AS STS
                                         ,Context_operation
                                         ,productline
                                         ,productgroup
                                         ,row_number() OVER (PARTITION BY k_entityid ORDER BY k_processingtime DESC) AS RNK
                                                         
                                                                                      
                                         FROM STG_T24.fodb_aa_arrangement
                                            
                                         WHERE PRODUCTLINE = 'LENDING'
                                         AND from_unixtime(unix_timestamp(CASE WHEN context_cobdate in('', 'null') or context_cobdate is null  THEN context_bankingdate ELSE context_cobdate END  ,'yyyyMMdd'),'yyyy-MM-dd')
                                         BETWEEN '${strt_dt}' AND '${end_dt}'
                                         
                          )AA_LOAN
                          
                          WHERE RNK = 1
            )AA
            ON  BASE.Calendar_dt BETWEEN AA.STRT_DT AND AA.END_DT
            
            
            -------------------=== ACCOUNT=====-------------------
            
            LEFT JOIN
            (
                          
                          SELECT *
                          FROM
                          (
                                         SELECT
                                         K_ENTITYID
                                         ,LINKEDAPPLID AS ACCT_KEY
                                         ,row_number() OVER (PARTITION BY k_entityid ORDER BY k_processingtime DESC) AS RNK
                                         
                                         FROM STG_T24.fodb_aa_arrangement_linkedappl
                )AA_LINKEDAPPL
                          
                          WHERE RNK = 1
            )LNKD_ACCT
            ON LNKD_ACCT.K_ENTITYID = AA.K_ENTITYID
            
            ----------------======CUSTOMER====-----------------------------
            LEFT JOIN
            (
                SELECT *
                          FROM
                          (
                                         SELECT
                                         K_ENTITYID
                                         ,CUSTOMER  AS CUST_KEY
            
                                         ,row_number() OVER (PARTITION BY k_entityid ORDER BY k_processingtime DESC) AS RNK
                                         
                                         FROM STG_T24.fodb_aa_arrangement_customer
                          )AA_CUST
                          WHERE RNK = 1
            )LNKD_CUST
            ON LNKD_CUST.K_ENTITYID = AA.K_ENTITYID
            
            -----------------=======LOAN_DESCRIPTION======-----------------------
            
            LEFT JOIN
            (
                SELECT *
                          FROM
                          (
                                         SELECT
                                         K_ENTITYID
                                         ,ACCOUNTTITLE_D_1 AS LOAN_TYP
                                         ,row_number() OVER (PARTITION BY k_entityid ORDER BY k_processingtime DESC) AS RNK
                                         
                                         FROM STG_T24.fodb_account_accounttitle_d_1
                          )ACCT_ACCOUNTTITLE
                          WHERE RNK = 1
            
            )ACCT_TITL
            ON ACCT_TITL.k_entityid = LNKD_ACCT.ACCT_KEY
            
            -----------============LOAN DATA==============--------------------------
            
            LEFT JOIN
            (
            
                          SELECT *
                          ,COALESCE(
                    DATE_ADD(
                        LEAD(strt_dt) OVER (PARTITION BY idcomp_d_1 ORDER BY strt_dt),-1
                    ),DATE '2999-12-31'
                 ) AS End_Dt
                          
                          FROM
                          (
                              SELECT
                                         
                                         idcomp_d_1
                                         ,activity
                                         ,term
                                         ,Cast(CASE WHEN TRIM(amount) IN('','null') OR amount IS NULL THEN '0.00' ELSE amount END  AS DECIMAL(18,2))  AS AMT
                                         ,changeamount
                          ,FROM_unixtime(unix_timestamp(maturitydate,'yyyyMMdd'),'yyyy-MM-dd') AS MAT_DT
                                         ,revolving  AS RVOLVNG_FLG
                                         ,from_unixtime(unix_timestamp(case when context_cobdate in ('','null') OR context_cobdate IS NULL then context_bankingdate else context_cobdate end ,'yyyyMMdd'),'yyyy-MM-dd') AS strt_Dt
                                         ,row_number() OVER (PARTITION BY idcomp_d_1 ORDER BY k_processingtime DESC) AS RNK
                                         
                                         FROM STG_T24.fodb_aa_arr_term_amount
                                         
                          
                                         
                          )ACCT_TERM
                          WHERE RNK = 1
            )AA_TERM
            on  AA_TERM.idcomp_d_1 = AA.k_entityid
            AND  BASE.Calendar_dt BETWEEN AA_TERM.STRT_DT AND AA_TERM.END_DT
            
            
            ----------=======LOAN INTEREST====------------
            
            LEFT JOIN
            (
            
                          SELECT
                          *
                          ,COALESCE(
                    DATE_ADD(
                        LEAD(strt_dt) OVER (PARTITION BY PROD_KEY, INT_TYP ,REC_INDEX  ORDER BY strt_dt),-1
                    ),DATE '2999-12-31'
                 ) AS End_Dt
                          
                          FROM
                          (
                                         SELECT
                                         K_ENTITYID
                                         ,SPLIT(k_Entityid, '-')[0] AS PROD_KEY
                    ,SPLIT(k_Entityid, '-')[1] AS INT_TYP
                    ,from_unixtime(unix_timestamp(REGEXP_REPLACE(split(K_ENTITYID, '-')[size(split(K_ENTITYID, '-')) - 1], '\\.\\d+', '')  ,'yyyyMMdd'),'yyyy-MM-dd') AS int_dt
                                         ,REC_INDEX
                                         ,from_unixtime(unix_timestamp(case when context_cobdate in ('','null') OR context_cobdate IS NULL then context_bankingdate else context_cobdate end ,'yyyyMMdd'),'yyyy-MM-dd') AS strt_Dt
                                         ,Cast(CASE WHEN TRIM(EFFECTIVERATE) IN('','null') OR EFFECTIVERATE IS NULL THEN '0.00' ELSE EFFECTIVERATE END  AS DECIMAL(6,4)) AS INT_RT
                                         ,ROW_NUMBER() OVER (PARTITION BY  SPLIT(k_Entityid, '-')[0], SPLIT(k_Entityid, '-')[1], REC_INDEX,SPLIT(rec_index, '[.]')[0], from_unixtime(unix_timestamp(REGEXP_REPLACE(split(K_ENTITYID, '-')[size(split(K_ENTITYID, '-')) - 1], '\\.\\d+', '')  ,'yyyyMMdd'),'yyyy-MM-dd') ORDER BY K_PROCESSINGTIME desc,K_ENTITYID desc) AS RNK
            
                
                                         FROM stg_t24.fodb_aa_arr_interest_fixedrate
                                         WHERE  SPLIT(k_Entityid, '-')[1] = 'PRINCIPALINT'
            --                             and from_unixtime(unix_timestamp(CASE When context_cobdate in('', 'null') or context_cobdate is null  THEN context_bankingdate ELSE context_cobdate END  ,'yyyyMMdd'),'yyyy-MM-dd')
            --                             BETWEEN '${strt_dt}' AND '${end_dt}'
            --                             
                          )AA_RT
                          
                          WHERE RNK = 1
            
            )AA_RT
            ON AA_RT.PROD_KEY = AA.K_ENTITYID
            AND BASE.Calendar_dt BETWEEN AA_RT.STRT_DT AND AA_RT.END_DT
            
            ----------===== PAYMENT PERIOD ====---------
            
            LEFT join
            
            (
                          SELECT
                          *
                          ,COALESCE(
                    DATE_ADD(
                        LEAD(strt_dt) OVER (PARTITION BY PROD_KEY ORDER BY strt_dt),-1
                    ),DATE '2999-12-31'
                 ) AS End_Dt
                          
                          FROM
                          (
                                         SELECT
                                         SPLIT(k_Entityid, '-')[0] AS PROD_KEY
                                         ,paymentfreq
                                         ,from_unixtime(unix_timestamp(case when context_cobdate in ('','null') OR context_cobdate IS NULL then context_bankingdate else context_cobdate end ,'yyyyMMdd'),'yyyy-MM-dd') AS strt_Dt
                                         ,row_number() OVER (PARTITION BY SPLIT(k_Entityid, '-')[0] ,CASE When context_cobdate in('', 'null') or context_cobdate is null  THEN context_bankingdate ELSE context_cobdate END ORDER BY K_PROCESSINGTIME desc,k_Entityid desc) AS RNK
                                         
                                         FROM STG_T24.fodb_aa_arr_payment_schedule_paymenttype
                                         where paymenttype='CONSTANT'
            --                             AND from_unixtime(unix_timestamp(CASE When context_cobdate in('', 'null') or context_cobdate is null  THEN context_bankingdate ELSE context_cobdate END  ,'yyyyMMdd'),'yyyy-MM-dd')
            --                             BETWEEN '${strt_dt}' AND '${end_dt}'
            --                             
                          )AA_PYMT
                          
                          WHERE RNK = 1
                                         
            )PYMT
            ON PYMT.PROD_KEY = AA.K_ENTITYID
            AND BASE.Calendar_dt BETWEEN PYMT.STRT_DT AND PYMT.END_DT
            
            
            LEFT join
            
            (
                          SELECT
                          *
                          ,COALESCE(
                    DATE_ADD(
                        LEAD(strt_dt) OVER (PARTITION BY ACCT_KEY  ORDER BY strt_dt),-1
                    ),DATE '2999-12-31'
                 ) AS End_Dt
                          FROM
                          (
                                         SELECT
                                         k_entityid AS ACCT_KEY
                                         ,CAST(CASE WHEN category IN ('','null') THEN NULL ELSE category END AS INT) as ACCT_CTGY_KEY
                                         ,from_unixtime(unix_timestamp(case when context_cobdate in ('','null') OR context_cobdate IS NULL then context_bankingdate else context_cobdate end ,'yyyyMMdd'),'yyyy-MM-dd') AS strt_DT
                                         ,row_number() OVER (PARTITION BY K_ENTITYID,CASE When context_cobdate in('', 'null') or context_cobdate is null  THEN context_bankingdate ELSE context_cobdate END ORDER BY K_PROCESSINGTIME desc) AS RNK
                          
                                         FROM STG_T24.fodb_account
                                         where  from_unixtime(unix_timestamp(CASE When context_cobdate in('', 'null') or context_cobdate is null  THEN context_bankingdate ELSE context_cobdate END  ,'yyyyMMdd'),'yyyy-MM-dd')
                                         BETWEEN '${strt_dt}' AND '${end_dt}'
                                         
                          )ACCT
                          
                          WHERE RNK = 1
                                         
            )ACCT
            ON ACCT.ACCT_KEY = LNKD_ACCT.ACCT_KEY
            AND BASE.Calendar_dt BETWEEN ACCT.STRT_DT AND ACCT.END_DT
            
            
            ----------===== OUTSTANDING ====---------
            LEFT JOIN
            (
                                         SELECT
                                         ACCT_TYP.k_entityid AS ACCT_KEY
                                         ,STRT_DT
                                         ,OS_AMT
                                         ,COALESCE(
                     DATE_ADD(
                        LEAD(strt_dt) OVER (PARTITION BY ACCT_TYP.k_entityid  ORDER BY strt_dt),-1
                      ),DATE '2999-12-31'
                    ) AS End_Dt
                                         
                                         FROM
                                         (
                                            select
                                                       k_entityid
                                                       ,REC_INDEX   
                                                       ,COB_DT AS STRT_DT              
                       from                         
                                            (
                                                                      select
                                                                      k_entityid
                                                                      ,REC_INDEX
                                                                     ,from_unixtime(unix_timestamp(CASE When context_cobdate in('', 'null') or context_cobdate is null  THEN context_bankingdate ELSE context_cobdate END  ,'yyyyMMdd'),'yyyy-MM-dd') as cob_dt
                                                                      ,row_number() OVER (PARTITION BY K_ENTITYID,REC_INDEX, CASE When context_cobdate in('', 'null') or context_cobdate is null  THEN context_bankingdate ELSE context_cobdate END ORDER BY K_PROCESSINGTIME desc) AS RNK
                                         
                                                                      from stg_t24.fodb_eb_contract_balances_typesysdate
                                                                      where  from_unixtime(unix_timestamp(CASE When context_cobdate in('', 'null') or context_cobdate is null  THEN context_bankingdate ELSE context_cobdate END  ,'yyyyMMdd'),'yyyy-MM-dd')
                                                                      BETWEEN '${strt_dt}' AND '${end_dt}'
                                                                      AND                   typesysdate = 'CURACCOUNT'          
                                                       )CNTRCT_TYPE
                                                       where rnk = 1
                                         )ACCT_TYP
            
                                         INNER JOIN
                                         (
                                            select *
                                            from
                                            (
                                                                      select
                                                                      k_entityid
                                                                      ,CAST(SPLIT(rec_index, '\\.')[0] AS INT) as rec_index
                                                                      ,CAST((COALESCE(Openbalance,0)+ COALESCE(creditmvmt,0) + COALESCE(debitmvmt,0) ) AS DECIMAL(18,2)) as OS_AMT
                                                                     ,from_unixtime(unix_timestamp(CASE When context_cobdate in('', 'null') or context_cobdate is null  THEN context_bankingdate ELSE context_cobdate END  ,'yyyyMMdd'),'yyyy-MM-dd') as cob_dt
                                                                      ,row_number() OVER (PARTITION BY K_ENTITYID,CAST(SPLIT(rec_index, '\\.')[0] AS INT), CASE When context_cobdate in('', 'null') or context_cobdate is null  THEN context_bankingdate ELSE context_cobdate END ORDER BY K_PROCESSINGTIME desc) AS RNK
                                         
                                                                      from stg_t24.fodb_eb_contract_balances_typesysdate_matdate
                                                       )cntrct_bal
                                                       where rnk =1
                                         )ACCT_BAL
                                         ON ACCT_BAL.k_entityid  = ACCT_TYP.k_entityid
                                         AND ACCT_BAL.rec_index = ACCT_TYP.rec_index
                                         AND ACCT_BAL.COB_DT = ACCT_TYP.STRT_DT
            
            )ACCT_OS
            ON ACCT_OS.ACCT_KEY = LNKD_ACCT.ACCT_KEY
            AND BASE.Calendar_dt BETWEEN ACCT_OS.STRT_DT AND ACCT_OS.END_DT
        ) BUS_QRY
    ) HASH_PREP
) FINAL WHERE FK_UP <> 1
