
SELECT
	DISTINCT
	  T.RRN AS TRX_Key  	,--PK--
	T.ID AS TRX_NUmber 	, 
	COALESCE( CUST.CUST_ID_NUM ,
	crd_det.cust_id_num ,
	-1) AS CUST_Key	,
	COALESCE(T.ACNUM1 ,
	acct_det.accno ,
	-1 ) AS ACCT_Key
	,
	CASE
		WHEN T.CRDDET_ID <> 0
		OR T.CRDDET_ID IS NULL THEN T.CRDDET_ID
		ELSE COALESCE(crd_det.id ,
		-1)
	END AS CRD_Key	,
	T.PAN	,
	T.PAN_DISPLAY	,
	CAST(T.TXNCODE AS INT) AS TRX_TYP_KEY	,
	TYP.DESCR AS TRX_TYP			,
	CASE 
		  WHEN CAST(T.TXNCODE AS INT)= 0
		AND T.SUB_TXNCODE = '00' THEN 'Default logic'
		WHEN CAST(T.TXNCODE AS INT)= 0
		AND T.SUB_TXNCODE = '01' THEN 'Transit, Debt Recovery'
		WHEN CAST(T.TXNCODE AS INT)= 0
		AND T.SUB_TXNCODE = '02' THEN 'Incremental Authorisation'
		WHEN CAST(T.TXNCODE AS INT)= 0
		AND T.SUB_TXNCODE = '03' THEN 'Transit, Unknown'
		WHEN CAST(T.TXNCODE AS INT)= 0
		AND T.SUB_TXNCODE = '04' THEN 'Transit, Prefunded'
		WHEN CAST(T.TXNCODE AS INT)= 0
		AND T.SUB_TXNCODE = '05' THEN 'Transit, Real-Time Authorised'
		WHEN CAST(T.TXNCODE AS INT)= 0
		AND T.SUB_TXNCODE = '06' THEN 'Transit, Post-Authorised Aggregated'
		WHEN CAST(T.TXNCODE AS INT)= 0
		AND T.SUB_TXNCODE = '07' THEN 'Transit, Authorised Agg Split Clear'
		WHEN CAST(T.TXNCODE AS INT)= 0
		AND T.SUB_TXNCODE = '08' THEN 'Transit, Other'
		WHEN CAST(T.TXNCODE AS INT)= 0
		AND T.SUB_TXNCODE = '09' THEN 'Transit, Post-Authorised Agg Maestro PayPass'
		WHEN CAST(T.TXNCODE AS INT)= 0
		AND T.SUB_TXNCODE = '10' THEN 'Network Installment'
		WHEN CAST(T.TXNCODE AS INT)= 10
		AND T.SUB_TXNCODE = '00' THEN 'Default logic'
		WHEN CAST(T.TXNCODE AS INT)= 10
		AND T.SUB_TXNCODE = '01' THEN 'VMT Account Funding txn'
		WHEN CAST(T.TXNCODE AS INT)= 26
		AND T.SUB_TXNCODE = '00' THEN 'Default logic'
		WHEN CAST(T.TXNCODE AS INT)= 26
		AND T.SUB_TXNCODE = '01' THEN 'VMT OCT/Fast Funds'
		WHEN CAST(T.TXNCODE AS INT)= 93
		AND T.SUB_TXNCODE = '00' THEN 'Default logic'
		WHEN CAST(T.TXNCODE AS INT)= 93
		AND T.SUB_TXNCODE = '01' THEN 'Purchase Account Status Inquiry'
		WHEN CAST(T.TXNCODE AS INT)= 93
		AND T.SUB_TXNCODE = '02' THEN 'Payment Account Status Inquiry'
		WHEN CAST(T.TXNCODE AS INT)= 93
		AND T.SUB_TXNCODE = '03' THEN 'MoneySend Payment Account Status Inquiry'
		WHEN CAST(T.TXNCODE AS INT)= 99
		AND T.SUB_TXNCODE = '00' THEN 'Purchase Account Status Inquiry'
		WHEN CAST(T.TXNCODE AS INT)= 99
		AND T.SUB_TXNCODE = '01' THEN 'Activation request'
		WHEN CAST(T.TXNCODE AS INT)= 99
		AND T.SUB_TXNCODE = '02' THEN 'Activation code notification'
		WHEN CAST(T.TXNCODE AS INT)= 109
		AND T.SUB_TXNCODE = '01' THEN 'ATC Update'
	END AS TRX_SUB_TYP 		,
	CASE 
		WHEN (
				T.POSCHP = '5'
		OR
				T.POSCHP = '4'
		OR 
				T.POSCHAM = '9'
		OR 
				T.POSCHAM = 'S'
		OR 
				T.POSCDIM = 'S'
		OR 
				T.POSCDIM = 'T'
		OR
				T.POSCDIM = 'V'
		OR
				T.POSCDIM = 'U'
		OR 
				T.POSCDIM = 'A'
		OR 
				T.POSCDIM = 'B'
		OR 
				T.POSCDIM = 'C'
			 ) THEN 'E-Commerce'
		WHEN NOT (T.POSCHP = '5'
		OR T.POSCHP = '4'
		OR T.POSCHAM = '9'
		OR T.POSCHAM = 'S'
		OR T.POSCDIM = 'S'
		OR T.POSCDIM = 'T'
		OR T.POSCDIM = 'V'
		OR T.POSCDIM = 'U'
		OR T.POSCDIM = 'A'
		OR T.POSCDIM = 'B'
		OR T.POSCDIM = 'C')
		AND (CAST(T.TXNCODE AS INT) = 0 ) THEN 'POS Purchase'
		WHEN CAST(T.CRDACPTBUS AS INT) IN(6011, 6010) THEN 'ATM'
		ELSE TYP.DESCR
	END AS TRX_CHNL 
	 ,
	CASE
		WHEN XX.eci IN ('07') THEN TRUE
		ELSE FALSE
	END CNTCTlESS_flg
		    ,
	T.AIID 	,
	CASE
		WHEN T.AIID = '3232011088' THEN 'onebank'
		WHEN T.AIID = '3232011089' THEN 'BM'
		ELSE 'OTHERS'
	END AS ATM_TYP
	,
	T.TXNSTATUS AS TRX_STS_KEY
	,
	STS.DESCR AS TRX_STS
	,
	CASE 
		WHEN T.TXNSTATUS = 7 THEN TRUE
		ELSE FALSE
	END is_approved 
	,
	CAST(from_unixtime(CAST(T.DATELOCAL AS BIGINT) DIV 1000) AS date) AS TRX_DT_AT_ORGIN  	
	, 
	CONCAT(
	CAST(CAST(from_unixtime(CAST(T.DATEXMIT AS BIGINT) DIV 1000) AS date) AS STRING) 
	, ' '
	, SUBSTR(LPAD(t.timexmit, 6, '0'), 1, 2)
	, ':'
    , SUBSTR(LPAD(T.timexmit, 6, '0'), 3, 2)
	, ':'
	, SUBSTR(LPAD(T.timexmit, 6, '0'), 5, 2)
	) AS OTHR_SYS_TRX_DT_GMT   
	,
	from_utc_timestamp(CONCAT(
	CAST(CAST(from_unixtime(CAST(T.DATEXMIT AS BIGINT) DIV 1000) AS date) AS STRING) 
	, ' '
	, SUBSTR(LPAD(t.timexmit, 6, '0'), 1, 2)
	, ':'
    , SUBSTR(LPAD(T.timexmit, 6, '0'), 3, 2)
	, ':'
	, SUBSTR(LPAD(T.timexmit, 6, '0'), 5, 2)
	) ,
	'Africa/Cairo') AS OTHR_SYS_TRX_DT
	--, T.when_created  Entry_DT 
	, 
	   SUBSTR( t.when_created ,
	1,
	4) 
	 || '-' 
	 || SUBSTR( t.when_created ,
	5,
	2)
	 || '-'
	 || SUBSTR( t.when_created ,
	7,
	2)
	 || ' ' 
	 || SUBSTR(t.when_created ,
	9,
	2)
	 || ':'
     || SUBSTR( T.when_created ,
	11,
	2)
	 || ':'
	 || SUBSTR(T.when_created,
	13,
	2) AS Entry_dttm
	,
	CAST(from_unixtime(CAST( T.CTXDATE AS BIGINT) div 1000 ) AS date) AS SYS_DT
	---@Cortex System
	,
	CAST(from_unixtime(CAST( T.DATESET AS BIGINT) div 1000 ) AS date) AS STLMT_DT
	,
	CASE 
		    WHEN (CAST(T.TXNCODE AS INT) BETWEEN 20 AND 29 )
		AND T.MSGCLS != '4' THEN '001'
		WHEN (CAST(T.TXNCODE AS INT) BETWEEN 20 AND 29)
		AND T.MSGCLS = '4' THEN '000'
		WHEN (CAST(T.TXNCODE AS INT) < 20
		OR CAST(T.TXNCODE AS INT)> 29)
		AND T.MSGCLS != '4' THEN '000'
		WHEN (CAST(T.TXNCODE AS INT) < 20
		OR CAST(T.TXNCODE AS INT) > 29)
		AND T.MSGCLS = '4' THEN '001'
		ELSE
		 CAST(CAST(T.TXNCODE AS INT) AS CHAR(5) )
	END AS TRX_DBT_CR_CD	
	,
	CASE
		WHEN (CAST(T.TXNCODE AS INT) BETWEEN 20 AND 29)
		AND T.MSGCLS != '4' THEN 'CREDIT'
		WHEN (CAST(T.TXNCODE AS INT) BETWEEN 20 AND 29)
		AND T.MSGCLS = '4' THEN 'DEBIT'
		WHEN (CAST(T.TXNCODE AS INT) < 20
		OR CAST(T.TXNCODE AS INT) > 29)
		AND T.MSGCLS != '4' THEN 'DEBIT'
		WHEN (CAST(T.TXNCODE AS INT) < 20
		OR CAST(T.TXNCODE AS INT) > 29)
		AND T.MSGCLS = '4' THEN 'CREDIT'
		ELSE CAST(CAST(T.TXNCODE AS INT) AS CHAR(5) )
	END AS TRX_DBT_CR		
	,
	T.TRN AS TRX_REF
	,
	T.ARN						
	,
	T.ACTYPE1 AS actype1
	,
	T.ACNUM2 AS DESTN_ACCT_KEY  
	,
	T.ACTYPE2 AS DESTN_ACCT_TYP	
	,
	APP.CODE AS APPRV_AUTH_CD
	,
	CASE
		WHEN APP.ACTIONCODE = '0' THEN 'Aauthorisation approved'
		WHEN APP.ACTIONCODE = '1' THEN 'Authorisation denied'
		WHEN APP.ACTIONCODE = '2' THEN 'Authorisation denied, pickup'
		WHEN APP.ACTIONCODE = '3' THEN 'File actions'
		WHEN APP.ACTIONCODE = '4' THEN 'Reversal/chargeback actions'
		WHEN APP.ACTIONCODE = '5' THEN 'Reconciliation'
		WHEN APP.ACTIONCODE = '6' THEN 'Administrative'
		WHEN APP.ACTIONCODE = '7' THEN 'Fee collection'
		WHEN APP.ACTIONCODE = '8' THEN 'Network management'
		WHEN APP.ACTIONCODE = '9' THEN 'Error response action'
		ELSE APP.ACTIONCODE
	END AS APPRV_ACTN_DSC
	,
	APP.ALLOCDATE AS APPVL_DT
	,
	T.SCHEME AS SCHEME_KEY
	,
	T.AMTTXN AS TRX_AMT
	,
	T.CURTXN AS TRX_CURY_CD
	,
	CURRENCY.ALPHACODE AS TRX_CURY_KEY	
	,
	CASE
    	 WHEN CURRENCY.ALPHACODE = 'EGP'   THEN CAST(T.AMTTXN AS DECIMAL (24,4))
	 WHEN CURRENCY.ALPHACODE <> 'EGP' AND CURBILL.ALPHACODE ='EGP' THEN  CAST(T.AMTBILL AS DECIMAL (24,4)) 
	 ELSE '0.00'
	END AS TRX_AMT_EQUV_EGP	,
	T.AMTSET AS STLMT_AMT	,
	T.RATESET AS STLMT_RT	,
	T.CURSET AS STLMT_CURY_CD	,
	STLMT_CURY.ALPHACODE AS STLMT_CURY_kEY	,
	T.AMTBILL AS BILL_AMT	,
	T.RATEBILL AS BILL_RT	,
	T.CURBILL AS BILL_CURY_CD	,
	CURBILL.ALPHACODE AS BILL_CURY_KEY	,
	T.AMTBILLCB AS BILL_AMT_CB	 ,
	T.amt_issuer_com AS AMT_ISSUR_COM	 ,
	T.cur_issuer_com AS ISSUR_COM_CURY_CD	 ,
	ISSUR_COM_CURY.ALPHACODE AS ISSUR_COM_CURY_KEY	,
	T.AMTTXNFEE AS TRX_FEE	,
	T.AMTPROCFEE AS TRX_PRCSG_FEE	,
	T.AMTTXNORG AS TRX_AMT_ORG	,
	T.AMTTXNCB AS TRX_AMT_CB 	,
	T.SIID AS STLMT_INST_KEY	,
	T.SIIDCOUNTRY AS STLMT_INST_CNTRY_KEY	,
	T.REJREASON AS TRX_REJ_KEY		,
	REJ.DESCR AS TRX_REJ				,
	PRD.DESCR	,
	CASE
		WHEN PRD.DESCR LIKE 'PP%' THEN 'PP'
		WHEN PRD.DESCR LIKE 'DB%' THEN 'DB'
		WHEN PRD.DESCR LIKE 'Credit%' THEN 'CC'
		ELSE '-1'
	END AS CRD_CLS	,
	T.SVCCODE AS SVC_CD,
	CASE  
		WHEN Substr(T.SVCCODE,
		0,
		1) = 0 THEN 'National Card'
		WHEN Substr(T.SVCCODE,
		0,
		1) = 1 THEN 'International card'
		WHEN Substr(T.SVCCODE,
		0,
		1) = 2 THEN 'International ICC card'
		WHEN Substr(T.SVCCODE,
		0,
		1) = 5 THEN 'National use only'
		WHEN Substr(T.SVCCODE,
		0,
		1) = 6 THEN 'National use only ICC card'
		WHEN Substr(T.SVCCODE,
		0,
		1) = 7 THEN 'Proprietary card scheme'
		WHEN Substr(T.SVCCODE,
		0,
		1) = 9 THEN 'Test card'
		ELSE 'Unknown'
	END Card_Usage_Type   ,
	CASE  
		WHEN Substr(T.SVCCODE,
		1,
		1) = 0 THEN 'Normal authorization'
		WHEN Substr(T.SVCCODE,
		1,
		1) = 2 THEN 'Online authorization required'
		WHEN Substr(T.SVCCODE,
		1,
		1) = 4 THEN 'Online auth required unless special agreement'
		ELSE 'Unknown'
	END Card_Auth_rul	,
	T.TERMCODE AS TERM_CD	,
	T.TERMTYPE AS TERM_TYP_KEY	,
	TERM_TYP.DESCR AS TERM_TYP		,
	T.TERMSEQ AS TERM_SEQ	,
	T.CRDSEQNO AS CRD_SEQ_KEY	,
	T.DATEEXP AS EXP_DT	,
	XX.ISO_DE003 AS PROC_CD			,
	IFE.FECODE AS ISSUR_FEE_Key 	,
	IFE.DESCR AS ISSUR_FEE_DESCR	,
	AFE.FECODE AS ACQR_FEE_Key	,
	AFE.DESCR AS ACQR_FEE_DESCR	,
	T.CRDACPTID AS CRD_ACPT_KEY	,
	T.CRDACPTLOC_NAME AS CRD_ACPT_NM	,
	T.CRDACPTLOC AS CRD_ACPT_LOC	,
	T.CRDACPTLOC_STREET AS CRD_ACPT_ST		,
	UPPER(T.CRDACPTLOC_CITY) AS CRD_ACPT_CTY	,
	T.CRDACPTLOC_POSTCODE AS CRD_ACPT_PC		,
	T.CRDACPTLOC_REGION AS CRD_ACPT_REG			,
	T.CRDACPTLOC_COUNTRY AS CRD_ACPT_CNTRY_KEY		,
	T.CRDACPTBUS AS CRD_ACPT_BUS_KEY	,
	BUS.DESCR AS CRD_ACPT_BUS  	,
	T.POSCHIC AS POS_CHIC_KEY 	,
	CHIC.DESCR AS POS_CHIC	  	,
	T.POSCHAC AS POS_CHAC_KEY	,
	CHAC.DESCR AS POS_CHAC  	,
	T.POSCRC AS POS_CRC_KEY		,
	CRC.DESCR AS POS_CRC	 	,
	T.POSOE AS POS_OE_KEY		,
	OE.DESCR AS POS_OE	 		,
	T.POSCHP AS POS_CHP_KEY		,
	CHP.DESCR AS POS_CHP	 	,
	T.POSCP AS POS_CP_KEY		,
	CP.DESCR AS POS_CP	 		,
	T.POSCDIM AS POS_CDIM_KEY	,
	CDIM.DESCR AS POS_CDIM	 	,
	T.POSCHAM AS POS_CHAM_KEY	,
	CHAM.DESCR AS POS_CHAM	 	,
	T.POSCHA AS POS_CHA_KEY		,
	CHA.DESCR AS POS_CHA	 	,
	T.POSCHAD AS POS_CHAD_KEY	,
	CHAD.DESCR AS POS_CHAD	 	,
	T.POSSD AS POS_SD_KEY		,
	SD.DESCR AS POS_SD	 		,
	T.POSPCC AS POS_PCC_KEY		,
	PCC.DESCR AS POS_PCC		,
	T.POSCC_89 AS POS_CC_89_KEY ,
	CC.DESCR AS POS_CC_89		
	,
	T.AIID AS ACQRR_KEY
	,
	T.ACQCOUNTRY AS ACQRR_CNTRY_KEY
	     ,
	CAST(from_unixtime(CAST( T.DATEXMITORG AS BIGINT) DIV 1000) AS date) AS TRX_REV_DT
  	,
	CASE
		WHEN T.MSGCLS = '1' THEN 'Authorization'
		WHEN T.MSGCLS = '2' THEN 'Financial'
		WHEN T.MSGCLS = '3' THEN 'File Update'
		WHEN T.MSGCLS = '4' THEN 'Reversal or Chargeback'
		WHEN T.MSGCLS = '5' THEN 'Reconciliation'
		WHEN T.MSGCLS = '6' THEN 'Administrative'
		WHEN T.MSGCLS = '7' THEN 'Fee Collection'
		WHEN T.MSGCLS = '8' THEN 'Network Management'
		ELSE T.MSGCLS
	END AS MSG_CLS
