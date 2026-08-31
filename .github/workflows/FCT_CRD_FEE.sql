
 
select
 
	FEE_KEY,
 
FEE_DTTM,
 
LNK_TYPE,
 
ACCT_KEY,
 
ACCT_NO,
 
CRD_KEY,
 
PAN,
 
PAN_DISPLAY,
 
CUST_KEY,
 
FEE_DESCR,
 
FEE_STMT_DESCR,
 
CYCL_FLG,
 
CYCL_KEY,
 
CURY_KEY,
 
CURY,
 
FEE_AMT,
 
FIXD_AMT,
 
PRCNTG,
 
PRCNTG_AMT,
 
ORGNL_FEE_AMT,
 
STS,
 
CRD_TYP,
 
REF_FEE_KEY,
 
PST_MTHD,
 
EXT_KEY,
 
EXT_BLCK_KEY,
 
FIRST_FEE_WAIVE_DT,
 
FIRST_FEE_WAIVE_AMT,
 
current_timestamp  as tec_insrt_dttm,
 
current_timestamp as tec_upd_dttm,
 
cast(null as string) as dr_dttm,
 
cast(null as string) as dr_flg

from (

SELECT

FEE.ID  AS FEE_KEY,

to_date(from_unixtime(cast(CAST(feedate AS BIGINT) / 1000 as int ))) AS FEE_DTTM,

CASE 

WHEN FEE.LINK_TYPE = 'P' THEN 'CARD'

WHEN FEE.LINK_TYPE = 'A' THEN 'ACCOUNT'

END LNK_TYPE,

coalesce(ACCT.ID, '-1')           AS ACCT_KEY,

ACCT.ACCNO                        AS ACCT_NO,

coalesce(CRD.ID  , '-1')          AS CRD_KEY,

CRD.PAN                           AS PAN,

CRD.PAN_DISPLAY                   AS PAN_DISPLAY,

coalesce(CRD.CUST_ID_NUM,'-1')    AS CUST_KEY,

F.DESCR                           AS FEE_DESCR,

F.STMTDESCR                       AS FEE_STMT_DESCR,

CASE WHEN F.CYCLIC = 0 THEN 'N' ELSE 'Y' END CYCL_FLG,

FEE.FEECYCLE_ID                   AS CYCL_KEY,

FEE.CURRCODE                      AS CURY_KEY,

CURY.ALPHACODE                    AS CURY,

FEEAMOUNT                         AS FEE_AMT,

FIXEDAMOUNT                       AS FIXD_AMT,

PERCENTAGE                        AS PRCNTG,

PERCENTAGEAMT                     AS PRCNTG_AMT,

ORGFEEAMOUNT                      AS ORGNL_FEE_AMT,

CASE 

WHEN FEE.STATUS = 0 THEN 'PENDING'

WHEN FEE.STATUS = 1 THEN 'APPLIED'

WHEN FEE.STATUS = 2 THEN 'SUSPENDED DUE TO INSUFFICIENT FUNDS'

WHEN FEE.STATUS = 3 THEN 'PENDING EXTERNAL APPLICATION'

WHEN FEE.STATUS = 4 THEN 'FEE PUT ON HOLD' 

END AS STS,

CASE 

WHEN FEE.APPLY_LINK = 'A' THEN 'PREPAID'

WHEN FEE.APPLY_LINK = 'N' THEN 'DEBIT CARD'

WHEN FEE.APPLY_LINK = 'C' THEN 'CREDIT CARD' 

END AS CRD_TYP,

APPLY_LINK_ID AS REF_FEE_KEY,

CASE 

WHEN POSTMTD = 0 THEN 'ALWAYS POST'

WHEN POSTMTD = 1 THEN 'REJECT ACTION'

WHEN POSTMTD = 2 THEN 'SUSPEND FEE AND RETRY LATER'

WHEN POSTMTD = 3 THEN 'SUSPEND FEE AND BLOCK CARD UNTIL PAYMENT DONE'

WHEN POSTMTD = 4 THEN 'HANDLE EXTERNALLY'

WHEN POSTMTD = 5 THEN 'HANDLE EXTERNALLY AND BLOCK THE CARD IN CASE OF ERROR'

WHEN POSTMTD = 6 THEN 'HANDLE EXTERNALLY AND 2 TRANSACTIONS WILL BE CREATED'

WHEN POSTMTD = 7 THEN 'HANDLE EXTERNALLY AND BLOCK THE CARD IN CASE OF ERROR AND 2 TRANSACTIONS WILL BE CREATED' 

END AS PST_MTHD,

EXTREF AS EXT_KEY,

EXTBLOCKID AS EXT_BLCK_KEY,

CAST(FIRST_FEE_WAIVE_DATE AS DATE) FIRST_FEE_WAIVE_DT,

FIRST_FEE_WAIVE_AMOUNT AS FIRST_FEE_WAIVE_AMT
 
 
FROM 

(

    SELECT * 

	FROM 

	(

	    SELECT * 

		,ROW_NUMBER() over (partition by id order by TS_MS desc) as rn  

		FROM ${stg_schema}.FEELOG 

                WHERE to_date(from_unixtime(cast(CAST(feedate AS BIGINT) / 1000 as int )))  BETWEEN '${strt_dt}' AND '${end_dt}'

	)FEELOG

	WHERE RN = 1

)FEE
 
LEFT JOIN

(
 
   select * 

   from 

   (

	   select 

	   id

	   ,ACCNO

	   ,ROW_NUMBER() over (partition by id order by TS_MS desc) as rn  

	   from ${stg_schema}.ACCDET 

    )ACCDET

	where rn = 1
 
 
)ACCT

on ACCT.ID = FEE.LINK_ID 

and  FEE.LINK_TYPE = 'A'
 
LEFT JOIN

(

   select * 

   from 

   (

	   select 

	   id

	   ,PAN

	   ,PAN_DISPLAY

	   ,CUST_ID_NUM

	   ,ROW_NUMBER() over (partition by id order by TS_MS desc) as rn  

	   from ${stg_schema}.CRDDET

    )CRDDET

	where rn = 1  

)CRD

ON CRD.ID = FEE.LINK_ID

AND FEE.LINK_TYPE = 'P'
 
LEFT JOIN 

(

	SELECT * 

	from

	(

		SELECT 

		ID

		,DESCR                         

		,STMTDESCR                      

		,CYCLIC

		,ROW_NUMBER() over (partition by id order by TS_MS desc) as rn  

	    FROM ${stg_schema}.FEEOP
 
	)FEE_DESC

	WHERE RN = 1
 
)F

ON F.ID = FEE.FEEOP_ID
 
LEFT JOIN

(

   select * 

   from 

   (

	   select 

	   CURRCODE

	   ,ALPHACODE

	   ,ROW_NUMBER() over (partition by CURRCODE order by TS_MS desc) as rn  

	   FROM ${stg_schema}.CURRENCY 

    )CURRENCY

	where rn = 1  
 
)CURY

ON CURY.CURRCODE = FEE.CURRCODE) as sr

