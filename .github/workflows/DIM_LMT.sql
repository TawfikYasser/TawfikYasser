SELECT COUNT(*) FROM (
    SELECT hash_prep.*,
        CASE WHEN HASH_PREP.HASH_KEY = FIRST_VALUE(HASH_PREP.HASH_KEY) OVER(
            PARTITION BY HASH_PREP.lmt_key ORDER BY HASH_PREP.strt_dt ASC
            ROWS BETWEEN 1 PRECEDING AND 1 PRECEDING)
        THEN 1 ELSE 0 END AS FK_UP
    FROM (
        SELECT BUS_QRY.*,
            sha2(
coalesce(prnt_lmt_key, '') ||
coalesce(acct_key, '') ||
coalesce(cust_key, '') ||
coalesce(coltrl_key, '') ||
coalesce(lmt_descr, '') ||
coalesce(ccy_key, '') ||
coalesce(ctry_cd, '') ||
coalesce(ctry_rsk, '') ||
coalesce(sctr_key, '') ||
coalesce(Lmt_Grd, '') ||
coalesce(grd_prcntg, '') ||
coalesce(revw_freq_typ, '') ||
coalesce(revw_intrvl, '') ||
coalesce(revw_day_of_mnth, '') ||
coalesce(orgnl_lmt_amt, '') ||
coalesce(amt, '') ||
coalesce(max_tot_amt, '') ||
coalesce(scurd_amt, '') ||
coalesce(fxd_flg, '') ||
coalesce(avl_mrkr_flg, '') ||
coalesce(redcng_lmt_flg, '') ||
coalesce(allow_ntng_flg, '') ||
coalesce(cr_line, '') ||
coalesce(prod_ctgy_key, '') ||
coalesce(authrzr, '') ||
coalesce(chnl_key, '') ||
coalesce(TEC_STS, '')
            , 256) AS HASH_KEY
        FROM (
            
                                    SELECT
                                        lmt_key,
                                        Calendar_dt as strt_dt,
                                        prnt_lmt_key,
                                        coalesce(acct_key,'-1') as acct_key,
                                        coalesce(lmt_Cust.cust_key,lmt.cust_key,'-1') as cust_key,
                                        coalesce(coltrl_key, '-1') as coltrl_key,
                                        lmt_descr,
                                        ccy_key,
                                        ctry_cd,
                                        ctry_rsk,
                                        sctr_key,
                                        Lmt_Grd,
                                        grd_prcntg,
                                        prposl_dt,
                                        offr_exp_dt,
                                        aprvl_dt,
                                        exp_dt,
                                        lmt_dt,
                                        revw_dt,
                                        revw_freq_typ,
                                        revw_intrvl,
                                        revw_day_of_mnth,
                                        orgnl_lmt_amt,
                                        amt,
                                        max_tot_amt,
                                        scurd_amt,
                                        fxd_flg,
                                        avl_mrkr_flg,
                                        redcng_lmt_flg,
                                        allow_ntng_flg,
                                        cr_line,
                                        prod_ctgy_key,
                                        authrzr,
                                        chnl_key,
                                        CASE WHEN Context_operation = 'DELETE' THEN 'Deleted' ELSE 'Active' END as TEC_STS
                                    FROM (
                                        SELECT Calendar_dt
                                        FROM reporting_schema.calendar_base
                                        WHERE Calendar_dt BETWEEN '${strt_dt}' AND '${end_dt}'
                                    ) BASE
                                    INNER JOIN (
                                        SELECT *,
                                            COALESCE(
                                                DATE_ADD(
                                                    LEAD(strt_dt) OVER (PARTITION BY lmt_key ORDER BY strt_dt), -1
                                                ), DATE '2999-12-31'
                                            ) AS End_Dt
                                        FROM (
                                            SELECT
                                                k_entityid as lmt_key,
                                                from_unixtime(unix_timestamp(CASE WHEN context_cobdate IN ('','null') OR context_cobdate IS NULL THEN context_bankingdate ELSE context_cobdate END ,'yyyyMMdd'),'yyyy-MM-dd') AS strt_Dt,
                                                limitcurrency as ccy_key,
                                                liabilitynumber as cust_key,
                                                FROM_unixtime(unix_timestamp(proposaldate ,'yyyyMMdd'),'yyyy-MM-dd') AS prposl_dt,
                                                FROM_unixtime(unix_timestamp(offereduntil ,'yyyyMMdd'),'yyyy-MM-dd') AS offr_exp_dt,
                                                FROM_unixtime(unix_timestamp(approvaldate ,'yyyyMMdd'),'yyyy-MM-dd') AS aprvl_dt,
                                                FROM_unixtime(unix_timestamp(expirydate ,'yyyyMMdd'),'yyyy-MM-dd') AS exp_dt,
                                                FROM_unixtime(unix_timestamp(onlinelimitdate ,'yyyyMMdd'),'yyyy-MM-dd') AS lmt_dt,
                                                FROM_unixtime(unix_timestamp(SUBSTRING(reviewfrequency, 1, 8),'yyyyMMdd'),'yyyy-MM-dd') AS revw_dt,
                                                CASE SUBSTRING(reviewfrequency, 9, 1)
                                                    WHEN 'D' THEN 'Daily'
                                                    WHEN 'W' THEN 'Weekly'
                                                    WHEN 'M' THEN 'Monthly'
                                                    WHEN 'Q' THEN 'Quarterly'
                                                    WHEN 'Y' THEN 'Yearly'
                                                    ELSE 'Unknown'
                                                END AS revw_freq_typ,
                                                CAST(SUBSTRING(reviewfrequency, 10, 2) AS INT) AS revw_intrvl,
                                                CAST(SUBSTRING(reviewfrequency, 12, 2) AS INT) AS revw_day_of_mnth,
                                                CAST(CASE WHEN TRIM(internalamount) IN('','null') OR internalamount IS NULL THEN '0.00' ELSE internalamount END AS DECIMAL(18,2)) AS amt,
                                                CAST(CASE WHEN TRIM(maximumtotal) IN('','null') OR maximumtotal IS NULL THEN '0.00' ELSE maximumtotal END AS DECIMAL(18,2)) AS max_tot_amt,
                                                CAST(CASE WHEN TRIM(originallimit) IN('','null') OR originallimit IS NULL THEN '0.00' ELSE originallimit END AS DECIMAL(18,2)) AS orgnl_lmt_amt,
                                                CASE WHEN fixedvariable = 'FIXED' THEN 'Y' ELSE 'N' END AS fxd_flg,
                                                allownetting AS allow_ntng_flg,
                                                availablemarker AS avl_mrkr_flg,
                                                reducinglimit AS redcng_lmt_flg,
                                                CASE WHEN recordparent IN ('','null') OR recordparent IS NULL THEN '-1' ELSE recordparent END AS prnt_lmt_key,
                                                creditline AS cr_line,
                                                limitproduct AS prod_ctgy_key,
                                                authoriser AS authrzr,
                                                cocode AS chnl_key,
                                                context_operation,
                                                ROW_NUMBER() OVER (PARTITION BY k_entityid, CASE WHEN context_cobdate IN ('','null') OR context_cobdate IS NULL THEN context_bankingdate ELSE context_cobdate END ORDER BY k_processingtime DESC) AS RNK
                                            FROM STG_T24.fodb_limit
                                            WHERE from_unixtime(unix_timestamp(CASE WHEN context_cobdate IN ('', 'null') OR context_cobdate IS NULL THEN context_bankingdate ELSE context_cobdate END ,'yyyyMMdd'),'yyyy-MM-dd') BETWEEN '${strt_dt}' AND '${end_dt}'
                                        ) limit
                                        WHERE RNK = 1
                                    ) LMT
                                    ON BASE.Calendar_dt BETWEEN LMT.STRT_DT AND LMT.END_DT
                                    LEFT JOIN (
                                        SELECT *,
                                            COALESCE(
                                                DATE_ADD(
                                                    LEAD(strt_dt) OVER (PARTITION BY k_entityid ORDER BY strt_dt), -1
                                                ), DATE '2999-12-31'
                                            ) AS End_Dt
                                        FROM (
                                            SELECT
                                                k_entityid,
                                                account as acct_key,
                                                from_unixtime(unix_timestamp(CASE WHEN context_cobdate IN ('','null') OR context_cobdate IS NULL THEN context_bankingdate ELSE context_cobdate END ,'yyyyMMdd'),'yyyy-MM-dd') AS strt_Dt,
                                                ROW_NUMBER() OVER (PARTITION BY k_entityid, CASE WHEN context_cobdate IN ('','null') OR context_cobdate IS NULL THEN context_bankingdate ELSE context_cobdate END ORDER BY k_processingtime DESC) AS RNK
                                            FROM STG_T24.fodb_limit_acccompany
                                            WHERE rec_index = '0'
                                        ) lmt_acct
                                        WHERE RNK = 1
                                    ) lmt_acct
                                    ON lmt_acct.k_entityid = lmt.lmt_key
                                    AND BASE.Calendar_dt BETWEEN lmt_acct.STRT_DT AND lmt_acct.END_DT
                                    LEFT JOIN (
                                        SELECT *,
                                            COALESCE(
                                                DATE_ADD(
                                                    LEAD(strt_dt) OVER (PARTITION BY k_entityid ORDER BY strt_dt), -1
                                                ), DATE '2999-12-31'
                                            ) AS End_Dt
                                        FROM (
                                            SELECT
                                                k_entityid,
                                                customernumber as cust_key,
                                                from_unixtime(unix_timestamp(CASE WHEN context_cobdate IN ('','null') OR context_cobdate IS NULL THEN context_bankingdate ELSE context_cobdate END ,'yyyyMMdd'),'yyyy-MM-dd') AS strt_Dt,
                                                ROW_NUMBER() OVER (PARTITION BY k_entityid, CASE WHEN context_cobdate IN ('','null') OR context_cobdate IS NULL THEN context_bankingdate ELSE context_cobdate END ORDER BY k_processingtime DESC) AS RNK
                                            FROM STG_T24.fodb_limit_customernumber
                                            WHERE rec_index = '0'
                                        ) lmt_Cust
                                        WHERE RNK = 1
                                    ) lmt_Cust
                                    ON lmt_Cust.k_entityid = lmt.lmt_key
                                    AND BASE.Calendar_dt BETWEEN lmt_Cust.STRT_DT AND lmt_Cust.END_DT
                                    LEFT JOIN (
                                        SELECT *,
                                            COALESCE(
                                                DATE_ADD(
                                                    LEAD(strt_dt) OVER (PARTITION BY k_entityid, rec_index ORDER BY strt_dt), -1
                                                ), DATE '2999-12-31'
                                            ) AS End_Dt
                                        FROM (
                                            SELECT
                                                k_entityid,
                                                rec_index,
                                                limitgrade as Lmt_Grd,
                                                gradepercent as grd_prcntg,
                                                from_unixtime(unix_timestamp(CASE WHEN context_cobdate IN ('','null') OR context_cobdate IS NULL THEN context_bankingdate ELSE context_cobdate END ,'yyyyMMdd'),'yyyy-MM-dd') AS strt_Dt,
                                                ROW_NUMBER() OVER (PARTITION BY k_entityid, rec_index, CASE WHEN context_cobdate IN ('','null') OR context_cobdate IS NULL THEN context_bankingdate ELSE context_cobdate END ORDER BY k_processingtime DESC) AS RNK
                                            FROM STG_T24.fodb_limit_limitgrade
                                        ) Grade
                                        WHERE RNK = 1
                                    ) Lmt_Grd
                                    ON Lmt_Grd.k_entityid = lmt.lmt_key
                                    AND BASE.Calendar_dt BETWEEN Lmt_Grd.STRT_DT AND Lmt_Grd.END_DT
                                    LEFT JOIN (
                                        SELECT *,
                                            COALESCE(
                                                DATE_ADD(
                                                    LEAD(strt_dt) OVER (PARTITION BY k_entityid, rec_index ORDER BY strt_dt), -1
                                                ), DATE '2999-12-31'
                                            ) AS End_Dt
                                        FROM (
                                            SELECT
                                                k_entityid,
                                                CAST(SPLIT(rec_index, '\\.')[0] AS INT) as rec_index,
                                                collatright as coltrl_key,
                                                CAST(CASE WHEN TRIM(securedamt) IN('','null') OR securedamt IS NULL THEN '0.00' ELSE securedamt END AS DECIMAL(18,2)) AS scurd_amt,
                                                from_unixtime(unix_timestamp(CASE WHEN context_cobdate IN ('','null') OR context_cobdate IS NULL THEN context_bankingdate ELSE context_cobdate END ,'yyyyMMdd'),'yyyy-MM-dd') AS strt_Dt,
                                                ROW_NUMBER() OVER (PARTITION BY k_entityid, CAST(SPLIT(rec_index, '\\.')[0] AS INT), CASE WHEN context_cobdate IN ('','null') OR context_cobdate IS NULL THEN context_bankingdate ELSE context_cobdate END ORDER BY k_processingtime DESC) AS RNK
                                            FROM STG_T24.fodb_limit_collatright_collatright
                                        ) lmt_cltrl
                                        WHERE RNK = 1
                                    ) lmt_cltrl
                                    ON lmt_cltrl.k_entityid = lmt.lmt_key
                                    AND BASE.Calendar_dt BETWEEN lmt_cltrl.STRT_DT AND lmt_cltrl.END_DT
                                    LEFT JOIN (
                                        SELECT *,
                                            COALESCE(
                                                DATE_ADD(
                                                    LEAD(strt_dt) OVER (PARTITION BY k_entityid, rec_index ORDER BY strt_dt), -1
                                                ), DATE '2999-12-31'
                                            ) AS End_Dt
                                        FROM (
                                            SELECT
                                                k_entityid,
                                                rec_index,
                                                countryofrisk as ctry_cd,
                                                countrypercent as ctry_rsk,
                                                from_unixtime(unix_timestamp(CASE WHEN context_cobdate IN ('','null') OR context_cobdate IS NULL THEN context_bankingdate ELSE context_cobdate END ,'yyyyMMdd'),'yyyy-MM-dd') AS strt_Dt,
                                                ROW_NUMBER() OVER (PARTITION BY k_entityid, rec_index, CASE WHEN context_cobdate IN ('','null') OR context_cobdate IS NULL THEN context_bankingdate ELSE context_cobdate END ORDER BY k_processingtime DESC) AS RNK
                                            FROM STG_T24.fodb_limit_countryofrisk
                                        ) ctry
                                        WHERE RNK = 1
                                    ) lmt_ctry
                                    ON lmt_ctry.k_entityid = lmt.lmt_key 
                                    AND BASE.Calendar_dt BETWEEN lmt_ctry.STRT_DT AND lmt_ctry.END_DT
                                    LEFT JOIN (
                                        SELECT *,
                                            COALESCE(
                                                DATE_ADD(
                                                    LEAD(strt_dt) OVER (PARTITION BY k_entityid, rec_index ORDER BY strt_dt), -1
                                                ), DATE '2999-12-31'
                                            ) AS End_Dt
                                        FROM (
                                            SELECT
                                                k_entityid,
                                                rec_index,
                                                commodity as sctr_key,
                                                from_unixtime(unix_timestamp(CASE WHEN context_cobdate IN ('','null') OR context_cobdate IS NULL THEN context_bankingdate ELSE context_cobdate END ,'yyyyMMdd'),'yyyy-MM-dd') AS strt_Dt,
                                                ROW_NUMBER() OVER (PARTITION BY k_entityid, rec_index, CASE WHEN context_cobdate IN ('','null') OR context_cobdate IS NULL THEN context_bankingdate ELSE context_cobdate END ORDER BY k_processingtime DESC) AS RNK
                                            FROM STG_T24.fodb_limit_commodity
                                        ) cmdty
                                        WHERE RNK = 1
                                    ) lmt_cmdty
                                    ON lmt_cmdty.k_entityid = lmt.lmt_key
                                    AND BASE.Calendar_dt BETWEEN lmt_cmdty.STRT_DT AND lmt_cmdty.END_DT
                                    LEFT JOIN (
                                        SELECT *,
                                            COALESCE(
                                                DATE_ADD(
                                                    LEAD(strt_dt) OVER (PARTITION BY k_entityid ORDER BY strt_dt), -1
                                                ), DATE '2999-12-31'
                                            ) AS End_Dt
                                        FROM (
                                            SELECT
                                                k_entityid,
                                                description as lmt_descr,
                                                from_unixtime(unix_timestamp(CASE WHEN context_cobdate IN ('','null') OR context_cobdate IS NULL THEN context_bankingdate ELSE context_cobdate END ,'yyyyMMdd'),'yyyy-MM-dd') AS strt_Dt,
                                                ROW_NUMBER() OVER (PARTITION BY k_entityid, CASE WHEN context_cobdate IN ('','null') OR context_cobdate IS NULL THEN context_bankingdate ELSE context_cobdate END ORDER BY k_processingtime DESC) AS RNK
                                            FROM STG_T24.fodb_limit_reference_description
                                            WHERE rec_index = '0'
                                        ) descr
                                        WHERE RNK = 1
                                    ) lmt_descr
                                    ON lmt_descr.k_entityid = lmt.prod_ctgy_key
                                    AND BASE.Calendar_dt BETWEEN lmt_descr.STRT_DT AND lmt_descr.END_DT
        ) BUS_QRY
    ) HASH_PREP
) FINAL WHERE FK_UP <> 1