,
	T.MSGCLSORG AS MSG_REV_CLS
	,
	CASE
		WHEN T.MSGFN = '0' THEN 'Request'
		WHEN T.MSGFN = '1' THEN 'Request response'
		WHEN T.MSGFN = '2' THEN 'Advice'
		WHEN T.MSGFN = '3' THEN 'Advice response'
		WHEN T.MSGFN = '4' THEN 'Notification'
		ELSE T.MSGFN
	END AS MSG_FN
,
	T.MSGFNORG AS MSG_REV_FN
	,
	CASE
		WHEN T.TXNSRC = '0' THEN 'Acquirer'
		WHEN T.TXNSRC = '1' THEN 'Acquirer repeat'
		WHEN T.TXNSRC = '2' THEN 'Issuer'
		WHEN T.TXNSRC = '3' THEN 'Issuer repeat'
		WHEN T.TXNSRC = '4' THEN 'Other'
		WHEN T.TXNSRC = '5'
		THEN 'Other repeat'
		ELSE T.TXNSRC
	END AS TRX_SRC
	,
	T.TXNSRCORG AS TRX_REV_SRC
	,
	T.FNCODE AS MSG_FN_CD
	,
	FN.DESCR AS MSG_FN_CD_DESCR		
,
	CASE
		WHEN T.ACTIONCODE = '0' THEN 'Aauthorisation approved'
		WHEN T.ACTIONCODE = '1' THEN 'Authorisation denied'
		WHEN T.ACTIONCODE = '2' THEN 'Authorisation denied, pickup'
		WHEN T.ACTIONCODE = '3' THEN 'File actions'
		WHEN T.ACTIONCODE = '4' THEN 'Reversal/chargeback actions'
		WHEN T.ACTIONCODE = '5' THEN 'Reconciliation'
		WHEN T.ACTIONCODE = '6' THEN 'Administrative'
		WHEN T.ACTIONCODE = '7' THEN 'Fee collection'
		WHEN T.ACTIONCODE = '8' THEN 'Network management'
		WHEN T.ACTIONCODE = '9' THEN 'Error response action'
		ELSE T.ACTIONCODE
	END AS ACTN_CD
	,
	T.RSPCODE AS RSP_CD_KEY
	,
	RSP_CD.DESCR AS RSP_CD			
	,
	RSP_CD.ACTIONCODE AS ACTN_KEY    
	,
	T.REASONCODE AS REASON_CD_KEY
	,
	REASONCODE.DESCR AS REASON_CD		
	,
	T.APRVLCODE AS APRVL_CD
	,
	T.VERCODES AS VER_CD				
	,
	CASE
		WHEN UPPER(T.OP)= 'D' THEN 'DELETED'
		ELSE 'ACTIVE'
	END TEC_STS
	,
	CURRENT_TIMESTAMP AS INS_DTTM
	,
	TO_DATE(T.DATELOCAL) AS TECH_TRX_DT,
	CAST(current_timestamp AS string) AS tec_insrt_dttm,
	CAST(current_timestamp AS string) AS tec_upd_dttm,
	CAST(NULL AS TIMESTAMP) AS dr_dttm,		
	CAST(NULL AS TIMESTAMP) AS dr_flg
	
 FROM
	(
	SELECT
		*
	FROM
		(
		SELECT
			* ,
			ROW_NUMBER() OVER(PARTITION BY rrn ORDER BY ID DESC, VERNO_CTX DESC , TEC_INSRT_DTTM DESC ) rn
		FROM
			(
			SELECT
				* ,
			ROW_NUMBER() OVER(PARTITION BY ID ORDER BY VERNO_CTX DESC , TEC_INSRT_DTTM DESC ) rn_ID
			FROM
				${stg_schema}.TLOG
				WHERE trim(RRN) <> ''
 --			WHERE tec_insrt_dttm => days_add(current_date, - 4)
 
	        )T_00
			WHERE
			RN_ID = 1
			)T0
	WHERE
		RN = 1 
)T
LEFT OUTER JOIN 
(
	SELECT *
	FROM 
	(SELECT
		verno_ctx,
		cust_id_num,
		branch_id,
		crdproduct_id,
		crdprogram_id,
		classid,
		pan,
		seqno,
		expdate,
		effdate,
		cyclen,
		cycbegin,
		amtauth,
		amtrem,
		blkamt,
		statcode,
		batch,
		crdsmade,
		pinsmade,
		cvv,
		pvki,
		pvv,
		lang,
		title,
		firstname,
		lastname,
		discret,
		usrdata,
		svccode,
		aci,
		offauth,
		kinship,
		date_statchg,
		old_cvv,
		old_expdate,
		renew,
		corp,
		date_birth,
		offlim,
		cvc,
		oldcvc,
		embossname,
		additionalno,
		date_created,
		applno,
		atc,
		old_atc,
		fallbackcnt,
		old_fallbackcnt,
		addrind,
		scriptstat,
		oldscrstat,
		dlv_method,
		cscs,
		oldcscs,
		crddesign_id,
		deliv_brncode,
		old_crdproduct_id,
		old_statcode,
		crdauth_params,
		preauth_blk,
		preauth_blk_old,
		preauth_unclr,
		preauth_unclr_old,
		preauth_blk_lim,
		preauth_tot_lim,
		id,
		pan_display,
		iss_host_code,
		iss_host_crdref,
		l10n_title,
		l10n_firstname,
		l10n_lastname,
		cat_params,
		accdet_id,
		custdet_id,
		cat_issrisk_id,
		cat_isscomm_id,
		notify_options,
		last_activity,
		ctta,
		ctta_old,
		csta,
		csta_old,
		cttaul,
		cttaul_old,
		preauth_amtcrpt,
		preauth_amtcrpt_old,
		preauth_tlogid,
		preauth_tlogid_old,
		preauth_txnflags,
		preauth_txnflags_old,
		ext_custnum,
		crdactstat,
		old_crdactstat,
		pinstatus_id,
		pinstatus_old_id,
		bin_flags,
		emvcrdseqno,
		emvcrdseqno_old,
		additionaltype,
		tec_insrt_dttm,
		tec_upd_dttm,
		dr_dttm,
		dr_flg,
		op,
		ts_ms 
      ,	ROW_NUMBER() OVER(PARTITION BY PAN	ORDER BY	verno_ctx DESC ,tec_insrt_dttm DESC) RN
		FROM
		stg_cor.crddet
		) crd_det
		 WHERE RN=1
) crd_det
ON
	t.pan = crd_det.pan
	
