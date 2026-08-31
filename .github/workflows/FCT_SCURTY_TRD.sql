
  select 
    stg.*, 
    SHA2(
      COALESCE(SCURTY_KEY, '')|| COALESCE(PORTF_KEY, '')|| COALESCE(PORTF_DESC, '')|| COALESCE(Tenor, '')|| COALESCE(FACE_VAL, '')|| COALESCE(PRESENT_VAL, '')|| COALESCE(TOT_INT_AMT, '')|| COALESCE(TRD_GROS_AMT, '')|| COALESCE(TRD_CURY, '')|| COALESCE(PUR_YLD, '')|| COALESCE(MRKT_TYP, '')|| COALESCE(BROKR_KEY, '')|| COALESCE(BROKR_ACCT_KEY, '')|| COALESCE(BROKR_Name, '')|| COALESCE(CUST_KEY, '')|| COALESCE(ACCT_KEY, '')|| COALESCE(CUST_NAME, '')|| COALESCE(ACCT_OFCR_KEY, '')|| COALESCE(CUST_ACCT_CTGY, '')|| COALESCE(BROKR_ACCT_CTGY, '')|| COALESCE(MISC_ACCT_SUSP_CTGY, '')|| COALESCE(AUTHRZR, ''), 
      256
    ) as hashcode, 
    cast(current_timestamp as string) as tec_insrt_dttm, 
    cast(current_timestamp as string) as tec_upd_dttm, 
    null as dr_dttm, 
    null as dr_flg 
  from 
    (SELECT
	SEC_TRD.k_entityid AS TRD_KEY,
	SEC_TRD.COB_DT,
	SEC_TRD.TRD_DTTM,
	SEC_TRD.securitycode AS SCURTY_KEY,
	SEC_CUST.Custsecacc AS PORTF_KEY,
	SEC_ACCT.accountname AS PORTF_DESC,
    SEC_CUST.custtranscode AS TRD_TYP,
	SEC_TRD.tradedate AS TRD_Dt,
	SEC_TRD.valuedate  AS VAL_Dt,
	SEC_TRD.Maturitydate AS MAT_DT,
	SEC_TRD.lastpaymntdate AS LST_PYMT_DT,
	Datediff(Maturitydate,tradedate) AS Tenor,
	SEC_CUST.custtotnom AS FACE_VAL,
	SEC_CUST.cunetamtrd AS PRESENT_VAL,
	SEC_CUST.Custintramt AS TOT_INT_AMT,
	SEC_CUST.cugrossamtrd AS TRD_GROS_AMT,
	SEC_TRD.tradeccy AS TRD_CURY,
	SEC_TRD.lticketytm AS PUR_YLD,
	SEC_TRD.markettype AS MRKT_TYP,
	SEC_BRKR.brokerno AS BROKR_KEY,
	SEC_BRKR.braccno AS BROKR_ACCT_KEY,
	BRKR_DTL.shortname AS BROKR_Name,
	SEC_CUST.customerno AS CUST_KEY,
	SEC_CUST.custaccno  AS ACCT_KEY,
	CUST_DTL.shortname  AS Cust_Name,
	SEC_ACCT.accountofficer AS ACCT_OFCR_KEY,
	SEC_TRD.custactsuspcat AS CUST_ACCT_CTGY,
	SEC_TRD.brokactsuspcat AS BROKR_ACCT_CTGY,
	SEC_TRD.miscactsuspcat AS MISC_ACCT_SUSP_CTGY,
	SEC_TRD.authoriser AS AUTHRZR
	
FROM
	(
		SELECT *
		FROM
		(
				SELECT 
				k_entityid,
				from_unixtime(unix_timestamp(CASE When context_cobdate in ('','null') or context_cobdate is Null Then context_bankingdate ELSE context_cobdate End ,'yyyyMMdd'),'yyyy-MM-dd') COB_DT,
				securitycode,
				tradeccy,
				Cast(CASE WHEN TRIM(lticketytm) IN('','null') or TRIM(lticketytm) is null THEN '1.00' ELSE lticketytm END AS DECIMAL(6,4)) AS lticketytm,
				markettype,
				authoriser,
				custactsuspcat,
				brokactsuspcat,
				miscactsuspcat,
				from_unixtime(unix_timestamp(tradedate,'yyyyMMdd'),'yyyy-MM-dd') AS tradedate,
				from_unixtime(unix_timestamp(valuedate,'yyyyMMdd'),'yyyy-MM-dd')  AS valuedate,
				from_unixtime(unix_timestamp(Maturitydate,'yyyyMMdd'),'yyyy-MM-dd')  AS Maturitydate,
				from_unixtime(unix_timestamp(lastpaymntdate,'yyyyMMdd'),'yyyy-MM-dd') AS lastpaymntdate,
				
				Cast(from_unixtime(Cast(Cast(k_processingtime as BIGINT) / 1000 as int), "yyyy-MM-dd HH:mm:ss") AS TIMESTAMP) TRD_DTTM,
				ROW_NUMBER() over(PARTITION by k_entityid ORDER by k_processingtime desc ) rnk
			
				FROM stg_t24.fodb_sec_trade
				WHERE  
				CASE When context_cobdate in ('','null') or context_cobdate is Null Then context_bankingdate ELSE context_cobdate End 
				BETWEEN ${STRT_DT}  AND ${END_DT}
		)SCURTY_TRD
		WHERE rnk = 1
	)SEC_TRD
	
	LEFT JOIN 
	(
		SELECT * 
		FROM 
		(		SELECT 
				k_entityid,
				custtranscode,
				Cast(CASE WHEN TRIM(custtotnom) IN('','null')   or custtotnom is null THEN '0.00' ELSE custtotnom END  AS DECIMAL(18,4)) AS custtotnom,
	            Cast(CASE WHEN TRIM(cugrossamtrd) IN('','null') or cugrossamtrd is null THEN '0.00' ELSE cugrossamtrd END  AS DECIMAL(18,4)) AS cugrossamtrd,
				Cast(CASE WHEN TRIM(Custintramt) IN('','null')  or Custintramt is null THEN '0.00' ELSE Custintramt END  AS DECIMAL(18,4)) AS Custintramt,
				Cast(CASE WHEN TRIM(cunetamtrd) IN('','null')   or Custintramt is null THEN '0.00' ELSE cunetamtrd END  AS DECIMAL(18,4)) AS cunetamtrd,
				custsecacc,
				custaccno,
				customerno,
				ROW_NUMBER() over(PARTITION by k_entityid ORDER by k_processingtime desc ) rnk
			
				FROM stg_t24.fodb_sec_trade_customerno
				
		)CUST
		WHERE RNK = 1
	)SEC_CUST
	ON SEC_CUST.k_entityid = SEC_TRD.k_entityid 
	
	
	LEFT JOIN 
	(
		select * 
        from 
		(		
		        SELECT DISTINCT
				k_entityid,
				accountofficer,
				accountname,
			    ROW_NUMBER() over(PARTITION by k_entityid ORDER by k_processingtime desc ) rnk
			
				
				FROM stg_t24.fodb_sec_acc_master
		)ACCT_KEY
		where rnk = 1
	)SEC_ACCT 
	ON SEC_ACCT.k_entityid = SEC_CUST.custsecacc 
	
	
	LEFT JOIN 
	(
		SELECT * 
		FROM
		(
				SELECT
				K_ENTITYID,
				brokerno,
				braccno,
				ROW_NUMBER () OVER (PARTITION BY k_entityid	ORDER BY k_processingtime desc) AS rnk
				
				FROM stg_t24.fodb_sec_trade_brokerno
				
		)BRKR
		WHERE RNK = 1
	)SEC_BRKR
	ON SEC_BRKR.k_entityid = SEC_TRD.k_entityid
	
	
	LEFT JOIN
	(
			SELECT
			k_entityid,
			shortname,
			Rank() OVER (PARTITION BY k_entityid ORDER BY k_processingtime DESC) rnk
			
			FROM stg_t24.fodb_customer_shortname 
			WHERE rec_index = '0'
	)CUST_DTL
	ON CUST_DTL.k_entityid = SEC_CUST.customerno
	AND CUST_DTL.rnk = 1
		
	LEFT JOIN
	(
			SELECT
			k_entityid,
			shortname,
			Rank() OVER (PARTITION BY k_entityid ORDER BY k_processingtime DESC) rnk
			
			FROM stg_t24.fodb_customer_shortname 
			WHERE rec_index = '0'
	)BRKR_DTL
	ON BRKR_DTL.k_entityid = SEC_BRKR.brokerno
	AND BRKR_DTL.rnk = 1
	  ) as stg
