
    SELECT
        CAST(CRD_STMT.acc_id AS varchar(50))  AS Acct_Key,
        CAST(ACCT_DTL.custcode AS varchar(50)) AS Cust_key,
        CAST(stmt_id AS varchar(50))          AS STMT_Key,
        CAST(date_stmt AS date)               AS STMT_DT,
        CAST(date_begin AS date)              AS STMT_STRT_DT,
        CAST(date_end AS date)                AS STMT_END_DT,
        CAST(credits AS decimal(18,2))        AS CRDTS,
        CAST(debits AS decimal(18,2))         AS DBTS,
        CAST(payments AS decimal(18,2))       AS PMTS,
        CAST(bal_close AS decimal(18,2))      AS CLSG_BAL,
        CAST(min_pay AS decimal(18,2))        AS Min_Pay,
        CAST(from_unixtime(CAST(date_pay AS BIGINT) DIV 1000) AS date) AS PAY_DT,
        CAST(bal_previous AS decimal(18,2))   AS PRV_BAL,
        CAST(surplus AS decimal(18,2))        AS Surplus,
        CAST(dlnqlvl AS int)                  AS DLNQ_LVL,
        CAST(overdue_count AS int)            AS OVRDUE_CNT,
        CAST(current_timestamp AS string)    AS tec_insrt_dttm,
        CAST(current_timestamp AS string)    AS tec_upd_dttm,
        NULL AS dr_dttm,
        NULL AS dr_flg
    FROM
    (
        SELECT *
        FROM (
            SELECT *,
                   row_number() OVER (
                       PARTITION BY stmt_id
                       ORDER BY verno_ctx DESC, tec_insrt_dttm DESC
                   ) rn
            FROM stg_cor.ccsstatement
            --WHERE CAST(tec_insrt_dttm AS date)
                  --BETWEEN '${strt_dt}' AND '${end_dt}'
        ) s
        WHERE rn = 1
    ) CRD_STMT
    LEFT JOIN
    (
        SELECT acc_id, custcode
        FROM (
            SELECT acc_id,
                   custcode,
                   row_number() OVER (
                       PARTITION BY acc_id
                       ORDER BY verno_ctx DESC, tec_insrt_dttm DESC
                   ) rn
            FROM stg_cor.CCSACCDET
        ) a
        WHERE rn = 1
    ) ACCT_DTL
    ON ACCT_DTL.acc_id = CRD_STMT.acc_id