LEFT OUTER JOIN 
(
		SELECT *
 		FROM  (
		SELECT *  , row_number() over(PARTITION BY id ORDER BY verno_ctx desc ,tec_insrt_dttm desc) RN
		FROM ${stg_schema}.ACCITEMS 
		WHERE  tlogid <> '0'
		)AC_01
		WHERE RN=1
) Ac
ON
	T.id = ac.tlogid
LEFT OUTER JOIN
	
	(
	SELECT * FROM 
	(
	SELECT * , ROW_NUMBER() OVER(PARTITION BY CRDPRODUCT ORDER BY VERNO_CTX DESC  ,tec_insrt_dttm  DESC  )  RN
	FROM  
	${stg_schema}.CRDPRODUCT 
	)	
	PRD_01 
	 WHERE RN=1
	)PRD 
	ON
	crd_det.crdproduct_id = PRD.prodnum
	 
LEFT OUTER JOIN 
	 (
	SELECT
		ID ,
		accdet_id
	FROM
		(
		SELECT
			ID ,
			accdet_id ,
			ROW_NUMBER() OVER(PARTITION BY id	ORDER BY	verno_ctx DESC , CAST(tec_insrt_dttm AS timestamp ) DESC ) RN
		FROM
			${stg_schema}.crddet   
	     ) X1
	WHERE
		RN = 1
	  ) X
	 ON
	 T.CRDDET_ID = x.ID
