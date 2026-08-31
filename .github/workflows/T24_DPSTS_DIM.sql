SELECT COUNT(*) FROM (
    SELECT hash_prep.*,
        CASE WHEN HASH_PREP.HASH_KEY = FIRST_VALUE(HASH_PREP.HASH_KEY) OVER(
            PARTITION BY HASH_PREP.ARRANGEMENT_NO ORDER BY HASH_PREP.strt_dt ASC
            ROWS BETWEEN 1 PRECEDING AND 1 PRECEDING)
        THEN 1 ELSE 0 END AS FK_UP
    FROM (
        SELECT BUS_QRY.*,
            sha2(
coalesce(CUSTOMER_ID, '') ||
coalesce(beneficial_owner, '') ||
coalesce(PRODUCTGROUP, '') ||
coalesce(ACCOUNT_REFERENCE, '') ||
coalesce(PRODUCT_NAME, '') ||
coalesce(PRODUCT_TITLE, '') ||
coalesce(ACTIVE_PRODUCT, '') ||
coalesce(CURRENCY, '') ||
coalesce(DEPOSIT_RATE, '') ||
coalesce(TIERAMOUNT, '') ||
coalesce(PAYMENTMETHOD, '') ||
coalesce(INITIALFUNDING_CHARGESSETTLEMENT_PAYINGACCOUNT, '') ||
coalesce(REDEMPTIONSETTLEMENTACCOUNT_PRINCIPLE_PAYOUT, '') ||
coalesce(INTERESTSETTLEMENT_PAYOUT_ACCOUNT, '') ||
coalesce(COMMITMENT_AMOUNT, '') ||
coalesce(PRINCIPAL_CURRENT, '') ||
coalesce(RENEWAL_PERIOD, '') ||
coalesce(CAPITALIZE_OR_NOT, '') ||
coalesce(HOLD_INTEREST, '')
            , 256) AS HASH_KEY
        FROM (
            select stg.* ,mod.HASH_KEY as old_hash_key,CURRENT_DATE AS STRT_DT
                        ,NULL                                    AS END_DTTM
            			,CURRENT_TIMESTAMP                       AS STRT_DTTM
            			           ,CURRENT_TIMESTAMP                          AS  Tec_Insrt_Dttm
            		   ,CURRENT_TIMESTAMP                          AS  Tec_Upd_Dttm
            		   ,null                          AS  DR_Dttm
            		   ,null                          AS  DR_Flg
            
            from
            ( 
            SELECT 
            A.*
            ,SHA2(COALESCE(PRODUCTGROUP,'')||COALESCE(ACCOUNT_REFERENCE,'')||COALESCE(PRODUCT_NAME,'')
            ||COALESCE(PRODUCT_TITLE,'')||COALESCE(ACTIVE_PRODUCT,'')||COALESCE(`STATUS`,'')||COALESCE(CURRENCY,'')
            ||COALESCE(START_DATE,'')||COALESCE(VALUE_DATE,'')||COALESCE( RENEWAL_DATE,'')||COALESCE(MATURITY_DATE,'')
            ||COALESCE(DEPOSIT_RATE,'')||COALESCE(TIERAMOUNT,'')||COALESCE(PAYMENTMETHOD,'') ||COALESCE(INITIALFUNDING_CHARGESSETTLEMENT_PAYINGACCOUNT,'')
            ||COALESCE(REDEMPTIONSETTLEMENTACCOUNT_PRINCIPLE_PAYOUT,'')||COALESCE(INTERESTSETTLEMENT_PAYOUT_ACCOUNT,'')
            ||COALESCE(COMMITMENT_AMOUNT,'') ||COALESCE(PRINCIPAL_CURRENT,'') ||COALESCE(NEXT_INTEREST_PAYOUT_DATE,'')
            ||COALESCE(RENEWAL_PERIOD,'') ||COALESCE(CAPITALIZE_OR_NOT,'') ||COALESCE(HOLD_INTEREST,'') , 256) HASH_KEY 
            from (
            
            SELECT 
            distinct A.RECID ARRANGEMENT_NO, 
            C.CUSTOMER CUSTOMER_ID,
            c.shortname beneficial_owner,
            trim(PRODUCTGROUP) PRODUCTGROUP, 
            ACC.LINKEDAPPLID ACCOUNT_REFERENCE, 
            trim(a.activeproduct) PRODUCT_NAME, 
            ACCT_TITLE PRODUCT_TITLE,
            trim(a.activeproduct) ACTIVE_PRODUCT,
            trim(A.ARRSTATUS) `STATUS`,
            A.CURRENCY CURRENCY, 
            case when a.startdate in ('','null') then NULL else cast(regexp_replace(startdate, '(\\d{4})(\\d{2})(\\d{2})', '$1-\$2\-\$3') as date) end START_DATE,
            VALUE_DATE, 
            RENEWAL_DATE,
            MATURITY_DATE,
            FX.EFFECTIVERATE DEPOSIT_RATE,
            FX.TIERAMOUNT TIERAMOUNT,
            --paymenttype Payment_Type,
            PYMT.PAYMENTMETHOD PAYMENTMETHOD,
            INITIAL_FUNDING_CHARGES_SETTLEMENT_PAYING_ACCOUNT INITIALFUNDING_CHARGESSETTLEMENT_PAYINGACCOUNT,
            REDEMPTION_SETTLEMENTACCOUNT_PRINCIPLEPAYOUT REDEMPTIONSETTLEMENTACCOUNT_PRINCIPLE_PAYOUT,
            INTERESTSETTLEMENT_PAYOUT_ACCOUNT INTERESTSETTLEMENT_PAYOUT_ACCOUNT, 
            COMMITMENT_AMOUNT COMMITMENT_AMOUNT,
            PRINCIPAL_AMOUNT PRINCIPAL_CURRENT,
            dts.nextdate NEXT_INTEREST_PAYOUT_DATE,
            CNG.changeperiod RENEWAL_PERIOD, 
            CASE WHEN upper(PYMT.PAYMENTMETHOD) LIKE 'CAPITALISE' THEN 'Y' ELSE 'N' END CAPITALIZE_OR_NOT, 
            Hold_interest HOLD_INTEREST,
            date_format(CURRENT_DATE, 'yyyymmdd') prt_dt
            FROM (
            SELECT a.* FROM (
            SELECT a.k_entityid, a.recid, a.currency, a.startdate, a.activechannel, a.productline, a.productgroup, a.activeproduct, a.arrstatus,
            rank() OVER (PARTITION BY a.k_entityid ORDER BY a.context_bankingdate DESC, a.k_processingtime DESC) R 
            FROM  ${stg_schema}.fodb_aa_arrangement a where a.PRODUCTLINE = 'DEPOSITS'
            and insert_date > '2025-08-01' ) a WHERE a.R = 1
            ) A
            INNER JOIN 
            (select arr.K_ENTITYID,CUSTOMER,shortname,ROW_NUMBER() over(PARTITION by recid order by k_processingtime desc)r 
             from  ${stg_schema}.fodb_aa_arrangement_customer arr left join ( select K_ENTITYID ,shortname , ROW_NUMBER() over(PARTITION by recid order by k_processingtime desc)s  from 
             ${stg_schema}.fodb_customer_shortname cust  ) cust on cust.K_ENTITYID = arr.CUSTOMER and cust.s = 1
            where arr.insert_date > '2025-08-01' 
            )c 
            ON A.K_ENTITYID = C.K_ENTITYID and c.r=1
            INNER JOIN (select recid, K_ENTITYID,linkedapplid ,ROW_NUMBER() over(PARTITION by recid order by k_processingtime desc)r 
            from  ${stg_schema}.fodb_aa_arrangement_linkedappl )acc
            ON ACC.K_ENTITYID = A.K_ENTITYID and acc.r=1
            INNER JOIN (
            SELECT
            K_ENTITYID, 
            case when MATURITYDATE in ('','null') then NULL else cast(regexp_replace(MATURITYDATE, '(\\d{4})(\\d{2})(\\d{2})',  '$1\-$\2-\$3') as date) end MATURITY_DATE ,
            case when RENEWALDATE in ('','null') then NULL else cast(regexp_replace(RENEWALDATE, '(\\d{4})(\\d{2})(\\d{2})',  '$1\-$\2-\$3') as date) end RENEWAL_DATE, 
            case when VALUEDATE in ('','null') then NULL else cast(regexp_replace(VALUEDATE, '(\\d{4})(\\d{2})(\\d{2})',  '$1\-$\2-\$3') as date) end VALUE_DATE,
            RENEWALPERIOD,
            ROLLOVERSTATUS,
            rank() OVER (PARTITION BY k_entityid ORDER BY k_processingtime DESC) R 
            FROM  ${stg_schema}.fodb_aa_account_details) acc_det 
            ON ACC_DET.K_ENTITYID = A.K_ENTITYID and acc_det.R = 1
            LEFT OUTER JOIN (
            select * from(
            SELECT 
            IDCOMP_D_1, 
            PAYMENTMETHOD, 
            b.k_entityid, 
            b.context_bankingdate,
            B.K_EMITTEDTIME, 
            ROW_NUMBER () OVER (PARTITION BY idcomp_d_1 ORDER BY B.k_processingtime DESC) R 
            FROM  ${stg_schema}.fodb_aa_arr_payment_schedule a 
            INNER JOIN  ${stg_schema}.fodb_aa_arr_payment_schedule_paymenttype b 
            ON A.RECID = B.RECID AND A.K_EVENTID = B.K_EVENTID 
            AND A.CONTEXT_COBDATE = B.CONTEXT_COBDATE
            AND A.CONTEXT_BANKINGDATE = B.CONTEXT_BANKINGDATE
            and a.insert_date > '2025-08-01' 
            and b.insert_date > '2025-08-01' 
            
            )pay
            where R = 1) pymt 
            ON PYMT.IDCOMP_D_1 = A.K_ENTITYID
            ------------------------
            LEFT OUTER JOIN (
            SELECT * FROM (
            SELECT 
            EFFECTIVERATE, 
            case when COALESCE(TRIM(TIERAMOUNT) ,'null') in ('') then 'null' end as TIERAMOUNT,
            idcomp_d_1 K_ENTITYID, 
            rank() OVER (PARTITION BY idcomp_d_1 ORDER BY substring(substring(b.k_entityid, 1, instr(b.k_entityid, '.') - 1), -8) DESC, 
            CAST(substring(b.k_entityid, instr(b.k_entityid, '.') + 1) AS FLOAT) DESC,B.k_processingtime DESC) R
            FROM  ${stg_schema}.fodb_aa_arr_interest a 
            INNER JOIN  ${stg_schema}.fodb_aa_arr_interest_fixedrate b 
            ON a.recid = b.recid AND a.k_eventid = b.k_eventid
            AND a.context_cobdate = b.context_cobdate
            AND a.context_bankingdate = b.context_bankingdate) d WHERE R = 1
            ) fx 
            ON FX.K_ENTITYID = A.K_ENTITYID
            LEFT OUTER JOIN (select * from (
            SELECT LNKTYP.K_ENTITYID, linkedapp1.LINKEDAPPLID,
            max(CASE WHEN LINKTYPE = 'PAYIN.ACCOUNT' THEN LINKEDAPPLID END) INITIAL_FUNDING_CHARGES_SETTLEMENT_PAYING_ACCOUNT, 
            max(CASE WHEN LINKTYPE = 'PAYOUT.ACCOUNT' THEN LINKEDAPPLID END) REDEMPTION_SETTLEMENTACCOUNT_PRINCIPLEPAYOUT,
            max(case when LINKTYPE = 'SETTLEMENT.ACCOUNT' THEN LINKEDAPPLID END) INTERESTSETTLEMENT_PAYOUT_ACCOUNT,
            row_number() OVER (PARTITION BY lnktyp.k_entityid ORDER BY linkedapp1.k_processingtime DESC) R
            FROM  ${stg_schema}.fodb_aa_arrangement_linkdate_linktype lnktyp 
            INNER JOIN  ${stg_schema}.fodb_aa_arrangement_linkedappl linkedapp1
            ON LNKTYP.LINKARRANGEMENT = LINKEDAPP1.K_ENTITYID and lnktyp.insert_date > '2025-08-01'
            and linkedapp1.insert_date > '2025-08-01'
            GROUP BY LNKTYP.K_ENTITYID, linkedapp1.LINKEDAPPLID ,linkedapp1.k_processingtime 
            )a 
            where a.r=1) lnktyp
            ON LNKTYP.K_ENTITYID = A.K_ENTITYID
            LEFT OUTER JOIN (
            SELECT k_entityid, 
            max(CASE WHEN typesysdate = 'TOTCOMMITMENT' THEN openbalance END) Commitment_Amount, 
            max(CASE WHEN typesysdate = 'CURACCOUNT' THEN openbalance END) Principal_AMOUNT, 
            max(CASE WHEN typesysdate = 'ACCDEPOSITINT' THEN openbalance END) Accrued_Interest, 
            max(CASE WHEN typesysdate = 'PAYDEPOSITINT' THEN openbalance END) Hold_interest
            FROM (select * from (
            SELECT typesysdate, A.k_entityid, 
            CAST(openbalance AS FLOAT) openbalance,
            rank() OVER (PARTITION BY A.k_entityid, typesysdate ORDER BY A.k_processingtime DESC) R
            FROM  ${stg_schema}.fodb_eb_contract_balances_typesysdate a
            INNER JOIN  ${stg_schema}.fodb_eb_contract_balances_typesysdate_matdate b
            ON a.recid = b.recid AND a.k_eventid = b.k_eventid 
            AND a.context_cobdate = b.context_cobdate AND a.context_bankingdate = b.context_bankingdate 
            AND a.rec_index = substr(b.rec_index, 1, 1) 
            WHERE typesysdate IN ('TOTCOMMITMENT', 'CURACCOUNT', 'ACCDEPOSITINT', 'PAYDEPOSITINT')
            and a.insert_date > '2025-08-01'  and b.insert_date > '2025-08-01' 
            )a WHERE r = 1) a
            GROUP BY k_entityid) amnt
            ON AMNT.K_ENTITYID = ACC.LINKEDAPPLID 
            ---------------
            LEFT OUTER JOIN (
            SELECT * FROM (
            SELECT ACCOUNTTITLE_D_1 ACCT_TITLE, K_ENTITYID ACCT, 
            rank() OVER (PARTITION BY K_ENTITYID ORDER BY k_processingtime DESC) R 
            FROM  ${stg_schema}.fodb_account_accounttitle_d_1 
            ) tit WHERE R = 1 
            ) title 
            ON TITLE.ACCT = ACC.LINKEDAPPLID
            LEFT OUTER JOIN  (Select * from( 
            Select idcomp_d_1,changeperiod,rank() OVER (PARTITION BY idcomp_d_1 ORDER BY k_processingtime DESC) R From  ${stg_schema}.fodb_aa_arr_change_product cng )prod where r=1
            ) cng ON CNG.idcomp_d_1 = A.K_ENTITYID
            LEFT OUTER JOIN (
            SELECT distinct * FROM 
            (
            SELECT k_entityid,
            case when nextrundate in ('','null') then NULL else cast(regexp_replace(nextrundate, '(\\d{4})(\\d{2})(\\d{2})',  '$1\-$\2-\$3') as date) end nextdate,
            case when earlyenddate in('','null')then NULL else cast(regexp_replace(earlyenddate, '(\\d{4})(\\d{2})(\\d{2})',  '$1\-$\2-\$3') as date) end lastdate,
            rank() OVER (PARTITION BY k_entityid ORDER BY k_processingtime DESC) R
            FROM  ${stg_schema}.fodb_aa_scheduled_activity where insert_date > '2025-08-01' 
            ) f WHERE R = 1
            ) dts 
            ON DTS.k_entityid = A.K_ENTITYID
            LEFT OUTER JOIN (
            SELECT sum(CAST(X.ORPROPAMOUNT AS FLOAT)) ORPROPAMOUNT, BL.arrangementid FROM  ${stg_schema}.fodb_aa_bill_details_property x
            INNER JOIN  ${stg_schema}.fodb_aa_bill_details bl 
            ON BL.k_entityid = X.k_entityid 
            WHERE property = 'DEPOSITINT' and bl.insert_date > '2025-08-01'  and x.insert_date > '2025-08-01' 
            GROUP BY BL.arrangementid) pd_int 
            ON PD_INT.arrangementid = A.K_ENTITYID 
            
            
            
            ) A 
            ) as stg
            LEFT JOIN ${mod_schema}.${table_name}  mod
            on  stg.HASH_KEY =mod.HASH_KEY and stg.ARRANGEMENT_NO = mod.ARRANGEMENT_NO
            AND MOD.END_DTTM is  null  
            where  mod.ARRANGEMENT_NO is  null
            
             
            
            union 
            select stg.* ,mod.HASH_KEY as old_hash_key
                       ,CURRENT_DATE                            AS STRT_DT
            			,NULL                                    AS END_DTTM
            			,CURRENT_TIMESTAMP                       AS STRT_DTTM
            			           ,CURRENT_TIMESTAMP                          AS  Tec_Insrt_Dttm
            		   ,CURRENT_TIMESTAMP                          AS  Tec_Upd_Dttm
            		   ,null                          AS  DR_Dttm
            		   ,null                          AS  DR_Flg
            from
            ( 
            SELECT 
            A.*
            ,SHA2(COALESCE(PRODUCTGROUP,'')||COALESCE(ACCOUNT_REFERENCE,'')||COALESCE(PRODUCT_NAME,'')
            ||COALESCE(PRODUCT_TITLE,'')||COALESCE(ACTIVE_PRODUCT,'')||COALESCE(`STATUS`,'')||COALESCE(CURRENCY,'')
            ||COALESCE(START_DATE,'')||COALESCE(VALUE_DATE,'')||COALESCE( RENEWAL_DATE,'')||COALESCE(MATURITY_DATE,'')
            ||COALESCE(DEPOSIT_RATE,'')||COALESCE(TIERAMOUNT,'')||COALESCE(PAYMENTMETHOD,'') ||COALESCE(INITIALFUNDING_CHARGESSETTLEMENT_PAYINGACCOUNT,'')
            ||COALESCE(REDEMPTIONSETTLEMENTACCOUNT_PRINCIPLE_PAYOUT,'')||COALESCE(INTERESTSETTLEMENT_PAYOUT_ACCOUNT,'')
            ||COALESCE(COMMITMENT_AMOUNT,'') ||COALESCE(PRINCIPAL_CURRENT,'') ||COALESCE(NEXT_INTEREST_PAYOUT_DATE,'')
            ||COALESCE(RENEWAL_PERIOD,'') ||COALESCE(CAPITALIZE_OR_NOT,'') ||COALESCE(HOLD_INTEREST,'') , 256) HASH_KEY
            from (
            SELECT 
            distinct A.RECID ARRANGEMENT_NO, 
            C.CUSTOMER CUSTOMER_ID,
            c.shortname beneficial_owner,
            trim(PRODUCTGROUP) PRODUCTGROUP, 
            ACC.LINKEDAPPLID ACCOUNT_REFERENCE, 
            trim(a.activeproduct) PRODUCT_NAME, 
            ACCT_TITLE PRODUCT_TITLE,
            trim(a.activeproduct) ACTIVE_PRODUCT,
            trim(A.ARRSTATUS) `STATUS`,
            A.CURRENCY CURRENCY, 
            case when a.startdate in ('','null') then NULL else cast(regexp_replace(startdate, '(\\d{4})(\\d{2})(\\d{2})', '$1-\$2\-\$3') as date) end START_DATE,
            VALUE_DATE, 
            RENEWAL_DATE,
            MATURITY_DATE,
            FX.EFFECTIVERATE DEPOSIT_RATE,
            FX.TIERAMOUNT TIERAMOUNT,
            --paymenttype Payment_Type,
            PYMT.PAYMENTMETHOD PAYMENTMETHOD,
            INITIAL_FUNDING_CHARGES_SETTLEMENT_PAYING_ACCOUNT INITIALFUNDING_CHARGESSETTLEMENT_PAYINGACCOUNT,
            REDEMPTION_SETTLEMENTACCOUNT_PRINCIPLEPAYOUT REDEMPTIONSETTLEMENTACCOUNT_PRINCIPLE_PAYOUT,
            INTERESTSETTLEMENT_PAYOUT_ACCOUNT INTERESTSETTLEMENT_PAYOUT_ACCOUNT, 
            COMMITMENT_AMOUNT COMMITMENT_AMOUNT,
            PRINCIPAL_AMOUNT PRINCIPAL_CURRENT,
            dts.nextdate NEXT_INTEREST_PAYOUT_DATE,
            CNG.changeperiod RENEWAL_PERIOD, 
            CASE WHEN upper(PYMT.PAYMENTMETHOD) LIKE 'CAPITALISE' THEN 'Y' ELSE 'N' END CAPITALIZE_OR_NOT, 
            Hold_interest HOLD_INTEREST,
            date_format(CURRENT_DATE, 'yyyymmdd') prt_dt
            FROM (
            SELECT a.* FROM (
            SELECT a.k_entityid, a.recid, a.currency, a.startdate, a.activechannel, a.productline, a.productgroup, a.activeproduct, a.arrstatus,
            rank() OVER (PARTITION BY a.k_entityid ORDER BY a.context_bankingdate DESC, a.k_processingtime DESC) R 
            FROM  ${stg_schema}.fodb_aa_arrangement a where a.PRODUCTLINE = 'DEPOSITS'
            and insert_date > '2025-08-01' ) a WHERE a.R = 1
            ) A
            INNER JOIN 
            (select arr.K_ENTITYID,CUSTOMER,shortname,ROW_NUMBER() over(PARTITION by recid order by k_processingtime desc)r 
             from  ${stg_schema}.fodb_aa_arrangement_customer arr left join ( select K_ENTITYID ,shortname , ROW_NUMBER() over(PARTITION by recid order by k_processingtime desc)s  from 
             ${stg_schema}.fodb_customer_shortname cust  ) cust on cust.K_ENTITYID = arr.CUSTOMER and cust.s = 1
            where arr.insert_date > '2025-08-01' 
            )c 
            ON A.K_ENTITYID = C.K_ENTITYID and c.r=1
            INNER JOIN (select recid, K_ENTITYID,linkedapplid ,ROW_NUMBER() over(PARTITION by recid order by k_processingtime desc)r 
            from  ${stg_schema}.fodb_aa_arrangement_linkedappl )acc
            ON ACC.K_ENTITYID = A.K_ENTITYID and acc.r=1
            INNER JOIN (
            SELECT
            K_ENTITYID, 
            case when MATURITYDATE in ('','null') then NULL else cast(regexp_replace(MATURITYDATE, '(\\d{4})(\\d{2})(\\d{2})',  '$1\-$\2-\$3') as date) end MATURITY_DATE ,
            case when RENEWALDATE in ('','null') then NULL else cast(regexp_replace(RENEWALDATE, '(\\d{4})(\\d{2})(\\d{2})',  '$1\-$\2-\$3') as date) end RENEWAL_DATE, 
            case when VALUEDATE in ('','null') then NULL else cast(regexp_replace(VALUEDATE, '(\\d{4})(\\d{2})(\\d{2})',  '$1\-$\2-\$3') as date) end VALUE_DATE,
            RENEWALPERIOD,
            ROLLOVERSTATUS,
            rank() OVER (PARTITION BY k_entityid ORDER BY k_processingtime DESC) R 
            FROM  ${stg_schema}.fodb_aa_account_details) acc_det 
            ON ACC_DET.K_ENTITYID = A.K_ENTITYID and acc_det.R = 1
            LEFT OUTER JOIN (
            select * from(
            SELECT 
            IDCOMP_D_1, 
            PAYMENTMETHOD, 
            b.k_entityid, 
            b.context_bankingdate,
            B.K_EMITTEDTIME, 
            ROW_NUMBER () OVER (PARTITION BY idcomp_d_1 ORDER BY B.k_processingtime DESC) R 
            FROM  ${stg_schema}.fodb_aa_arr_payment_schedule a 
            INNER JOIN  ${stg_schema}.fodb_aa_arr_payment_schedule_paymenttype b 
            ON A.RECID = B.RECID AND A.K_EVENTID = B.K_EVENTID 
            AND A.CONTEXT_COBDATE = B.CONTEXT_COBDATE
            AND A.CONTEXT_BANKINGDATE = B.CONTEXT_BANKINGDATE
            and a.insert_date > '2025-08-01' 
            and b.insert_date > '2025-08-01' 
            
            )pay
            where R = 1) pymt 
            ON PYMT.IDCOMP_D_1 = A.K_ENTITYID
            ------------------------
            LEFT OUTER JOIN (
            SELECT * FROM (
            SELECT 
            EFFECTIVERATE, 
            case when COALESCE(TRIM(TIERAMOUNT) ,'null') in ('') then 'null' end as TIERAMOUNT,
            idcomp_d_1 K_ENTITYID, 
            rank() OVER (PARTITION BY idcomp_d_1 ORDER BY substring(substring(b.k_entityid, 1, instr(b.k_entityid, '.') - 1), -8) DESC, 
            CAST(substring(b.k_entityid, instr(b.k_entityid, '.') + 1) AS FLOAT) DESC,B.k_processingtime DESC) R
            FROM  ${stg_schema}.fodb_aa_arr_interest a 
            INNER JOIN  ${stg_schema}.fodb_aa_arr_interest_fixedrate b 
            ON a.recid = b.recid AND a.k_eventid = b.k_eventid
            AND a.context_cobdate = b.context_cobdate
            AND a.context_bankingdate = b.context_bankingdate) d WHERE R = 1
            ) fx 
            ON FX.K_ENTITYID = A.K_ENTITYID
            LEFT OUTER JOIN (select * from (
            SELECT LNKTYP.K_ENTITYID, linkedapp1.LINKEDAPPLID,
            max(CASE WHEN LINKTYPE = 'PAYIN.ACCOUNT' THEN LINKEDAPPLID END) INITIAL_FUNDING_CHARGES_SETTLEMENT_PAYING_ACCOUNT, 
            max(CASE WHEN LINKTYPE = 'PAYOUT.ACCOUNT' THEN LINKEDAPPLID END) REDEMPTION_SETTLEMENTACCOUNT_PRINCIPLEPAYOUT,
            max(case when LINKTYPE = 'SETTLEMENT.ACCOUNT' THEN LINKEDAPPLID END) INTERESTSETTLEMENT_PAYOUT_ACCOUNT,
            row_number() OVER (PARTITION BY lnktyp.k_entityid ORDER BY linkedapp1.k_processingtime DESC) R
            FROM  ${stg_schema}.fodb_aa_arrangement_linkdate_linktype lnktyp 
            INNER JOIN  ${stg_schema}.fodb_aa_arrangement_linkedappl linkedapp1
            ON LNKTYP.LINKARRANGEMENT = LINKEDAPP1.K_ENTITYID and lnktyp.insert_date > '2025-08-01'
            and linkedapp1.insert_date > '2025-08-01'
            GROUP BY LNKTYP.K_ENTITYID, linkedapp1.LINKEDAPPLID ,linkedapp1.k_processingtime 
            )a 
            where a.r=1) lnktyp
            ON LNKTYP.K_ENTITYID = A.K_ENTITYID
            LEFT OUTER JOIN (
            SELECT k_entityid, 
            max(CASE WHEN typesysdate = 'TOTCOMMITMENT' THEN openbalance END) Commitment_Amount, 
            max(CASE WHEN typesysdate = 'CURACCOUNT' THEN openbalance END) Principal_AMOUNT, 
            max(CASE WHEN typesysdate = 'ACCDEPOSITINT' THEN openbalance END) Accrued_Interest, 
            max(CASE WHEN typesysdate = 'PAYDEPOSITINT' THEN openbalance END) Hold_interest
            FROM (select * from (
            SELECT typesysdate, A.k_entityid, 
            CAST(openbalance AS FLOAT) openbalance,
            rank() OVER (PARTITION BY A.k_entityid, typesysdate ORDER BY A.k_processingtime DESC) R
            FROM  ${stg_schema}.fodb_eb_contract_balances_typesysdate a
            INNER JOIN  ${stg_schema}.fodb_eb_contract_balances_typesysdate_matdate b
            ON a.recid = b.recid AND a.k_eventid = b.k_eventid 
            AND a.context_cobdate = b.context_cobdate AND a.context_bankingdate = b.context_bankingdate 
            AND a.rec_index = substr(b.rec_index, 1, 1) 
            WHERE typesysdate IN ('TOTCOMMITMENT', 'CURACCOUNT', 'ACCDEPOSITINT', 'PAYDEPOSITINT')
            and a.insert_date > '2025-08-01'  and b.insert_date > '2025-08-01' 
            )a WHERE r = 1) a
            GROUP BY k_entityid) amnt
            ON AMNT.K_ENTITYID = ACC.LINKEDAPPLID 
            ---------------
            LEFT OUTER JOIN (
            SELECT * FROM (
            SELECT ACCOUNTTITLE_D_1 ACCT_TITLE, K_ENTITYID ACCT, 
            rank() OVER (PARTITION BY K_ENTITYID ORDER BY k_processingtime DESC) R 
            FROM  ${stg_schema}.fodb_account_accounttitle_d_1 
            ) tit WHERE R = 1 
            ) title 
            ON TITLE.ACCT = ACC.LINKEDAPPLID
            LEFT OUTER JOIN  (Select * from( 
            Select idcomp_d_1,changeperiod,rank() OVER (PARTITION BY idcomp_d_1 ORDER BY k_processingtime DESC) R From  ${stg_schema}.fodb_aa_arr_change_product cng )prod where r=1
            ) cng ON CNG.idcomp_d_1 = A.K_ENTITYID
            LEFT OUTER JOIN (
            SELECT distinct * FROM 
            (
            SELECT k_entityid,
            case when nextrundate in ('','null') then NULL else cast(regexp_replace(nextrundate, '(\\d{4})(\\d{2})(\\d{2})',  '$1\-$\2-\$3') as date) end nextdate,
            case when earlyenddate in('','null')then NULL else cast(regexp_replace(earlyenddate, '(\\d{4})(\\d{2})(\\d{2})',  '$1\-$\2-\$3') as date) end lastdate,
            rank() OVER (PARTITION BY k_entityid ORDER BY k_processingtime DESC) R
            FROM  ${stg_schema}.fodb_aa_scheduled_activity where insert_date > '2025-08-01' 
            ) f WHERE R = 1
            ) dts 
            ON DTS.k_entityid = A.K_ENTITYID
            LEFT OUTER JOIN (
            SELECT sum(CAST(X.ORPROPAMOUNT AS FLOAT)) ORPROPAMOUNT, BL.arrangementid FROM  ${stg_schema}.fodb_aa_bill_details_property x
            INNER JOIN  ${stg_schema}.fodb_aa_bill_details bl 
            ON BL.k_entityid = X.k_entityid 
            WHERE property = 'DEPOSITINT' and bl.insert_date > '2025-08-01'  and x.insert_date > '2025-08-01' 
            GROUP BY BL.arrangementid) pd_int 
            ON PD_INT.arrangementid = A.K_ENTITYID 
            
            
            
            ) A  
            ) as stg
            right JOIN ${mod_schema}.${table_name}  mod
            on  stg.HASH_KEY =mod.HASH_KEY and stg.ARRANGEMENT_NO = mod.ARRANGEMENT_NO
            AND MOD.END_DTTM is  null  
            where  stg.ARRANGEMENT_NO  is  null
        ) BUS_QRY
    ) HASH_PREP
) FINAL WHERE FK_UP <> 1
