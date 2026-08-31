select * from (select 
FX.K_ENTITYID AS FX_KEY, --KEY
FX_SWAP.swaprefno AS SWAP_REF_KEY,
Base_CCY_key,---- added 
DEAL_DT,
DEAL_TYP,
CNTR_PRTY_KEY,
CNTR_PRTY_NM,
CNTR_RSDNC_CTRY,
Buy_Val_Dt,
BUY_CCY_KEY, 
BUY_INT_RT,
BUY_AMT,
BUY_PSTN_TYP,
SELL_Val_Dt,
SELL_CCY_KEY,
SELL_INT_RT,
SELL_AMT,
SELL_PSTN_TYP,
SPOT_DT,
SPOT_RT,
FRWD_RT,
SPOT_LCL_AMT,
BUY_LCL_EQV_AMT,
SELL_LCL_EQV_AMT,
SWFT_REF_KEY,
LMT_ref_Key,---- added 
FX.ctgy_key,   
DIM_CTGY.ctgy_descr AS CTGY_DESCR,
SEND_CONFRMTN,
SEND_PYMT,
SEND_ADVIC,
FX.CHNL_KEY,
TEC_STS,
current_timestamp as tec_insrt_dttm,
current_timestamp as tec_upd_dttm,
null as dr_dttm,
null as dr_flg


FROM 
(	

    SELECT 
	*
    FROM
    (
        SELECT 
		K_entityid
	   ,from_unixtime(unix_timestamp(case when context_cobdate in ('','null') or context_cobdate is null then context_bankingdate else context_cobdate end ,'yyyyMMdd'),'yyyy-MM-dd') as cob_dt
	   ,dealtype as deal_typ
	   ,baseccy   as base_ccy_key ----- added (mahmoud)
	   ,counterparty as cntr_prty_key
	   ,currencybought as  buy_ccy_key
	   ,cast(case when amountbought in ('','null') or amountbought is null then '0.00' else amountbought end as decimal(18,2)) as buy_amt
	   ,cast(case when buylcyequiv in ('','null')  or buylcyequiv is null then '0.00' else buylcyequiv end as decimal(18,2)) as buy_lcl_eqv_amt
	   ,from_unixtime(unix_timestamp(valuedatebuy,'yyyyMMdd'),'yyyy-MM-dd') as  buy_val_dt
	   ,positiontypebuy  as buy_pstn_typ
	   ,currencysold as sell_ccy_key
	   ,cast(case when amountsold in ('','null') or amountsold is null then '0.00' else amountsold end as decimal(18,2)) as sell_amt
	   ,cast(case when sellcyequiv in ('','null')  or sellcyequiv is null then '0.00' else sellcyequiv end as decimal(18,2)) as sell_lcl_eqv_amt
	   ,from_unixtime(unix_timestamp(valuedatesell,'yyyyMMdd'),'yyyy-MM-dd') as  sell_val_dt
	   ,positiontypesell as sell_pstn_typ
	   ,cast(case when trim(intratebuy) in('','null') or intratebuy is null then '1.00' else intratebuy end  as decimal(6,4)) as buy_int_rt
	   ,cast(case when trim(intratesell) in('','null') or intratesell is null then '1.00' else intratesell end  as decimal(6,4)) as sell_int_rt
	   ,cast(case when trim(spotrate) in('','null') or spotrate is null then '1.00' else spotrate end  as decimal(6,4)) as spot_rt
	   ,cast(case when trim(forwardrate) in('','null') or forwardrate is null then '1.00' else forwardrate end  as decimal(6,4)) as frwd_rt
	   ,cast(case when spotlcyamount in ('','null')  or spotlcyamount is null then '0.00' else spotlcyamount end as decimal(18,2)) as spot_lcl_amt   
	   ,from_unixtime(unix_timestamp(spotdate,'yyyyMMdd'),'yyyy-MM-dd') as Spot_Dt
	   ,from_unixtime(unix_timestamp(dealdate,'yyyyMMdd'),'yyyy-MM-dd') as Deal_Dt
	   ,revaluationtype
	   ,swiftcommonref   as  swft_ref_key
	   ,case when limitreferenceno = '1010.01' then '-1' else  limitreferenceno end  as  lmt_ref_key ----- added (mahmoud)
       ,categorycode     as  ctgy_key
	   ,sendconfirmation as  send_confrmtn
	   ,sendpayment      as  send_pymt
       ,sendadvice       as  send_advic
       ,cocode as chnl_key
	   ,case When context_operation = 'WRITE' THEN 'Active' else 'Deleted' end as TEC_STS
       ,ROW_NUMBER () OVER(PARTITION BY K_ENTITYID  ORDER BY k_processingtime DESC,insert_date desc) RNK
 

	    FROM  stg_t24.fodb_forex   
        WHERE from_unixtime(unix_timestamp(case when context_cobdate in ('','null') OR context_cobdate IS NULL then context_bankingdate else context_cobdate end ,'yyyyMMdd'),'yyyy-MM-dd') 
            between  '${strt_dt}'  and  '${end_dt}'     
    )FOREX
	WHERE RNK = 1

)FX


LEFT JOIN  
(	

    SELECT 
	*
    FROM
    (
        SELECT 
		k_entityid
		,swaprefno
        ,ROW_NUMBER () OVER(PARTITION BY K_ENTITYID ORDER BY k_processingtime DESC,insert_date desc) RNK
 

	    FROM stg_t24.fodb_forex_swaprefno   
        WHERE from_unixtime(unix_timestamp(case when context_cobdate in ('','null') OR context_cobdate IS NULL then context_bankingdate else context_cobdate end ,'yyyyMMdd'),'yyyy-MM-dd') 
            between  '${strt_dt}'  and  '${end_dt}'  
        AND  k_entityid != swaprefno			
    )FOREX_SWAP
	WHERE RNK = 1

)FX_SWAP
ON FX_SWAP.k_entityid = FX.K_ENTITYID


LEFT JOIN DWH_BASE.dim_ctgy_lkp DIM_CTGY
ON  DIM_CTGY.ctgy_key  = FX.CTGY_KEY
and DIM_CTGY.end_dt is null


LEFT  JOIN  
(
	 SELECT 
	*
	,COALESCE(
        DATE_ADD(
            LEAD(strt_dt) OVER (PARTITION BY K_ENTITYID ORDER BY strt_dt),-1
        ),DATE '2999-12-31'
    ) AS End_Dt
	FROM 
	(
	

        SELECT k_entityid
		,from_unixtime(unix_timestamp(case when context_cobdate in ('','null') OR context_cobdate IS NULL then context_bankingdate else context_cobdate end ,'yyyyMMdd'),'yyyy-MM-dd') AS STRT_DT
        ,shortname AS CNTR_PRTY_NM
        ,ROW_NUMBER() OVER (PARTITION BY k_entityid, case when context_cobdate in ('','null') OR context_cobdate IS NULL then context_bankingdate else context_cobdate end ORDER BY k_processingtime DESC) rnk
        
		
		FROM  stg_t24.fodb_customer_shortname
	)CUST_SHRTNAME
	WHERE RNK = 1
		
)CUST_NAME
ON  CUST_NAME.k_entityid = FX.CNTR_PRTY_KEY
and fx.cob_dt between CUST_NAME.strt_dt and CUST_NAME.end_dt


LEFT  JOIN  
(
	SELECT *
	,COALESCE(
        DATE_ADD(
            LEAD(strt_dt) OVER (PARTITION BY K_ENTITYID ORDER BY strt_dt),-1
        ),DATE '2999-12-31'
    ) AS End_Dt
	FROM 
	(
	

        SELECT k_entityid
		,from_unixtime(unix_timestamp(case when context_cobdate in ('','null') OR context_cobdate IS NULL then context_bankingdate else context_cobdate end ,'yyyyMMdd'),'yyyy-MM-dd') AS STRT_DT
        ,residence AS CNTR_RSDNC_CTRY
        ,ROW_NUMBER() OVER (PARTITION BY k_entityid, case when context_cobdate in ('','null') OR context_cobdate IS NULL then context_bankingdate else context_cobdate end ORDER BY k_processingtime DESC) rnk
        
		
		FROM  stg_t24.fodb_customer
	)FODB_CUST
	WHERE RNK = 1
		
)CUST
ON  CUST.k_entityid = FX.CNTR_PRTY_KEY
AND fx.cob_dt BETWEEN CUST.STRT_DT AND CUST.End_Dt) presrc