LEFT OUTER JOIN 
    (
	SELECT
		*
	FROM
		(
		SELECT
			* ,
			ROW_NUMBER() OVER(PARTITION BY id ORDER BY verno_ctx DESC , CAST(tec_insrt_dttm AS timestamp ) DESC ) RN
		FROM
			${stg_schema}.accdet
    )acct_det_1
	WHERE
		rn = 1
    ) acct_det
	 ON
	 crd_det.accdet_id = acct_det.id
LEFT JOIN 
(
SELECT * 
FROM 
(
SELECT * , ROW_NUMBER() OVER(PARTITION BY inst_id, FECODE ORDER BY VERNO_CTX DESC ,tec_insrt_dttm DESC ) RN
FROM 
${stg_schema}.FE 
) FE_01
 WHERE RN=1 
 )AS IFE					
	ON
	T.IFE = IFE.FECODE
LEFT JOIN
(
SELECT * 
FROM 
(
SELECT * , ROW_NUMBER() OVER(PARTITION BY inst_id, FECODE ORDER BY VERNO_CTX DESC ,tec_insrt_dttm DESC ) RN
FROM 
${stg_schema}.FE 
) AFE_01
 WHERE RN=1 
 
 )AS AFE					
ON
	T.AFE = AFE.FECODE
	
