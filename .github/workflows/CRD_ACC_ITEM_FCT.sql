
SELECT distinct
	A.TLOGID				AS	TRX_KEY
	,A.ID					AS	ACCT_ITEM_KEY
	,A.CRDDET_ID			AS	CRD_KEY
	,ACCT.ACCNO				AS	ACCT_KEY
	,A.ACCSTAT				AS	ACCT_STS
	,A.TXNSTATUS			AS	TRX_STS_KEY
	,STS.DESCR				AS	TRX_STS
	,A.DATELOCAL 			AS 	TRX_DT
	,Cast (Substr(Cast(Cast((A.TIMELOCAL +1000000) AS INTEGER) AS VARCHAR(10)),2,2) 
	||':'||Substr(Cast(Cast((A.TIMELOCAL +1000000) AS INTEGER) AS VARCHAR(10)),4,2)
	||':'||Substr(Cast(Cast((A.TIMELOCAL +1000000) AS INTEGER) AS VARCHAR(10)),6,2)
	AS VARCHAR(8) )			AS	TRX_TM
	,A.TXNTYPE				AS	TRX_ACTV_TYP_KEY
	,ACT.DESCR				AS	TRX_ACTV_TYP
	,A.TXNCODE				AS	TRX_TYP_KEY
	,TYP.DESCR				AS	TRX_TYP
	,A.LOADTYPE				AS	LOAD_TYP_KEY
	,LOAD.DESCR				AS	LOAD_TYP
	,A.LOADSRC				AS	LOAD_SRC_KEY
	,SRC.DESCR				AS	LOAD_SRC
	,A.AMTTXN				AS	TRX_AMT
	,A.AMTBILL				AS	BILL_AMT
	,A.AMTBLK				AS	AMT_blk
	,A.CURBILL				AS	CURY_KEY
	,A.DESCRIPTION			AS	TRX_DESCR	
	,CASE WHEN REV=0 THEN 'Not a reversal transaction' 
			WHEN REV=1 THEN 'Reversal transaction' ELSE REV END REV
	,A.FEEID				AS	FEE_KEY
	,A.EXTCODE				AS	EXT_CD
	,A.REASONCODE			AS 	REASON_CD_KEY
	,REASONCODE.DESCR		AS 	REASON_CD	
	,A.TXNSUBTYPE			AS	TRX_SUB_TYP_KEY
	,CASE WHEN A.TXNSUBTYPE=0 THEN 'Authorization Matched'
		WHEN A.TXNSUBTYPE=1 THEN 'Authorization Expired'
		WHEN A.TXNSUBTYPE=2 THEN 'Authorization Canceled' ELSE A.TXNSUBTYPE END AS TRX_SUB_TYP
	,CURRENT_TIMESTAMP		AS INS_DTTM
	,A.ctxdate AS ctx_date
	,A.avlbal AS avl_bal
	,A.blkamt AS blk_amt
	,A.unclrcredit AS unclr_credit
	,TO_DATE(A.DATELOCAL)	AS TECH_TRX_DT,
cast(current_timestamp as string) as tec_insrt_dttm,
cast(current_timestamp as string) as tec_upd_dttm,
NULL as dr_dttm,		
NULL as dr_flg

FROM ${stg_schema}.ACCITEMS A

LEFT JOIN ${stg_schema}.ACCDET ACCT
	ON A.ACCDET_ID=ACCT.ID

LEFT JOIN ${stg_schema}.NUMDESCR ACT
	ON A.TXNTYPE=ACT.ID
	AND ACT.DESCRTYPE='acitty'
	
LEFT JOIN ${stg_schema}.NUMDESCR TYP		
	ON A.TXNCODE=TYP.ID
	AND TYP.DESCRTYPE='tx'
	
LEFT JOIN ${stg_schema}.NUMDESCR LOAD
	ON A.LOADTYPE=LOAD.ID
	AND LOAD.DESCRTYPE='ldtyp'
	
LEFT JOIN ${stg_schema}.NUMDESCR SRC
	ON A.LOADSRC=SRC.ID
	AND SRC.DESCRTYPE='ldsrc'
LEFT JOIN ${stg_schema}.NUMDESCR STS
	ON A.TXNSTATUS=STS.ID
	AND STS.DESCRTYPE='tstat'
LEFT JOIN ${stg_schema}.NUMDESCR REASONCODE
	ON A.REASONCODE=REASONCODE.ID
	AND REASONCODE.DESCRTYPE='aareas'
	
--where from_unixtime(unix_timestamp(concat(date_format(a.datelocal, 'yyyy-MM-dd'), ' ', substr(lpad(a.timelocal, 6, '0'), 1, 2), ':', substr(lpad(a.timelocal, 6, '0'), 3, 2), ':', substr(lpad(a.timelocal, 6, '0'), 5, 2)), 'yyyy-MM-dd HH:mm:ss')) > (CURRENT_TIMESTAMP - INTERVAL 48 HOUR)
