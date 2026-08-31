SELECT COUNT(*) FROM (
    SELECT hash_prep.*,
        CASE WHEN HASH_PREP.HASH_KEY = FIRST_VALUE(HASH_PREP.HASH_KEY) OVER(
            PARTITION BY HASH_PREP.Hld_key ORDER BY HASH_PREP.strt_dt ASC
            ROWS BETWEEN 1 PRECEDING AND 1 PRECEDING)
        THEN 1 ELSE 0 END AS FK_UP
    FROM (
        SELECT BUS_QRY.*,
            sha2(
coalesce(Acct_Key, '') ||
coalesce(Trx_Ref_key, '') ||
coalesce(Trx_Typ, '') ||
coalesce(Trx_Cd_key, '') ||
coalesce(Lckd_Typ, '') ||
coalesce(Descr, '') ||
coalesce(Pymt_CCY, '') ||
coalesce(Pymt_Amt, '') ||
coalesce(Lckd_Amt, '') ||
coalesce(Orgnl_AMT, '') ||
coalesce(Total_Chrg_Amt, '') ||
coalesce(Chrg_Amt1, '') ||
coalesce(Chrg_Amt2, '') ||
coalesce(Chrg_Amt3, '') ||
coalesce(Rsrvtn_Key, '') ||
coalesce(Mrchnt_Key, '') ||
coalesce(Jornl_Key, '') ||
coalesce(Chnl_key, '') ||
coalesce(DEPT_KEY, '') ||
coalesce(Audtr_key, '') ||
coalesce(TEC_STS, '') ||
coalesce(Inptr, '') ||
coalesce(Authrzr, '')
            , 256) AS HASH_KEY
        FROM (
            SELECT
                Lckd_Evnt.Hld_key                                            AS Hld_key,
                Lckd_Evnt.Strt_Dttm                                          AS strt_dttm,
                COALESCE(Dltd_Evnt.Acct_Key, Lckd_Evnt.Acct_Key)             AS Acct_Key,
                COALESCE(Dltd_Evnt.Trx_Ref, Lckd_Evnt.Trx_Ref)               AS Trx_Ref_key,
                COALESCE(Dltd_Evnt.Trx_Typ, Lckd_Evnt.Trx_Typ)               AS Trx_Typ,
                COALESCE(Dltd_Evnt.Trx_Code, Lckd_Evnt.Trx_Code)             AS Trx_Cd_key,
                COALESCE(Dltd_Evnt.Lckd_Typ, Lckd_Evnt.Lckd_Typ)             AS Lckd_Typ,
                COALESCE(Dltd_Evnt.Descr, Lckd_Evnt.Descr) 		             AS Descr,
                COALESCE(Dltd_Evnt.From_Dt, Lckd_Evnt.From_Dt)               AS From_Dt,
                COALESCE(Dltd_Evnt.To_Dt, Lckd_Evnt.To_Dt) 		             AS To_Dt,
                COALESCE(Dltd_Evnt.Pymt_CCY, Lckd_Evnt.Pymt_CCY)             AS Pymt_CCY,
                COALESCE(Dltd_Evnt.Pymt_Amt, Lckd_Evnt.Pymt_Amt)             AS Pymt_Amt,
                COALESCE(Dltd_Evnt.Lckd_Amt, Lckd_Evnt.Lckd_Amt)             AS Lckd_Amt,
                COALESCE(Dltd_Evnt.Orgnl_AMT, Lckd_Evnt.Orgnl_AMT)           AS Orgnl_AMT,
                COALESCE(Dltd_Evnt.Total_Chrg_Amt, Lckd_Evnt.Total_Chrg_Amt) AS Total_Chrg_Amt,
                COALESCE(Dltd_Evnt.Chrg_Amt1, Lckd_Evnt.Chrg_Amt1) 			 AS Chrg_Amt1,
                COALESCE(Dltd_Evnt.Chrg_Amt2, Lckd_Evnt.Chrg_Amt2) 			 AS Chrg_Amt2,
                COALESCE(Dltd_Evnt.Chrg_Amt3, Lckd_Evnt.Chrg_Amt3) 			 AS Chrg_Amt3,
                COALESCE(Dltd_Evnt.Rsrvtn_Key, Lckd_Evnt.Rsrvtn_Key)         AS Rsrvtn_Key,
                Lckd_Evnt.Mrchnt_Key                                         AS Mrchnt_Key,
                Lckd_Evnt.Jornl_Key                                          AS Jornl_Key,
                Lckd_Evnt.Chnl_Key                                           AS Chnl_key,
                Lckd_Evnt.Dept_key                                           AS DEPT_KEY,
                Lckd_Evnt.Audtr_key                                          AS Audtr_key,
                Lckd_Evnt.Audt_Dttm                                          AS Audt_Dttm,
                CASE WHEN Lckd_Evnt.Context_operation = 'DELETE' THEN 'Deleted' ELSE 'Active' END AS TEC_STS,
                EVNT_INPTR.inputter                                          AS Inptr,
                COALESCE(Dltd_Evnt.Authrzr, Lckd_Evnt.Authrzr)               AS Authrzr,
                Lckd_Evnt.COB_DT                                             AS strt_dt
            FROM
            (
                SELECT
                    k_entityid AS Hld_key,
                    from_unixtime(cast(CAST(k_processingtime AS BIGINT) / 1000 AS INT), "yyyy-MM-dd HH:mm:ss") AS Strt_Dttm,
                    context_companycode AS Chnl_Key,
                    from_unixtime(unix_timestamp(CASE WHEN context_cobdate IN ('','null') OR context_cobdate IS NULL THEN context_bankingdate ELSE context_cobdate END ,'yyyyMMdd'),'yyyy-MM-dd') AS COB_DT,
                    context_operation,
                    accountnumber AS Acct_Key,
                    CASE WHEN TRIM(description) IN ('','null') OR description IS NULL THEN 'NA' ELSE description END AS Descr,
                    CASE WHEN TRIM(fromdate) IN ('','null') THEN NULL ELSE from_unixtime(unix_timestamp(fromdate ,'yyyyMMdd'),'yyyy-MM-dd') END AS From_Dt,
                    CASE WHEN TRIM(todate) NOT IN ('','null') THEN NULL ELSE from_unixtime(unix_timestamp(todate ,'yyyyMMdd'),'yyyy-MM-dd') END AS To_Dt,
                    CASE WHEN TRIM(lockedamount) IN ('','null') OR lockedamount IS NULL THEN 0.00 ELSE CAST(lockedamount AS DECIMAL(18,3)) END AS lckd_Amt,
                    rcretry AS Rc_Retry,
                    rcdetailid AS Rc_Dtl,
                    blockpriority AS BLK_PRIO,
                    CASE WHEN TRIM(transref) IN ('','null') OR transref IS NULL THEN 'NA' ELSE transref END AS Trx_Ref,
                    CASE WHEN paymentamt IN ('',null) OR paymentamt IS NULL THEN 0.00 ELSE CAST(paymentamt AS DECIMAL(18,3)) END AS Pymt_Amt,
                    paymentccy AS Pymt_CCY,
                    adddetailreqsource AS Req_Src_Dtl,
                    reservealtkey AS Reservealt_key,
                    CASE WHEN TRIM(lockedtype) IN ('','null') OR lockedtype IS NULL THEN 'NA' ELSE lockedtype END AS Lckd_Typ,
                    accountlink AS Acct_Lnk,
                    linkstatus AS Lnk_Sts,
                    CASE WHEN TRIM(txnsign) IN ('','null') OR txnsign IS NULL THEN 'NA' ELSE txnsign END AS Trx_typ,
                    fastatus AS Fst_Sts,
                    reservationid AS Rsrvtn_Key,
                    journalid AS Jornl_Key,
                    merchantflag AS Mrchnt_Key,
                    CASE WHEN TRIM(transactioncode) IN ('','null') OR transactioncode IS NULL THEN NULL ELSE transactioncode END AS Trx_Code,
                    recordstatus AS Rec_Sts,
                    CASE WHEN TRIM(authoriser) IN ('','null') OR authoriser IS NULL THEN 'NA' ELSE authoriser END AS Authrzr,
                    deptcode AS Dept_key,
                    auditorcode AS Audtr_key,
                    auditdatetime AS Audt_Dttm,
                    CASE WHEN TRIM(loriginalamt) IN ('','null') OR loriginalamt IS NULL THEN 0.00 ELSE CAST(loriginalamt AS DECIMAL(18,3)) END AS Orgnl_AMT,
                    CASE WHEN TRIM(ltotalchgamt) IN ('','null') OR ltotalchgamt IS NULL THEN 0.00 ELSE CAST(ltotalchgamt AS DECIMAL(18,3)) END AS Total_Chrg_Amt,
                    CASE WHEN TRIM(lchargeamt1) IN ('','null') OR lchargeamt1 IS NULL THEN 0.00 ELSE CAST(lchargeamt1 AS DECIMAL(18,3)) END AS Chrg_Amt1,
                    CASE WHEN TRIM(lchargeamt2) IN ('','null') OR lchargeamt2 IS NULL THEN 0.00 ELSE CAST(lchargeamt2 AS DECIMAL(18,3)) END AS Chrg_Amt2,
                    CASE WHEN TRIM(lchargeamt3) IN ('','null') OR lchargeamt3 IS NULL THEN 0.00 ELSE CAST(lchargeamt3 AS DECIMAL(18,3)) END AS Chrg_Amt3
                FROM STG_T24.fodb_ac_locked_events
                WHERE from_unixtime(unix_timestamp(CASE WHEN context_cobdate IN ('', 'null') OR context_cobdate IS NULL THEN context_bankingdate ELSE context_cobdate END ,'yyyyMMdd'),'yyyy-MM-dd') BETWEEN '${strt_dt}' AND '${end_dt}'
                QUALIFY ROW_NUMBER() OVER (PARTITION BY k_ENTITYID, CASE WHEN context_cobdate IN ('','null') OR context_cobdate IS NULL THEN context_bankingdate ELSE context_cobdate END ORDER BY k_processingtime DESC) = 1
            ) Lckd_Evnt
            LEFT JOIN
            (
                SELECT
                    k_entityid AS Hld_key,
                    accountnumber AS Acct_Key,
                    CASE WHEN TRIM(lockedamount) IN ('','null') OR lockedamount IS NULL THEN 0.00 ELSE CAST(lockedamount AS DECIMAL(18,3)) END AS lckd_Amt,
                    CASE WHEN paymentamt IN ('',null) OR paymentamt IS NULL THEN 0.00 ELSE CAST(paymentamt AS DECIMAL(18,3)) END AS Pymt_Amt,
                    paymentccy AS Pymt_CCY,
                    CASE WHEN TRIM(fromdate) IN ('','null') THEN NULL ELSE from_unixtime(unix_timestamp(fromdate ,'yyyyMMdd'),'yyyy-MM-dd') END AS From_Dt,
                    CASE WHEN TRIM(todate) NOT IN ('','null') THEN NULL ELSE from_unixtime(unix_timestamp(todate ,'yyyyMMdd'),'yyyy-MM-dd') END AS To_Dt,
                    CASE WHEN TRIM(description) IN ('','null') THEN NULL ELSE description END AS Descr,
                    CASE WHEN TRIM(transref) IN ('','null') THEN NULL ELSE transref END AS Trx_Ref,
                    CASE WHEN TRIM(txnsign) IN ('','null') THEN NULL ELSE txnsign END AS Trx_typ,
                    CASE WHEN TRIM(transactioncode) IN ('','null') THEN NULL ELSE transactioncode END AS Trx_Code,
                    CASE WHEN TRIM(lockedtype) IN ('','null') THEN NULL ELSE lockedtype END AS Lckd_Typ,
                    CASE WHEN TRIM(reservationid) IN ('','null') THEN NULL ELSE reservationid END AS Rsrvtn_Key,
                    CASE WHEN TRIM(authoriser) IN ('','null') THEN NULL ELSE authoriser END AS Authrzr,
                    CASE WHEN TRIM(loriginalamt) IN ('','null') OR loriginalamt IS NULL THEN 0.00 ELSE CAST(loriginalamt AS DECIMAL(18,3)) END AS Orgnl_AMT,
                    CASE WHEN TRIM(ltotalchgamt) IN ('','null') OR ltotalchgamt IS NULL THEN 0.00 ELSE CAST(ltotalchgamt AS DECIMAL(18,3)) END AS Total_Chrg_Amt,
                    CASE WHEN TRIM(lchargeamt1) IN ('','null') OR lchargeamt1 IS NULL THEN 0.00 ELSE CAST(lchargeamt1 AS DECIMAL(18,3)) END AS Chrg_Amt1,
                    CASE WHEN TRIM(lchargeamt2) IN ('','null') OR lchargeamt2 IS NULL THEN 0.00 ELSE CAST(lchargeamt2 AS DECIMAL(18,3)) END AS Chrg_Amt2,
                    CASE WHEN TRIM(lchargeamt3) IN ('','null') OR lchargeamt3 IS NULL THEN 0.00 ELSE CAST(lchargeamt3 AS DECIMAL(18,3)) END AS Chrg_Amt3
                FROM STG_T24.fodb_ac_locked_events Lckd_Evnt
                WHERE CONTEXT_OPERATION = 'WRITE'
                QUALIFY ROW_NUMBER() OVER (PARTITION BY k_ENTITYID ORDER BY k_processingtime DESC) = 1
            ) Dltd_Evnt
            ON Dltd_Evnt.Hld_key = Lckd_Evnt.Hld_key
            AND Lckd_Evnt.CONTEXT_OPERATION = 'DELETE'
            LEFT JOIN
            (
                SELECT
                    k_entityid AS Hld_key,
                    rec_index,
                    inputter
                FROM STG_T24.fodb_ac_locked_events_inputter
                WHERE rec_index = '0'
                QUALIFY ROW_NUMBER() OVER (PARTITION BY k_ENTITYID ORDER BY k_processingtime DESC) = 1
            ) EVNT_INPTR
            ON EVNT_INPTR.Hld_key = Lckd_Evnt.Hld_key
        ) BUS_QRY
    ) HASH_PREP
) FINAL WHERE FK_UP <> 1