LEFT JOIN 
(
SELECT * 
FROM 
(
SELECT *   , row_number() over(PARTITION BY id ,TLOGID  ORDER BY verno_ctx  desc ,tec_insrt_dttm desc ) RN
FROM  
${stg_schema}.APRVLCODE 
) APP_01
WHERE RN=1
) APP
ON
	T.ID = APP.TLOGID
LEFT JOIN
	-- 
	(
	SELECT * 
 	FROM  
  	(SELECT *  , ROW_NUMBER() OVER(PARTITION BY   ID  ,TLOG_ID  ORDER BY tec_insrt_dttm DESC )  RN
	FROM  
	${stg_schema}.TLOG_X
	) XX_01
	 WHERE RN=1
	)XX
ON
	T.ID = XX.TLOG_ID
LEFT JOIN 
	(
		SELECT
		DISTINCT ID,
		CUSTDET_ID ,
		CUST_ID_NUM
		FROM
		${stg_schema}.CRDDET 
		
		) CUST 
	ON
	T.CRDDET_ID = CUST.ID
LEFT JOIN 
	(
	 SELECT * 
	 FROM 
	(
	SELECT *  , ROW_NUMBER() OVER(PARTITION BY  TAG ,VERNO_CTX ORDER BY  VERNO_CTX DESC,tec_insrt_dttm DESC   ) RN
	FROM ${stg_schema}.STRDESCR 	
	WHERE DESCRTYPE = 'trmtyp' AND lang='EN'
	)TERM_TYP_01
	WHERE RN=1
	)TERM_TYP
	ON
	T.TERMTYPE = TERM_TYP.TAG
	 
