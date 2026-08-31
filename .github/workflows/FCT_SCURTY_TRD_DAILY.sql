
    SELECT 
        BASE.Calendar_dt AS cal_dt,
        trd_postn.PRCSNG_DTTM,
        trd_postn.scurty_key,
        trd_postn.portf_key,
        trd_postn.currentposition AS postn_amt,
        trd_postn.curcostposition AS cost_amt,
        trd_postn.curavgprice AS avg_price,
        trd_postn.discaccrposted AS disc_acrul_postd,
        trd_postn.cpnaccrposted AS copn_acrul_postd,
        trd_postn.vdatedcpnaccr AS copn_acrul,
        trd_postn.revalunrealpl AS reval_unreal_pl_amt,
        trd_postn.revalunrealplcy AS reval_unreal_pl_Lcy_amt,
        DATEDIFF(Maturitydate, Calendar_dt) AS Days_to_maturity,
        CURRENT_TIMESTAMP AS tec_insrt_dttm,
        CURRENT_TIMESTAMP AS tec_upd_dttm,
        NULL AS dr_dttm,
        NULL AS dr_flg
    FROM (	
        SELECT Calendar_dt
        FROM dwh_base.calendar_base
        WHERE Calendar_dt BETWEEN '${STRT_DT}' AND '${END_DT}'
    ) BASE
    INNER JOIN (
        SELECT 
            SCURTY_KEY,
            PORTF_KEY,
            currentposition,
            curcostposition,
            ABS(discaccrposted) AS discaccrposted,
            cpnaccrposted,
            curavgprice,
            vdatedcpnaccr,
            revalunrealpl,
            revalunrealplcy,
            COB_DT AS strt_dt,
            prcsng_dttm,
            COALESCE(
                LEAD(cob_dt) OVER (
                    PARTITION BY SCURTY_KEY, PORTF_KEY
                    ORDER BY cob_dt
                ),
                '2999-12-31'
            ) AS end_dt
        FROM (		
            SELECT
                securitycode AS SCURTY_KEY,
                dealerbook AS PORTF_KEY,
                CAST(CASE WHEN TRIM(currentposition) IN('', 'null') OR currentposition IS NULL THEN '0.00' ELSE currentposition END AS DECIMAL(18,4)) AS currentposition,
                CAST(CASE WHEN TRIM(curcostposition) IN('', 'null') OR curcostposition IS NULL THEN '0.00' ELSE curcostposition END AS DECIMAL(18,4)) AS curcostposition,
                CAST(CASE WHEN TRIM(discaccrposted) IN('', 'null') OR discaccrposted IS NULL THEN '0.00' ELSE discaccrposted END AS DECIMAL(18,4)) AS discaccrposted,
                CAST(CASE WHEN TRIM(cpnaccrposted) IN('', 'null') OR cpnaccrposted IS NULL THEN '0.00' ELSE cpnaccrposted END AS DECIMAL(18,4)) AS cpnaccrposted,
                CAST(CASE WHEN TRIM(curavgprice) IN('', 'null') OR curavgprice IS NULL THEN '0.00' ELSE curavgprice END AS DECIMAL(18,4)) AS curavgprice,
                CAST(CASE WHEN TRIM(vdatedcpnaccr) IN('', 'null') OR vdatedcpnaccr IS NULL THEN '0.00' ELSE vdatedcpnaccr END AS DECIMAL(18,4)) AS vdatedcpnaccr,
                CAST(CASE WHEN TRIM(revalunrealpl) IN('', 'null') OR revalunrealpl IS NULL THEN '0.00' ELSE revalunrealpl END AS DECIMAL(18,4)) AS revalunrealpl,
                CAST(CASE WHEN TRIM(revalunrealplcy) IN('', 'null') OR revalunrealplcy IS NULL THEN '0.00' ELSE revalunrealplcy END AS DECIMAL(18,4)) AS revalunrealplcy,
                FROM_UNIXTIME(UNIX_TIMESTAMP(CASE WHEN context_cobdate IN ('', 'null') OR context_cobdate IS NULL THEN context_bankingdate ELSE context_cobdate END, 'yyyyMMdd'), 'yyyy-MM-dd') AS cob_dt,
                FROM_UNIXTIME(CAST(CAST(k_processingtime AS BIGINT) / 1000 AS INT), "yyyy-MM-dd HH:mm:ss") AS PRCSNG_DTTM,
                ROW_NUMBER() OVER (
                    PARTITION BY k_entityid, dealerbook, FROM_UNIXTIME(UNIX_TIMESTAMP(CASE WHEN context_cobdate IN ('', 'null') OR context_cobdate IS NULL THEN context_bankingdate ELSE context_cobdate END, 'yyyyMMdd'), 'yyyy-MM-dd')	
                    ORDER BY k_processingtime DESC
                ) AS rnk	
            FROM STG_t24.fodb_sc_trading_position
        ) SEC_POSTIN
        WHERE SEC_POSTIN.RNK = 1
    ) TRD_POSTN
    ON BASE.CALENDAR_DT >= TRD_POSTN.STRT_DT 
    AND BASE.CALENDAR_DT < TRD_POSTN.END_DT
    LEFT JOIN (
        SELECT *
        FROM (
            SELECT  
                securitycode AS SCURTY_KEY,
                FROM_UNIXTIME(UNIX_TIMESTAMP(Maturitydate, 'yyyyMMdd'), 'yyyy-MM-dd') AS Maturitydate,
                ROW_NUMBER() OVER(PARTITION BY securitycode ORDER BY k_processingtime DESC) AS rnk
            FROM STG_t24.fodb_sec_trade
        ) TRD
        WHERE rnk = 1
    ) SCURTY_TRD
    ON SCURTY_TRD.SCURTY_KEY = TRD_POSTN.SCURTY_KEY
    WHERE DATEDIFF(Maturitydate, CALENDAR_DT) >= 0
