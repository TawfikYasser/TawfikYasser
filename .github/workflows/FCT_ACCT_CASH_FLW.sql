SELECT 
ACCT_KEY --key
,CASH_FLW_TYP --key
,CASH_FLW_DT --key
,CUST_KEY
,CASH_FLW_AMT
 ,SHA2(COALESCE(CUST_KEY,'')||COALESCE(CASH_FLW_AMT,''), 256)as hashcode
 ,cast(current_timestamp as string) as tec_insrt_dttm		
	,cast(current_timestamp as string) as tec_upd_dttm		
	,null as dr_dttm		
	,null as dr_flg
FROM  
(
    SELECT * 
	FROM 
	(
		SELECT 
		k_entityid AS ACCT_KEY
		,customerid AS CUST_KEY
	    ,interestbasis AS INT_BASIS
	    ,contractrate AS CNTRCT_RATE
		,ROW_NUMBER () over (Partition by k_entityid order by k_processingtime DESC ) AS RNK
		FROM stg_t24.fodb_eb_cashflow 
		Where from_unixtime(unix_timestamp(CASE When context_cobdate in ('','null') or context_cobdate is null Then context_bankingdate  ELSE context_cobdate End ,'yyyyMMdd'),'yyyy-MM-dd')  between  '${STRT_DT}'  and  '${END_DT}'
	)CASHFLOW
	WHERE RNK = 1
 
) BASE
 
LEFT JOIN
(
	select * 
	FROM 
	(
		SELECT
		k_entityid
		,from_unixtime(unix_timestamp(cashflowdate,'yyyyMMdd'),'yyyy-MM-dd') AS CASH_FLW_DT
		,cashflowtype AS CASH_FLW_TYP
		,CAST(CASE WHEN cashflowamt IN('','null') OR cashflowamt IS NULL THEN '0.00' ELSE cashflowamt END AS DECIMAL(18,2)) CASH_FLW_AMT
	   	,ROW_NUMBER () over (Partition by k_entityid, cashflowtype , cashflowdate order by k_processingtime DESC, tec_insrt_dttm desc ) AS RNK
		FROM stg_t24.fodb_eb_cashflow_cashflowdate
	)CASHFLOW_DT
	WHERE RNK = 1
)EB_CASHFLOW
ON EB_CASHFLOW.k_entityid = BASE.ACCT_KEY