LEFT JOIN
( SELECT * 
 FROM 
 (
SELECT * , ROW_NUMBER() OVER(PARTITION BY ID ORDER BY VERNO_CTX DESC , tec_insrt_dttm DESC ) RN 
FROM ${stg_schema}.NUMDESCR 
WHERE 
   DESCRTYPE = 'ab' AND LANG = 'EN'
) BUS_01
 WHERE  RN=1
)BUS
	ON
	T.CRDACPTBUS = BUS.ID
	
LEFT JOIN 
( 
SELECT * 
FROM 
(
SELECT * , ROW_NUMBER() OVER(PARTITION BY TAG ORDER BY VERNO_CTX DESC , tec_insrt_dttm DESC )  RN
FROM 
${stg_schema}.STRDESCR 	
 WHERE 
    DESCRTYPE = 'pschic' 	AND    lang = 'EN'
) CHIC_01 
 WHERE 
  RN =1 
  ) CHIC
	ON 
   T.POSCHIC = CHIC.TAG
		
LEFT JOIN 
	(
	SELECT  * 
 	FROM  
 	(
	SELECT *   , ROW_NUMBER() OVER(PARTITION BY TAG ORDER BY VERNO_CTX DESC  , tec_insrt_dttm DESC ) RN
	FROM 
	${stg_schema}.STRDESCR 
	WHERE 
 	DESCRTYPE = 'pschac'  AND   LANG='EN'
	) CHAC_01
 	WHERE  RN=1 
	) CHAC
	ON
	T.POSCHAC = CHAC.TAG
	 
LEFT JOIN 
(
SELECT * 
 FROM 
(
SELECT *  , ROW_NUMBER() OVER(PARTITION BY  TAG ORDER BY  VERNO_CTX DESC , tec_insrt_dttm DESC  )   RN
FROM ${stg_schema}.STRDESCR 
 WHERE  	
DESCRTYPE = 'pscrc'  AND LANG='EN'
) CRC_01   		
 WHERE RN=1 
 ) CRC
	ON
	T.POSCRC = CRC.TAG
LEFT JOIN 
(SELECT  * FROM  
(
SELECT *    , ROW_NUMBER() OVER(PARTITION BY TAG ORDER BY verno_ctx DESC  , tec_insrt_dttm DESC    )  RN
FROM ${stg_schema}.STRDESCR 
WHERE DESCRTYPE = 'psoe'
	AND lang = 'EN'
) OE_01
 WHERE RN=1 
)OE  	
ON
	T.POSOE = OE.TAG
	
