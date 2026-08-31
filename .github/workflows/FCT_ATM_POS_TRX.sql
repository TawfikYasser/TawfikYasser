

-------Primary Keys(Trx_Ref_Key,Trx_Sts)-------

Select 
TRX.k_entityid  as Trx_Key 
,CAST(
    COALESCE(
        TRX_REF.Trx_Ref_Key,
        TRX_REVRSL.Trx_Ref_Key,'-1'
    ) AS STRING
 )  AS Trx_Ref_Key --PK
,RRN
,Trx_typ
,Trx_Cls
,Trx_Cls_Descr
,Trx_Dttm 
,Trx_Sts --PK
,Cob_Dt
,Bkng_Dt
,val_Dt
,Dr_Cust_Key
,Dr_Acct_Key
,Dr_Trx_Cd
,DR_Trx_Descr		
,Cr_Acct_Key
,Cr_Trx_Cd
,Cr_Trx_Descr
,ccy_mrkt_key
,Trx_Amt
,lckd_Amt
,rev_flg
,Nrtv
,orgnl_stmt_Key
,pan
,Auth_cd
,trx_src
,Mti_cd
,proc_cd
,crd_acpt_bus_key
,crd_acct_Key
,crd_acpt_descr
,Iso_Key
,Aprvl_cd
,Bin_ref  
,Authrzr
,Chnl_Key
,Tec_Sts
,current_timestamp as tec_insrt_dttm,
current_timestamp as tec_upd_dttm,
null as dr_dttm,
null as dr_flg

from 
(
	SELECT * 
	FROM 
	(
		select 
		k_entityid
		,from_unixtime(unix_timestamp(CASE When context_cobdate in ('','null') or context_cobdate is null Then context_bankingdate ELSE context_cobdate End ,'yyyyMMdd'),'yyyy-MM-dd') as COB_DT
        ,Cast(from_unixtime(Cast(Cast(k_processingtime as BIGINT) / 1000 as int), "yyyy-MM-dd HH:mm:ss") AS TIMESTAMP) as  Trx_dttm
		,case when context_operation = 'WRITE' then 'Active' ELSE 'Deleted' end as Tec_Sts
		,substr(k_entityid,2,1) Trx_Cls
		,CASE 
		  WHEN substr(k_entityid,2,1)='1' THEN 'Authorization' 
		  WHEN substr(k_entityid,2,1)='2' THEN 'Financial' 
		  WHEN substr(k_entityid,2,1)='3' THEN 'File Update' 
		  WHEN substr(k_entityid,2,1)='4' THEN 'Reversal or Chargeback'
		  WHEN substr(k_entityid,2,1)='5' THEN 'Reconciliation' 
		  WHEN substr(k_entityid,2,1)='6' THEN 'Administrative' 
		  WHEN substr(k_entityid,2,1)='7' THEN 'Fee Collection'
		  WHEN substr(k_entityid,2,1)='8' THEN 'Network Management'  
		  ELSE substr(k_entityid,2,1)
		 END AS Trx_Cls_Descr	
        ,from_unixtime(unix_timestamp(bookingdate,'yyyyMMdd'),'yyyy-MM-dd') as Bkng_Dt
		,from_unixtime(unix_timestamp(valuedate,'yyyyMMdd'),'yyyy-MM-dd') as val_dt
        ,retrievalrefno as RRN
		,companycode    as Chnl_Key
		,COALESCE(transstatus , 'Others' ) as  Trx_Sts
		,debitacctno    as Dr_Acct_Key
		,drcustomerid   as Dr_Cust_Key
		,creditacctno   as Cr_Acct_Key
        ,currencymarket as ccy_mrkt_key
		,Cast(CASE WHEN TRIM(txnamount) IN('','null') or txnamount is null THEN '0.00' ELSE txnamount END AS DECIMAL(18,4)) as Trx_Amt
		,Cast(CASE WHEN TRIM(lockedamount) IN('','null') or lockedamount is null THEN '0.00' ELSE lockedamount END AS DECIMAL(18,4)) as lckd_Amt
		,drtxncode      as Dr_Trx_Cd
		,crtxncode      as Cr_Trx_Cd
		,CASE 
		  When narrative is null then 'NA'
		  Else regexp_replace(narrative, '\\s+', ' ')  
		 End as Nrtv
		,reversalflag as Rev_Flg
		,origstmtnos  as orgnl_stmt_Key
		,pannumber    as pan
		,authcode     as Auth_cd
		,acqoriss     as trx_src
		,atmorpos     as Trx_typ
		,mticode      as Mti_cd
		,proccode     as proc_cd
		,merchantid   as crd_acpt_bus_key
		,cardaccid    as crd_acct_Key
		,CASE 
		  When cardaccnameloc is null then 'NA'
		  Else regexp_replace(cardaccnameloc, '\\s+', ' ')  
		 End as crd_Acpt_descr  
		,isonumber   as Iso_Key
		,stanno      as Aprvl_cd
		,binreference As Bin_ref
		,`timestamp` as dttm
		,from_unixtime(unix_timestamp(substr(requesttime,1,19), 'MM/dd/yyyy-HH:mm:ss'),'yyyy-MM-dd HH:mm:ss') as Req_Dttm
		,from_unixtime(unix_timestamp(substr(responsetime,1,19), 'MM/dd/yyyy-HH:mm:ss'),'yyyy-MM-dd HH:mm:ss') as Rspns_Dttm
        ,authoriser   as Authrzr
		,ROW_NUMBER() over (partition by k_entityid,COALESCE(transstatus , 'Others' ) order by k_processingtime desc,tec_insrt_dttm desc) rnk 
		
		from stg_t24.f_atm_transaction
	    WHERE CONTEXT_OPERATION = 'WRITE'
	   

	)ATM_POS_TRX
	WHERE RNK = 1

)TRX



left join
(
	select * 
	from 
	(	
		select
		k_entityid
		,transref as Trx_Ref_Key
		,ROW_NUMBER() over (partition by k_entityid order by k_processingtime desc, tec_insrt_dttm desc) rnk
		
		from stg_t24.f_atm_transaction_transref
		where rec_index = '0'
	)Transref
	WHERE RNK = 1
)TRX_REF
ON TRX_REF.k_entityid = TRX.k_entityid
AND upper(trim(TRX.Trx_Sts)) NOT IN ('PARTIALLY-REVERSED', 'REVERSED')


left join
(
	select * 
	from 
	(	
		select
		k_entityid
		,reversaltransref as Trx_Ref_Key
		,ROW_NUMBER() over (partition by k_entityid order by k_processingtime desc, tec_insrt_dttm desc) rnk
		
		from stg_t24.f_atm_transaction_reversaltransref
		where rec_index = '0'
	)Transref
	WHERE RNK = 1
)TRX_REVRSL
ON TRX_REVRSL.k_entityid = TRX.k_entityid
AND upper(trim(TRX.Trx_Sts)) IN ('PARTIALLY-REVERSED', 'REVERSED')


left join
(

	select
	transaction_code
	,short_desc as Dr_Trx_Descr

	from dwh_base.t24_transactions
	where end_dt is null 
	
)DBT_TRX_LKP
ON DBT_TRX_LKP.transaction_code = TRX.Dr_Trx_Cd


left join
(

	select
	transaction_code
	,short_desc as Cr_Trx_Descr

	from dwh_base.t24_transactions
	where end_dt is null 
	
)CRDT_TRX_LKP
ON CRDT_TRX_LKP.transaction_code = TRX.Cr_Trx_Cd

