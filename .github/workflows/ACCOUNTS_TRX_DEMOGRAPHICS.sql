SELECT COUNT(*) FROM (
    SELECT hash_prep.*,
        CASE WHEN HASH_PREP.HASH_KEY = FIRST_VALUE(HASH_PREP.HASH_KEY) OVER(
            PARTITION BY HASH_PREP.account_number ORDER BY HASH_PREP.strt_dt ASC
            ROWS BETWEEN 1 PRECEDING AND 1 PRECEDING)
        THEN 1 ELSE 0 END AS FK_UP
    FROM (
        SELECT BUS_QRY.*,
            sha2(
coalesce(first_amountlcy, '') ||
coalesce(first_amountfcy, '') ||
coalesce(first_exchangerate, '') ||
coalesce(first_currency, '') ||
coalesce(first_recid, '') ||
coalesce(first_processingtime, '') ||
coalesce(first_transreference, '') ||
coalesce(first_narrative, '') ||
coalesce(first_softacctngdtls, '') ||
coalesce(first_dr_amountlcy, '') ||
coalesce(first_dr_amountfcy, '') ||
coalesce(first_dr_exchangerate, '') ||
coalesce(first_dr_currency, '') ||
coalesce(first_dr_recid, '') ||
coalesce(first_dr_processingtime, '') ||
coalesce(first_dr_transreference, '') ||
coalesce(first_dr_narrative, '') ||
coalesce(first_dr_softacctngdtls, '') ||
coalesce(first_cr_amountlcy, '') ||
coalesce(first_cr_amountfcy, '') ||
coalesce(first_cr_exchangerate, '') ||
coalesce(first_cr_currency, '') ||
coalesce(first_cr_recid, '') ||
coalesce(first_cr_processingtime, '') ||
coalesce(first_cr_transreference, '') ||
coalesce(first_cr_narrative, '') ||
coalesce(first_cr_softacctngdtls, '') ||
coalesce(has_debit, '') ||
coalesce(has_credit, '')
            , 256) AS HASH_KEY
        FROM (
            SELECT *
                  FROM   (SELECT main.accountnumber    account_number,
                                 main.amountlcy        first_amountlcy,
                                 main.amountfcy        first_amountfcy,
                                 main.exchangerate     first_exchangerate,
                                 main.currency         first_currency,
                                 main.k_entityid       first_recid,
                                 main.processingtime   first_processingtime,
                                 main.transreference   first_transreference,
                                 main.narrative        first_narrative,
                                 main.softacctngdtls   first_softacctngdtls,
                                 debit.amountlcy       first_dr_amountlcy,
                                 debit.amountfcy       first_dr_amountfcy,
                                 debit.exchangerate    first_dr_exchangerate,
                                 debit.currency        first_dr_currency,
                                 debit.k_entityid      first_dr_recid,
                                 debit.processingtime  first_dr_processingtime,
                                 debit.transreference  first_dr_transreference,
                                 debit.narrative       first_dr_narrative,
                                 debit.softacctngdtls  first_dr_softacctngdtls,
                                 credit.amountlcy      first_cr_amountlcy,
                                 credit.amountfcy      first_cr_amountfcy,
                                 credit.exchangerate   first_cr_exchangerate,
                                 credit.currency       first_cr_currency,
                                 credit.k_entityid     first_cr_recid,
                                 credit.processingtime first_cr_processingtime,
                                 credit.transreference first_cr_transreference,
                                 credit.narrative      first_cr_narrative,
                                 credit.softacctngdtls first_cr_softacctngdtls,
                                 CASE
                                   WHEN debit.accountnumber IS NOT NULL THEN true
                                   ELSE false
                                 END                   has_debit,
                                 CASE
                                   WHEN credit.accountnumber IS NOT NULL THEN true
                                   ELSE false
                                 END                   has_credit,
                                 CURRENT_TIMESTAMP     last_modefication_dt,cast(current_timestamp as string) as tec_insrt_dttm		
            	,cast(null as string) as tec_upd_dttm		
            	,cast(null as string) as dr_dttm		
            	,cast(null as string) as dr_flg
                          FROM   (SELECT accountnumber,
                                         amountlcy,
                                         amountfcy,
                                         exchangerate,
                                         currency,
                                         k_entityid,
                                         processingtime,
                                         transreference,
                                         trns_des.narrative,
                                         softacctngdtls
                                  FROM   (SELECT accountnumber,
                                                 amountlcy,
                                                 amountfcy,
                                                 exchangerate,
                                                 currency,
                                                 k_entityid,
                                                 processingtime,
                                                 transreference,
                                                 transactioncode,
                                                 softacctngdtls
                                          FROM   (SELECT k_entityid,
                                                         accountnumber,
                                                         Cast(CASE
                                                                WHEN COALESCE(amountlcy,
                                                                     'null')
                                                                     = 'null'
                                                              THEN
                                                                '0.00'
                                                                WHEN amountlcy = '' THEN
                                                                '0.00'
                                                                ELSE amountlcy
                                                              END AS DECIMAL(18, 3))
                                                                 amountlcy,
                                                         Cast(CASE
                                                                WHEN COALESCE(amountfcy,
                                                                     'null')
                                                                     = 'null'
                                                              THEN
                                                                '0.00'
                                                                WHEN amountfcy = '' THEN
                                                                '0.00'
                                                                ELSE amountfcy
                                                              END AS DECIMAL(18, 3))
                                                                 amountfcy,
                                                         currency,
                                                         Cast(CASE
                                                                WHEN COALESCE(exchangerate,
                                                                     'null') =
                                                                     'null' THEN
                                                                '0.00'
                                                                WHEN exchangerate = '' THEN
                                                                '0.00'
                                                                ELSE exchangerate
                                                              END AS DECIMAL(18, 3))
                                                                 exchangerate,
                                                         transreference,
                                                         From_unixtime(Cast(
                                                         Cast(COALESCE(k_processingtime,
                                                              k_emittedtime
                                                              ) AS
                                                              BIGINT) /
                                                         1000 AS INT), "yyyy-mm-dd hh:mm:ss"
                                                         )
                                                                 processingtime,
                                                         transactioncode,
                                                         softacctngdtls,
                                                         Rank()
                                                           OVER(
                                                             partition BY accountnumber
                                                             ORDER BY COALESCE(
                                                           meta_createdtime,
                                                           k_emittedtime),
                                                           k_entityid ASC)
                                                                 rnk
                                                  FROM   #{stg_t24_schema}.fodb_stmt_entry v
                                                  WHERE  COALESCE(processingdate, 'null') !=
                                                         'null') a
                                          WHERE  rnk = 1
                                          GROUP  BY accountnumber,
                                                    amountlcy,
                                                    amountfcy,
                                                    exchangerate,
                                                    currency,
                                                    k_entityid,
                                                    processingtime,
                                                    transreference,
                                                    transactioncode,
                                                    softacctngdtls) trns
                                         INNER JOIN #{dwh_base_schema}.t24_transactions trns_des
                                                 ON trns.transactioncode =
                                                    trns_des.transaction_code)main
                                 LEFT OUTER JOIN(SELECT accountnumber,
                                                        amountlcy,
                                                        amountfcy,
                                                        exchangerate,
                                                        currency,
                                                        k_entityid,
                                                        processingtime,
                                                        transreference,
                                                        trns_des.narrative,
                                                        softacctngdtls
                                                 FROM   (SELECT accountnumber,
                                                                amountlcy,
                                                                amountfcy,
                                                                exchangerate,
                                                                currency,
                                                                k_entityid,
                                                                processingtime,
                                                                transreference,
                                                                transactioncode,
                                                                softacctngdtls
                                                         FROM   (SELECT k_entityid,
                                                                        accountnumber,
                                                                        Cast(CASE
                                                                WHEN COALESCE(amountlcy,
                                                                     'null') =
                                                                     'null' THEN
                                                                '0.00'
                                                                WHEN amountlcy = '' THEN
                                                                '0.00'
                                                                ELSE amountlcy
                                                                             END AS DECIMAL(
                                                                             18, 3
                                                                                    ))
                                                                                amountlcy,
                                                                        Cast(CASE
                                                                WHEN COALESCE(amountfcy,
                                                                     'null') =
                                                                     'null' THEN
                                                                '0.00'
                                                                WHEN amountfcy = '' THEN
                                                                '0.00'
                                                                ELSE amountfcy
                                                                             END AS DECIMAL(
                                                                             18, 3
                                                                                    ))
                                                                                amountfcy,
                                                                        currency,
                                                        Cast(CASE
                                                                WHEN COALESCE(exchangerate
                                                                     , 'null'
                                                                     ) = 'null' THEN
                                                                '0.00'
                                                                WHEN exchangerate = ''
                                                                             THEN '0.00'
                                                                               ELSE
                                                             exchangerate
                                                                             END AS DECIMAL(
                                                             18, 3
                                                                                    ))
                                                                                exchangerate
                                                                        ,
            transreference,
            From_unixtime(Cast(
            Cast(COALESCE(k_processingtime,
            k_emittedtime
            ) AS
            BIGINT) /
            1000 AS INT), "yyyy-mm-dd hh:mm:ss")
            processingtime,
            transactioncode,
            softacctngdtls,
            Rank()
            OVER(
            partition BY accountnumber
            ORDER BY COALESCE(meta_createdtime,
            k_emittedtime),
            k_entityid ASC)
            rnk
            FROM
            #{stg_t24_schema}.fodb_stmt_entry
            v
            WHERE  COALESCE(processingdate,
            'null')
            !=
            'null'
            AND Cast(
            CASE
            WHEN
                COALESCE(
                       amountlcy,
                            'null') =
                'null'
                     THEN '0.00'
                       WHEN
                amountlcy = ''
                     THEN
                       '0.00'
                       ELSE amountlcy
                     END AS
            DECIMAL(18, 3))
                <= 0) a
            WHERE  rnk = 1
            GROUP  BY accountnumber,
            amountlcy,
            amountfcy,
            exchangerate,
            currency,
            k_entityid,
            processingtime,
            transreference,
            transactioncode,
            softacctngdtls) trns
            INNER JOIN #{dwh_base_schema}.t24_transactions
            trns_des
            ON trns.transactioncode =
            trns_des.transaction_code)
            debit
            ON main.accountnumber = debit.accountnumber
            LEFT OUTER JOIN (SELECT accountnumber,
            amountlcy,
            amountfcy,
            exchangerate,
            currency,
            k_entityid,
            processingtime,
            transreference,
            trns_des.narrative,
            softacctngdtls
            FROM   (SELECT accountnumber,
            amountlcy,
            amountfcy,
            exchangerate,
            currency,
            k_entityid,
            processingtime,
            transreference,
            transactioncode,
            softacctngdtls
            FROM   (SELECT k_entityid,
             accountnumber,
             Cast(CASE
            WHEN COALESCE(amountlcy,
            'null')
            = 'null' THEN
            '0.00'
            WHEN amountlcy = '' THEN
            '0.00'
            ELSE amountlcy
                  END AS DECIMAL(18,
                         3))
                     amountlcy,
             Cast(CASE
            WHEN COALESCE(amountfcy,
            'null')
            = 'null' THEN
            '0.00'
            WHEN amountfcy = '' THEN
            '0.00'
            ELSE amountfcy
                  END AS DECIMAL(18,
                         3))
                     amountfcy,
             currency,
             Cast(CASE
            WHEN COALESCE(exchangerate,
            'null') = 'null' THEN
            '0.00'
            WHEN exchangerate = '' THEN
            '0.00'
            ELSE exchangerate
                  END AS DECIMAL(18,
                         3))
                     exchangerate,
             transreference,
            From_unixtime(Cast(
            Cast(COALESCE(k_processingtime,
            k_emittedtime
            ) AS
            BIGINT) /
            1000 AS INT), "yyyy-mm-dd hh:mm:ss")
            processingtime,
            transactioncode,
            softacctngdtls,
            Rank()
            OVER(
            partition BY accountnumber
            ORDER BY COALESCE(meta_createdtime,
            k_emittedtime),
            k_entityid ASC)
            rnk
            FROM
            #{stg_t24_schema}.fodb_stmt_entry v
            WHERE  COALESCE(processingdate,
             'null')
             !=
             'null'
             AND Cast(
            CASE
            WHEN COALESCE
            (
            amountlcy,
            'null')
            = 'null'
            THEN '0.00'
            WHEN
                 amountlcy = ''
                      THEN
                        '0.00'
                        ELSE
                 amountlcy
                      END AS
            DECIMAL(18, 3))
                 > 0) a
            WHERE  rnk = 1
            GROUP  BY accountnumber,
            amountlcy,
            amountfcy,
            exchangerate,
            currency,
            k_entityid,
            processingtime,
            transreference,
            transactioncode,
            softacctngdtls) trns
            INNER JOIN #{dwh_base_schema}.t24_transactions
            trns_des
            ON trns.transactioncode =
            trns_des.transaction_code)
            credit
            ON main.accountnumber = credit.accountnumber)AS stg
        ) BUS_QRY
    ) HASH_PREP
) FINAL WHERE FK_UP <> 1