LEFT JOIN
--${stg_schema}.STRDESCR 
(
SELECT  * FROM  
(
SELECT *    , ROW_NUMBER() OVER(PARTITION BY TAG ORDER BY verno_ctx DESC  , tec_insrt_dttm DESC    )  RN
FROM ${stg_schema}.STRDESCR 
WHERE
--DESCRTYPE = 'psoe'
	--AND
	lang = 'EN'
) chp_01
 WHERE RN=1 
 )CHP			
ON
	T.POSCHP = CHP.TAG
	
LEFT JOIN 
--${stg_schema}.STRDESCR 
(
SELECT  * FROM  
(
SELECT *    , ROW_NUMBER() OVER(PARTITION BY TAG ORDER BY verno_ctx DESC  , tec_insrt_dttm DESC    )  RN
FROM ${stg_schema}.STRDESCR 
WHERE 
	 DESCRTYPE = 'pscp'
	 AND
	lang = 'EN'
) cp_01
 WHERE RN=1 
 )CP 		
	ON
	T.POSCP = CP.TAG
--	AND CP.DESCRTYPE = 'pscp'
LEFT JOIN 
--${stg_schema}.STRDESCR CDIM			
(
SELECT  * FROM  
(
SELECT *    , ROW_NUMBER() OVER(PARTITION BY TAG ORDER BY verno_ctx DESC  , tec_insrt_dttm DESC    )  RN
FROM ${stg_schema}.STRDESCR 
WHERE 
	 DESCRTYPE = 'pscdim'
	 AND
	lang = 'EN'
) CDIM_01
 WHERE RN=1 
 )CDIM
	ON
	T.POSCDIM = CDIM.TAG
	--AND CDIM.DESCRTYPE = 'pscdim'
	
LEFT JOIN 
--${stg_schema}.STRDESCR CHAM		
(
SELECT  * FROM  
(
SELECT *    , ROW_NUMBER() OVER(PARTITION BY TAG ORDER BY verno_ctx DESC  , tec_insrt_dttm DESC    )  RN
FROM ${stg_schema}.STRDESCR 
WHERE 
	 DESCRTYPE = 'pscham'
	 AND
	lang = 'EN'
) CHAM_01
 WHERE RN=1 
 )CHAM
	ON
	T.POSCHAM = CHAM.TAG
	--AND CHAM.DESCRTYPE = 'pscham'
LEFT JOIN
--${stg_schema}.STRDESCR CHA		
(
SELECT  * FROM  
(
SELECT *    , ROW_NUMBER() OVER(PARTITION BY TAG ORDER BY verno_ctx DESC  , tec_insrt_dttm DESC    )  RN
FROM ${stg_schema}.STRDESCR 
WHERE 
	 DESCRTYPE = 'pscha'
	 AND
	lang = 'EN'
) CHA_01
 WHERE RN=1 
 )CHA
	ON
	T.POSCHA = CHA.TAG
--	AND CHA.DESCRTYPE = 'pscha'
LEFT JOIN 
-- ${stg_schema}.STRDESCR CHAD			
(
SELECT  * FROM  
(
SELECT *    , ROW_NUMBER() OVER(PARTITION BY TAG ORDER BY verno_ctx DESC  , tec_insrt_dttm DESC    )  RN
FROM ${stg_schema}.STRDESCR 
WHERE 
	 DESCRTYPE = 'pscdoc'
	 AND
	lang = 'EN'
) CHAD_01
 WHERE RN=1 
 )CHAD
	ON
	T.POSCHAD = CHAD.TAG
--	AND CHAD.DESCRTYPE = 'pscdoc'
LEFT JOIN 
--${stg_schema}.STRDESCR SD		
(
SELECT  * FROM  
(
SELECT *    , ROW_NUMBER() OVER(PARTITION BY TAG ORDER BY verno_ctx DESC  , tec_insrt_dttm DESC    )  RN
FROM ${stg_schema}.STRDESCR 
WHERE 
	 DESCRTYPE = 'pstoc'
	 AND
	lang = 'EN'
) SD_01
 WHERE RN=1 
 ) SD
	ON
	T.POSSD = SD.TAG
	--AND SD.DESCRTYPE = 'pstoc'
LEFT JOIN
-- ${stg_schema}.STRDESCR PCC
(
SELECT  * FROM  
(
SELECT *    , ROW_NUMBER() OVER(PARTITION BY TAG ORDER BY verno_ctx DESC  , tec_insrt_dttm DESC    )  RN
FROM ${stg_schema}.STRDESCR 
WHERE 
	 DESCRTYPE = 'pspcc'
	 AND
	lang = 'EN'
) PCC_01
 WHERE RN=1 
 )PCC			
	ON
	T.POSPCC = PCC.TAG
--	AND PCC.DESCRTYPE = 'pspcc'
--	AND PCC.LANG = 'EN'
LEFT JOIN 
(
SELECT * 
FROM 
(
SELECT *  , ROW_NUMBER() OVER( PARTITION BY ID ORDER BY VERNO_CTX  DESC , tec_insrt_dttm DESC ) RN 
FROM  ${stg_schema}.NUMDESCR 
WHERE  lang='EN'  AND  DESCRTYPE = 'pc'
) cc_01
 WHERE RN=1
)CC		
ON
	T.POSCC_89 = CC.ID
