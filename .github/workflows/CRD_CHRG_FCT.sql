SELECT
 CHRG.TLGID			AS TRX_KEY			
 ,RECID              as     RECID      
,ACC.ACCNO			AS	ACCT_KEY
,CRD.ID				AS	CRD_KEY
,CHRG.CHARGE		AS CHRG_AMT
,CHRG.CHARGECUR		AS CURY_KEY
,CASE WHEN CHRG.CHARGESTATUS=0 THEN 'Not processed (before end of day processing is executed)'
	WHEN CHRG.CHARGESTATUS=1 THEN 'Processed (extracted)'
	WHEN CHRG.CHARGESTATUS=2 THEN 'Voided'
	WHEN CHRG.CHARGESTATUS=10 THEN 'Processed online' ELSE CAST (CHRG.CHARGESTATUS AS STRING)
	END AS CHRG_STS
,CASE WHEN CHRG.CREDIT=0 THEN 'Debit' WHEN CHRG.CREDIT=1 THEN 'Credit' 
	ELSE CHRG.CREDIT END 	AS TRX_TYP
,CHRG.DESCR					AS CHRG_DESCR
,CHRG.CHARGETYPE			AS CHRG_TYP
,CHRG.CHARGETAG				AS CHRG_TAG
,CASE WHEN CHRG.CHGTXNTYPE=0 THEN 'Unknown' WHEN CHRG.CHGTXNTYPE=1 THEN 'Financial'
	WHEN CHRG.CHGTXNTYPE=2 THEN 'Authorization' WHEN CHRG.CHGTXNTYPE=3 THEN 'Zero-valued Auth (e.g. balance inquiry)'
	WHEN CHRG.CHGTXNTYPE=4 THEN 'Event Fee (no transaction)' WHEN CHRG.CHGTXNTYPE=5 THEN 'Period Fee (no transaction)'
	ELSE CAST(CHRG.CHGTXNTYPE AS STRING) END AS CHRG_TRX_TYP
,CHRG.ORGCHARGE		AS ORG_CHRG
,CURRENT_DATE		AS INS_DTTM
,CHRG.APPLY_DATE	AS CHRG_DT
,CHRG.tec_insrt_dttm, 
CHRG.tec_upd_dttm, 
CHRG.dr_dttm, 
CHRG.dr_flg

from (select * from (select *, row_number() over(partition by recid order by verno_ctx desc, ctxdate desc, tec_insrt_dttm desc)r 
from ${stg_schema}.chargelog)a
where a.r =1)CHRG
LEFT JOIN (select * from (select *, row_number() over(partition by id order by verno_ctx desc, lastloaddate desc, tec_insrt_dttm desc)r 
from ${stg_schema}.ACCDET)a
where a.r =1) ACC
ON CHRG.ACCDET_ID=ACC.ID
LEFT JOIN (select * from (select *, row_number() over(partition by id order by verno_ctx desc, date_created desc, tec_insrt_dttm desc)r 
from ${stg_schema}.CRDDET)a
where a.r =1) CRD
ON CHRG.CRDDET_ID=CRD.ID
