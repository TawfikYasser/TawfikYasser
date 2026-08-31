Select 
stmt_key,
acct_key,
comp_cd,
trx_amt_lcy,
trx_cd,
thier_ref,
pl_categ,
cust_key,
acct_offcr,
prod_categ,
val_dt,
cury_key,
trx_amt_fcy,
exch_rt,
our_ref,
expsur_dt,
cury_mrkt,
trx_ref,
sys_id,
bking_dt,
crf_typ,
crf_trx_cd,
crf_cury,
crf_mat_dt,
crf_prod_cat,
pmt_typ,
liq_mod,
repmnt_dt,
outstnding_bal,
contract_int_rt,
contract_int_key,
int_rt,
orig_amt,
orig_cury,
oric_acct,
orig_exch_rt,
orig_amt_lcy,
drwn_acct,
amt_deal_cury,
deal_cury,
deal_exch_rt,
tax_exch_rt,
prcsing_dt,
bal_typ,
nrtv,
inptr,
auth,
booking_dt,
override,
p_day,
current_timestamp as tec_insrt_dttm,
current_timestamp as tec_upd_dttm,
null as dr_dttm,
null as dr_flg

From
(
	Select * 
	From 
	(	
		SELECT 
		 K_ENTITYID  AS STMT_KEY   
		,Case When ACCOUNTNUMBER in ('','null') then null else ACCOUNTNUMBER End AS ACCT_KEY
		,Case When COMPANYCODE in ('','null') then null else COMPANYCODE End AS COMP_CD
		,cast(case when amountlcy in ('','null') then '0.00' when amountlcy is null then '0.00' else amountlcy end as decimal(24,2)) AS TRX_AMT_LCY
		,Case When TRANSACTIONCODE in ('','null') then null else TRANSACTIONCODE End AS TRX_CD
		,Case When THEIRREFERENCE in ('','null') then null else THEIRREFERENCE End AS THIER_REF
		,Case When PLCATEGORY in ('','null') then null else PLCATEGORY End AS PL_CATEG
		,Case When CUSTOMERID in ('','null') then null else CUSTOMERID End AS CUST_KEY
		,Case When ACCOUNTOFFICER in ('','null') then null else ACCOUNTOFFICER End AS ACCT_OFFCR
		,Case When PRODUCTCATEGORY in ('','null') then null else PRODUCTCATEGORY End AS PROD_CATEG
		,CASE WHEN( COALESCE(trim(valuedate),'') ='null' or COALESCE(trim(valuedate),'') ='') or valuedate is null then null else SUBSTR(valuedate,1,4)||'-'||SUBSTR(valuedate,5,2) ||'-'||SUBSTR(valuedate,7,2) END VAL_DT
		,Case When CURRENCY in ('','null') then null else CURRENCY End AS CURY_KEY
		,cast(case when AMOUNTFCY in ('','null') then '0.00' when AMOUNTFCY is null then '0.00' else AMOUNTFCY end as decimal(24,2)) AS TRX_AMT_FCY
		,cast(case when exchangerate in ('','null') then '0.00' when exchangerate is null then '1.00' else exchangerate end  as decimal(24,2)) EXCH_RT
		,Case When OURREFERENCE in ('','null') then null else OURREFERENCE End AS OUR_REF
		,cast(regexp_replace( EXPOSUREDATE ,'(\\d{4})(\\d{2})(\\d{2})','$1-$2-$3') as date) AS EXPSUR_DT
		,Case When CURRENCYMARKET in ('','null') then null else CURRENCYMARKET End AS CURY_MRKT
		,Case When TRANSREFERENCE in ('','null') then null else TRANSREFERENCE End AS TRX_REF
		,Case When SYSTEMID in ('','null') then null else SYSTEMID End AS SYS_ID
		,CASE WHEN(COALESCE(trim(BOOKINGDATE),'') ='null' or COALESCE(trim(BOOKINGDATE),'') ='') or BOOKINGDATE is null then null else SUBSTR(BOOKINGDATE,1,4)||'-'||SUBSTR(BOOKINGDATE,5,2) ||'-'||SUBSTR(BOOKINGDATE,7,2) END BKING_DT
		,Case When CRFTYPE in ('','null') then null else CRFTYPE End AS CRF_TYP 
		,Case When CRFTXNCODE in ('','null') then null else CRFTXNCODE End AS CRF_TRX_CD
		,Case When CRFCURRENCY in ('','null') then null else CRFCURRENCY End AS CRF_CURY
		,CASE WHEN (COALESCE(trim(CRFMATDATE),'') ='null' or COALESCE(trim(CRFMATDATE),'') ='') or CRFMATDATE is null then null else SUBSTR(CRFMATDATE,1,4)||'-'||SUBSTR(CRFMATDATE,5,2) ||'-'||SUBSTR(CRFMATDATE,7,2) END CRF_MAT_DT
		,Case When CRFPRODCAT in ('','null') then null else CRFPRODCAT End AS CRF_PROD_CAT  
		,Case When PMTYPE in ('','null') then null else PMTYPE End AS PMT_TYP
		,Case When LIQUIDATIONMODE in ('','null') then null else LIQUIDATIONMODE End AS LIQ_MOD
		,CASE WHEN (COALESCE(trim(REPAYMENTDATE),'') ='null' or COALESCE(trim(REPAYMENTDATE),'') ='') or REPAYMENTDATE is null then null else SUBSTR(REPAYMENTDATE,1,4)||'-'||SUBSTR(REPAYMENTDATE,5,2) ||'-'||SUBSTR(REPAYMENTDATE,7,2) END REPMNT_DT
		,cast(case when OUTSTANDINGBAL in ('','null') then '0.00' when OUTSTANDINGBAL is null then '0.00' else OUTSTANDINGBAL end as decimal(24,2)) AS OUTSTNDING_BAL
		,cast(case when CONTRACTINTRATE in ('','null') then '0.00' when CONTRACTINTRATE is null then '1.00' else CONTRACTINTRATE end as decimal(24,2)) CONTRACT_INT_RT
		,Case When CONTRACTINTKEY in ('','null') then null else CONTRACTINTKEY End AS CONTRACT_INT_KEY
		,cast(case when INTERESTRATE in ('','null') then '0.00' when INTERESTRATE is null then '1.00' else INTERESTRATE end as decimal(24,2))  INT_RT 
		,ORIGINALAMOUNT AS ORIG_AMT
		,ORIGINALCCY AS ORIG_CURY
		,ORIGINALACCT AS ORIC_ACCT
		,ORIGINALEXCHRATE AS ORIG_EXCH_RT
		,ORIGAMOUNTLCY AS ORIG_AMT_LCY
		,DRAWNACCOUNT AS DRWN_ACCT
		,AMOUNTDEALCCY AS AMT_DEAL_CURY
		,DEALCCY AS DEAL_CURY
		,cast(case when DEALEXCHRATE in ('','null') then '0.00' when DEALEXCHRATE is null then '1.00' else DEALEXCHRATE end as decimal(24,2)) DEAL_EXCH_RT
		,cast(case when TAXEXCHRATE in ('','null') then '0.00' when TAXEXCHRATE is null then '1.00' else TAXEXCHRATE end as decimal(24,2)) TAX_EXCH_RT
		,Case When BALANCETYPE in ('','null') then null else BALANCETYPE End AS BAL_TYP
		,Case When AUTHORISER in ('','null') then null else AUTHORISER End AS AUTH
		,cast(regexp_replace( bookingdate,'(\\d{4})(\\d{2})(\\d{2})','$1-$2-$3') as date) booking_dt
		,CURRENT_DATE  AS P_DAY     
		,Row_number() over (partition by K_ENTITYID order by k_processingtime desc) rnk


		From stg_t24.FODB_STMT_ENTRY 
	
        Where from_unixtime(unix_timestamp(CASE When context_cobdate in ('','null') Then context_bankingdate When context_cobdate is null Then context_bankingdate ELSE context_cobdate End ,'yyyyMMdd'),'yyyy-MM-dd') BETWEEN '${strt_dt}' AND '${end_dt}'
	 
	)STMT
	
    WHERE RNK = 1
)STMT_ENTRY