--	AND CC.DESCRTYPE = 'pc'
LEFT JOIN
(
SELECT *
 FROM 
(
SELECT *  , ROW_NUMBER() OVER(PARTITION BY ID  ORDER BY VERNO_CTX DESC , tec_insrt_dttm DESC) RN
FROM ${stg_schema}.NUMDESCR 
 WHERE LANG ='EN' AND  DESCRTYPE = 'fncode'
 )
FN_01
 WHERE RN=1 
) FN
ON
	T.FNCODE = FN.ID
--	AND FN.DESCRTYPE = 'fncode'
LEFT JOIN
(
SELECT *
 FROM 
 (
 SELECT *    , ROW_NUMBER()OVER ( PARTITION BY ID  ORDER BY VERNO_CTX DESC ,tec_insrt_dttm DESC  ) RN
 FROM 
 ${stg_schema}.NUMDESCR 	
 WHERE LANG='EN'  AND DESCRTYPE = 'tx'
 )TYP_01
 WHERE RN=1 
)TYP
ON
	T.TXNCODE = TYP.ID
	--AND TYP.DESCRTYPE = 'tx'
LEFT JOIN
(
SELECT * 
FROM  
(
 SELECT *  , ROW_NUMBER() OVER(PARTITION BY  ID  ORDER BY VERNO_CTX DESC , tec_insrt_dttm DESC  ) RN
 FROM ${stg_schema}.NUMDESCR
 WHERE   DESCRTYPE = 'tstat'
	AND LANG = 'EN'
  
 )STS_01
  WHERE RN=1
)STS
	ON
	T.TXNSTATUS = STS.ID
	-- AND STS.DESCRTYPE = 'tstat'
	-- AND STS.LANG = 'EN'
LEFT JOIN 
( 
SELECT * 
 FROM  
	 (
	SELECT *  , row_number() over(PARTITION BY id  ORDER BY verno_ctx DESC ,tec_insrt_dttm desc  ) rn
	FROM 
	${stg_schema}.NUMDESCR
	WHERE  
		DESCRTYPE = 'rj'  
		AND  LANG = 'EN'
	) rej_01
	 WHERE rn=1
) REJ			
	ON
	T.REJREASON = REJ.ID
 
LEFT JOIN 
(
SELECT * 
FROM 
(
	SELECT
		*,
		SUBSTR(RSP_CD.descrtype,
		2,
		1) AS ACTIONCODE, 
	 row_number() over(PARTITION BY id , descrtype  ORDER BY verno_ctx  DESC  ,tec_insrt_dttm desc ) rn
	FROM
		${stg_schema}.NUMDESCR RSP_CD
	WHERE
		RSP_CD.descrtype IN ('r0', 'r1' , 'r2', 'r9' )
			AND LANG = 'EN'
) RSP_CD_01
 WHERE rn=1
 
) RSP_CD
	ON
	CAST(T.RSPCODE AS integer) = CAST(RSP_CD.ID AS integer)
	AND T.ACTIONCODE = RSP_CD.ACTIONCODE
	
LEFT JOIN 
(
SELECT * FROM 
(
	  SELECT *  , row_number() over(PARTITION BY  id order by verno_ctx   desc , tec_insrt_dttm desc) rn
	  FROM  ${stg_schema}.NUMDESCR REASONCODE
	  WHERE 	   DESCRTYPE = 'reason'
	 AND  LANG = 'EN'
	 )REASONCODE_01
	 WHERE rn=1
)REASONCODE
	ON
	T.REASONCODE = REASONCODE.ID
--	AND REASONCODE.DESCRTYPE = 'reason'
	--AND REASONCODE.LANG = 'EN'
LEFT OUTER JOIN 
	(
	SELECT
		*
	FROM
		(
		SELECT
			* ,
			ROW_NUMBER() OVER(PARTITION BY currcode
		ORDER BY
			verno_ctx DESC ,
			ts_ms DESC ) rn
		FROM
			${stg_schema}.currency
	) cur
	WHERE
		rn = 1 
	)Currency
	ON 
	currency.currcode = t.CURTXN
	
LEFT OUTER JOIN 
	(
	SELECT
		*
	FROM
		(
		SELECT
			* ,
			ROW_NUMBER() OVER(PARTITION BY currcode
		ORDER BY
			verno_ctx DESC ,
			ts_ms DESC ) rn
		FROM
			${stg_schema}.currency
	) cur
	WHERE
		rn = 1 
	)STLMT_CURY
	ON
	STLMT_CURY.currcode = T.CURSET
LEFT OUTER JOIN 
	(
	SELECT
		*
	FROM
		(
		SELECT
			* ,
			ROW_NUMBER() OVER(PARTITION BY currcode
		ORDER BY
			verno_ctx DESC ,
			ts_ms DESC ) rn
		FROM
			${stg_schema}.currency
	) cur
	WHERE
		rn = 1 
	)
	CURBILL		
	ON
	 CURBILL.currcode = T.CURBILL
LEFT OUTER JOIN 
	(
	SELECT
		*
	FROM
		(
		SELECT
			* ,
			ROW_NUMBER() OVER(PARTITION BY currcode
		ORDER BY
			verno_ctx DESC ,
			ts_ms DESC ) rn
		FROM
			${stg_schema}.currency
	) cur
	WHERE
		rn = 1 
	)
	ISSUR_COM_CURY
	ON
	 ISSUR_COM_CURY.currcode = T.cur_issuer_com

