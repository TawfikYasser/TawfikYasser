
Select
categ_key,
stmt_ref_key ,
trx_ref_key,
cust_key,
acct_key,
consl_key,
trx_cd,
trx_descr,
pl_ctgy_key,
pl_ctgy_descr, 
prod_ctgy_key,
prod_ctgy_descr, 
prcsng_dt,
prcsng_dttm,
val_dt,
exp_dt,
bkng_dt,
cob_dt,
ccy_mrkt_key,
ccy_cd,
amt_lcy,
amt_fcy,
exch_rt,
pstn_typ,
their_ref_key,
our_ref_key,
chnl_key,
acct_ofcr_key,
dept_cd,
src_sys_key,
authrzr,
inptr,
cast(current_timestamp as string) as tec_insrt_dttm, 
cast(current_timestamp as string) as tec_upd_dttm,
null as dr_dttm,
null as dr_flg

from (
Select 
categ_key,
coalesce(stmt_ref_key , '-1') as stmt_ref_key ,
trx_ref_key,
cust_key,
acct_key,
consl_key,
coalesce(trx_cd,'-1') as trx_cd,
coalesce(trx_lkp.short_desc, 'N/A') as trx_descr,
pl_ctgy_key,
pl_categ_lkp.ctgy_descr as pl_ctgy_descr, 
coalesce(prod_ctgy_key,'-1') as prod_ctgy_key,
coalesce(prod_lkp.ctgy_descr, 'N/A') as prod_ctgy_descr, 
prcsng_dt,
prcsng_dttm,
val_dt,
exp_dt,
bkng_dt,
cob_dt,
ccy_mrkt_key,
ccy_cd,
amt_lcy,
amt_fcy,
exch_rt,
categ_entry.pstn_typ,
their_ref_key,
our_ref_key,
categ_entry.chnl_key as chnl_key,
acct_ofcr_key,
dept_cd,
src_sys_key,
categ_entry.authrzr as authrzr,
categ_inptr.inptr as inptr


From
(
	Select * 
	from 
	(	
		Select 
		k_entityid as categ_key,
		case when transreference in('','null') or transreference is null then '-1'  else transreference end as  trx_ref_key,
		case when customerid in('','null') or customerid is null then '-1'  else customerid end as cust_key,
		case when accountnumber in('','null') or accountnumber is null then '-1'  else accountnumber end as acct_key,
	    consolkey   as consl_key,
        context_companycode  as chnl_key,
        systemid  as src_sys_key,
		case when accountofficer in('','null') or accountofficer is null then '-1'  else accountofficer end acct_ofcr_key,
		case when departmentcode in('','null') then null  else departmentcode end dept_cd,
		case when plcategory in('','null') then null  else plcategory end pl_ctgy_key,
		case when productcategory in('','null') then null  else productcategory end as prod_ctgy_key,
		cast(case when amountlcy in ('','null') or amountlcy is null then '0.00' else amountlcy end as decimal(24,2))as amt_lcy,
		cast(case when amountfcy in ('','null') or amountfcy is null then '0.00' else amountfcy end as decimal(24,2))as amt_fcy,	
		cast(case when exchangerate in ('','null') or exchangerate is null then '1.00' else exchangerate end as decimal(6,4))exch_rt,
		currencymarket  as   ccy_mrkt_key,
		case when currency in('','null')then null else currency end ccy_cd,
		positiontype  as pstn_typ,
		case when theirreference in('','null')  or theirreference is null then '-1' else theirreference end as their_ref_key,
		case when ourreference in('','null')    or ourreference is null then '-1'  else ourreference end as our_ref_key,
		case when authoriser in('','null')then null when authoriser is null then null else authoriser end authrzr,
		transactioncode trx_cd,
		to_date(from_unixtime(unix_timestamp(valuedate,'yyyyMMdd')))val_dt,
		to_date(from_unixtime(unix_timestamp(exposuredate,'yyyyMMdd'))) exp_dt,
		to_date(from_unixtime(unix_timestamp(bookingdate,'yyyyMMdd')))bkng_dt,
		to_date(from_unixtime(unix_timestamp(processingdate,'yyyyMMdd')))prcsng_dt,
		from_unixtime(unix_timestamp(CASE When context_cobdate in ('','null') or context_cobdate is null Then context_bankingdate ELSE context_cobdate End ,'yyyyMMdd'),'yyyy-MM-dd') as COB_DT,
		row_number() over (partition by k_entityid order by k_processingtime desc, tec_insrt_dttm desc) rnk
        
		From stg_t24.fodb_categ_entry 
	)categ_entry
	
    Where rnk = 1
)categ_entry

Left join 
(
	Select * 
	from 
	(   
		Select k_entityid
		,from_unixtime(unix_timestamp(datetime, 'yyMMddHHmm'), 'yyyy-MM-dd HH:mm:ss') as prcsng_dttm
		,row_number() over (partition by k_entityid order by k_processingtime desc) rnk
		
		From stg_t24.fodb_categ_entry_datetime
		where rec_index = '0'
	)dttm
	where rnk = 1

)Categ_dttm
on categ_dttm.k_entityid = categ_entry.categ_key

Left join 
(
    Select * 
	from 
	(   
		Select k_entityid
	    ,inputter as inptr
	    ,row_number() over (partition by k_entityid order by k_processingtime desc) rnk
		
		From stg_t24.fodb_categ_entry_inputter 
	)categ_inputter
	where rnk = 1

)Categ_inptr
on categ_inptr.k_entityid = categ_entry.categ_key
---------------------------------------------------------------
 Left join 
(
    Select * 
	from 
	(   
		Select k_entityid
	    ,case when stmtno in('','null') or stmtno is null then '-1'  else stmtno end as stmt_ref_key
	    ,row_number() over (partition by k_entityid order by k_processingtime desc, tec_insrt_dttm desc) rnk
		from stg_t24.fodb_categ_entry_stmtno
		where rec_index = '0'
	)categ_stmnt
	where rnk = 1 
)categ_stmt
on categ_stmt.k_entityid = categ_entry.categ_key
---------------------------------------------------------------
Left join   dwh_base.dim_ctgy_lkp pl_categ_lkp
on pl_categ_lkp.ctgy_key = categ_entry.pl_ctgy_key  
and pl_categ_lkp.end_dt is null 

Left join dwh_base.dim_ctgy_lkp  prod_lkp    
on prod_lkp.ctgy_key = categ_entry.prod_ctgy_key
and prod_lkp.end_dt is null


Left join dwh_base.t24_transactions  trx_lkp    
on trx_lkp.transaction_code = categ_entry.trx_cd
and trx_lkp.end_dt is null
) a 