left join 
(
	SELECT * 
	FROM 
	(   
		SELECT k_entityid
		,from_unixtime(unix_timestamp(datetime, 'yyMMddHHmm'), 'yyyy-MM-dd HH:mm:ss') as prcsing_dt
		,row_number() over (partition by K_ENTITYID order by k_processingtime desc) rnk
		
		FROM stg_t24.fodb_stmt_entry_datetime
	)DTTM
	WHERE RNK = 1

)STMT_DTTM
ON STMT_DTTM.K_ENTITYID = STMT_ENTRY.STMT_KEY


LEFT JOIN 
(

    SELECT K_ENTITYID
	,concat_ws(',', collect_list(Narrative)) AS NRTV
	FROM 
	(   
		SELECT k_entityid
	    ,Narrative  
	    ,row_number() over (partition by K_ENTITYID,rec_index order by k_processingtime desc) rnk
		
		FROM stg_t24.FODB_STMT_ENTRY_NARRATIVE 
	)NRTV
	WHERE RNK = 1
	group by K_ENTITYID

)STMT_NRTV
ON STMT_NRTV.K_ENTITYID = STMT_ENTRY.STMT_KEY

LEFT JOIN 
(

    SELECT * 
	FROM 
	(   
		SELECT k_entityid
	    ,Inputter AS INPTR
	    ,row_number() over (partition by K_ENTITYID order by k_processingtime desc) rnk
		
		FROM stg_t24.FODB_STMT_ENTRY_INPUTTER 
	)INPTR
	WHERE RNK = 1

)STMT_INPTR
ON STMT_INPTR.K_ENTITYID = STMT_ENTRY.STMT_KEY

LEFT JOIN 
(

    SELECT * 
	FROM 
	(   
		SELECT k_entityid
	    ,OVERRIDE 
	    ,row_number() over (partition by K_ENTITYID order by k_processingtime desc) rnk
		
		FROM stg_t24.FODB_STMT_ENTRY_OVERRIDE 
	)OVRD
	WHERE RNK = 1

)STMT_OVRD
ON STMT_OVRD.K_ENTITYID = STMT_ENTRY.STMT_KEY