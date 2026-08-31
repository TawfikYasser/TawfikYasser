SELECT COUNT(*) FROM (
    SELECT hash_prep.*,
        CASE WHEN HASH_PREP.HASH_KEY = FIRST_VALUE(HASH_PREP.HASH_KEY) OVER(
            PARTITION BY HASH_PREP.Arr_key ORDER BY HASH_PREP.strt_dt ASC
            ROWS BETWEEN 1 PRECEDING AND 1 PRECEDING)
        THEN 1 ELSE 0 END AS FK_UP
    FROM (
        SELECT BUS_QRY.*,
            sha2(
coalesce(sts, '') ||
coalesce(cust_key, '') ||
coalesce(cust_typ, '') ||
coalesce(acct_key, '') ||
coalesce(iban, '') ||
coalesce(ctgy_key, '') ||
coalesce(opn_ctgy_key, '') ||
coalesce(prnt_acct_key, '') ||
coalesce(chnl_key, '') ||
coalesce(CCY_KEY, '') ||
coalesce(prod_grp, '') ||
coalesce(prod_ln, '') ||
coalesce(Prod_typ, '') ||
coalesce(PROD_TITL, '') ||
coalesce(Actv_prod, '') ||
coalesce(int_rt, '') ||
coalesce(mrgn_rt, '') ||
coalesce(TOT_COMTMNT_AMT, '') ||
coalesce(TOT_PRNCPL_AMT, '') ||
coalesce(MONTH_TIME, '') ||
coalesce(DAY_TIME, '') ||
coalesce(TENR_TIME, '') ||
coalesce(FUNDNG_PAYIN_ACCT_KEY, '') ||
coalesce(REDMPTN_PAYOUT_ACCT_KEY, '') ||
coalesce(INT_STLMNT_ACCT_KEY, '') ||
coalesce(PYMNT_TYP, '') ||
coalesce(CAPTLIZ_FLG, '') ||
coalesce(TEC_STS, '')
            , 256) AS HASH_KEY
        FROM (
            with base as(
             
            SELECT  
            k_entityid
            ,cast(regexp_replace(DT, '(\\d{4})(\\d{2})(\\d{2})', '$1-$2-$3') AS DATE) COB_DT
             
            FROM 
            (
            	select  
            	k_entityid
            	,CASE 
            		   when context_cobdate = 'null' THEN context_bankingdate
            		   when context_cobdate = '' THEN context_bankingdate
            		   when context_cobdate is null THEN context_bankingdate
            		   ELSE context_cobdate END AS DT
             
            	FROM stg_t24.FODB_AA_ARRANGEMENT  				
            	where PRODUCTLINE IN ('DEPOSITS', 'ACCOUNTS')
            	and context_operation = 'WRITE'
            	group BY 
            	k_entityid
            	,CASE 
            	   when context_cobdate = 'null' THEN context_bankingdate
            	   when context_cobdate = '' THEN context_bankingdate
            	   when context_cobdate is null THEN context_bankingdate
            	   ELSE context_cobdate 
            	 END 
            	
            	UNION
             
            	select 
            	k_entityid
            	,CASE 
            		when context_cobdate = 'null' THEN context_bankingdate
            		when context_cobdate = '' THEN context_bankingdate
            		when context_cobdate is null THEN context_bankingdate
            		ELSE context_cobdate END AS DT
            	
            	FROM stg_t24.fodb_aa_account_details 
            	where  context_operation = 'WRITE'
             
            	qualify RANK() OVER (PARTITION BY k_entityid,RENEWALDATE ORDER BY k_processingtime DESC,INSERT_DATE DESC) = 1
             
            )PROD
             
            ),
             
            cal 
            AS 
            (
                select 
                cal.calendar_dt,
                k_entityid
                from 
            	(
                    SELECT 
            		k_entityid, 
            		MIN(COB_DT) AS MIN_COB_DT
                    
            		FROM base
                    GROUP BY k_entityid
                )cnn 
            	
            	inner join dwh_base.calendar_base cal
                ON cal.calendar_dt BETWEEN MIN_COB_DT AND CAST('${end_dt}' AS DATE)
            )
            
            
            SELECT DISTINCT
            
             PROD.k_entityid     				   as Arr_key
            ,cal.calendar_dt     				   as strt_dt
            ,PROD.STS            				   as sts
            ,coalesce(CUST.cust_key  , '-1' )      as cust_key
            ,CUST.cust_typ        				   as cust_typ
            ,coalesce(LNKD_ACCT.acct_key , '-1')   as acct_key
            ,LNKD_ACCT.iban       				   as iban
            ,ACCT.ctgy_key        				   as ctgy_key
            ,ACCT.opn_ctgy_key    				   as opn_ctgy_key
            ,coalesce(ACCT.prnt_acct_key,'-1')     as prnt_acct_key
            ,ACCT.chnl_key        				   as chnl_key
            ,PROD.CCY_KEY         				   as CCY_KEY
            ,PROD.prod_grp        				   as prod_grp
            ,PROD.prod_ln         				   as prod_ln
            ,CASE
              when prod_ln = 'DEPOSITS' AND prod_grp = 'MDI.CERTIFICATES.OF.DEPOSITS' THEN 'CD'
              when prod_ln = 'DEPOSITS' AND prod_grp = 'MDI.TERM.DEPOSITS' THEN 'TD'
              when prod_ln = 'DEPOSITS' AND prod_grp = 'MDI.FLEXIBLE.SAV' THEN 'FLEX_SAV'
              when prod_ln = 'DEPOSITS' AND prod_grp = 'MDI.FIXED.SAV' THEN 'FIXED_SAV'
              when prod_ln = 'ACCOUNTS' AND prod_grp = 'MDI.CURRENT.ACCOUNTS' THEN 'CURRENT'
              when prod_ln = 'ACCOUNTS' AND prod_grp = 'MDI.OVERDRAFT.ACCOUNTS' THEN 'OD'
              when prod_ln = 'ACCOUNTS' AND prod_grp IN ('MDI.SAVING.DAILY' ,'MDI.SAVINGS.ACCOUNTS') THEN 'SAVING'
              ELSE 'OTHER'
            END AS Prod_typ
            ,ACCT_TITL.Prod_titl  as PROD_TITL
            ,PROD.Actv_prod       as Actv_prod
            ,COALESCE (ACCT_DTLS.val_dt,PROD.prod_strt_dt) as prod_strt_dt
            ,ACCT_DTLS.val_dt     as val_dt
            ,ACCT_DTLS.Renwl_dt   as Renwl_dt
            ,ACCT_DTLS.mat_dt     as mat_dt
            ,cast(FX.int_rt AS float) AS int_rt
            ,CASE
              when prod_ln = 'DEPOSITS' THEN cast(FX.mrgn_rt AS float)
            END AS mrgn_rt
            ,cast(COALESCE (BAL.Commitment_Amount,0) AS FLOAT) TOT_COMTMNT_AMT
            ,ABS(CASE
                when prod_ln = 'DEPOSITS' AND COALESCE(AA_CNTR.workingbalance,0) = 0
                    THEN BAL.PRINCIPAL_CURRENT
                when prod_ln = 'DEPOSITS'
                    THEN cast(COALESCE (AA_CNTR.workingbalance,BAL.PRINCIPAL_CURRENT) AS FLOAT)
                ELSE 0
            END) TOT_PRNCPL_AMT
            
            ,COALESCE(CASE
                       when SUBSTRING(COALESCE(Tenor, term), 2, 1) = 'M' THEN cast(SUBSTRING(COALESCE(Tenor, term), 1, 1) AS int)
                       when SUBSTRING(COALESCE(Tenor, term), 2, 1) = 'Y' THEN cast(SUBSTRING(COALESCE(Tenor, term), 1, 1) AS int)*12
                       when SUBSTRING(COALESCE(Tenor, term), 2, 1) = 'W' THEN cast(SUBSTRING(COALESCE(Tenor, term), 1, 1) AS int)/4
                       when SUBSTRING(COALESCE(Tenor, term), 2, 1) = 'D' THEN cast(SUBSTRING(COALESCE(Tenor, term), 1, 1) AS int)/30
                       when SUBSTRING(COALESCE(Tenor, term), 3, 1) = 'M' THEN cast(SUBSTRING(COALESCE(Tenor, term), 1, 2) AS int)
                       when SUBSTRING(COALESCE(Tenor, term), 3, 1) = 'Y' THEN cast(SUBSTRING(COALESCE(Tenor, term), 1, 2) AS int)*12
                       when SUBSTRING(COALESCE(Tenor, term), 3, 1) = 'W' THEN cast(SUBSTRING(COALESCE(Tenor, term), 1, 2) AS int)/4
                       when SUBSTRING(COALESCE(Tenor, term), 3, 1) = 'D' THEN round((cast(SUBSTRING(COALESCE(Tenor, term), 1, 2) AS int)/30),0)
                       when SUBSTRING(COALESCE(Tenor, term), 4, 1) = 'D' THEN round((cast(SUBSTRING(COALESCE(Tenor, term), 1, 3) AS int)/30),0)
                       when SUBSTRING(COALESCE(Tenor, term), 5, 1) = 'D' THEN round((cast(SUBSTRING(COALESCE(Tenor, term), 1, 4) AS int)/30),0)
            END ,0) AS MONTH_TIME
            
            ,COALESCE(CASE
                        when SUBSTRING(COALESCE(Tenor, term), 2, 1) = 'D' THEN cast(SUBSTRING(COALESCE(Tenor, term), 1, 1) AS int)
                        when SUBSTRING(COALESCE(Tenor, term), 2, 1) = 'M' THEN cast(SUBSTRING(COALESCE(Tenor, term), 1, 1) AS int)*30
                        when SUBSTRING(COALESCE(Tenor, term), 2, 1) = 'Y' THEN cast(SUBSTRING(COALESCE(Tenor, term), 1, 1) AS int)*365
                        when SUBSTRING(COALESCE(Tenor, term), 2, 1) = 'W' THEN cast(SUBSTRING(COALESCE(Tenor, term), 1, 1) AS int)*7
                        when SUBSTRING(COALESCE(Tenor, term), 3, 1) = 'D' THEN cast(SUBSTRING(COALESCE(Tenor, term), 1, 2) AS int)
                        when SUBSTRING(COALESCE(Tenor, term), 3, 1) = 'M' THEN cast(SUBSTRING(COALESCE(Tenor, term), 1, 2) AS int)*30
                        when SUBSTRING(COALESCE(Tenor, term), 3, 1) = 'Y' THEN cast(SUBSTRING(COALESCE(Tenor, term), 1, 2) AS int)*365
                        when SUBSTRING(COALESCE(Tenor, term), 3, 1) = 'W' THEN cast(SUBSTRING(COALESCE(Tenor, term), 1, 2) AS int)*7
                        when SUBSTRING(COALESCE(Tenor, term), 4, 1) = 'D' THEN cast(SUBSTRING(COALESCE(Tenor, term), 1, 3) AS int)
                        when SUBSTRING(COALESCE(Tenor, term), 4, 1) = 'M' THEN cast(SUBSTRING(COALESCE(Tenor, term), 1, 3) AS int)*30
                        when SUBSTRING(COALESCE(Tenor, term), 4, 1) = 'W' THEN cast(SUBSTRING(COALESCE(Tenor, term), 1, 3) AS int)*7
                        when SUBSTRING(COALESCE(Tenor, term), 5, 1) = 'D' THEN cast(SUBSTRING(COALESCE(Tenor, term), 1, 4) AS int)
                        when SUBSTRING(COALESCE(Tenor, term), 5, 1) = 'M' THEN cast(SUBSTRING(COALESCE(Tenor, term), 1, 4) AS int)*30
                        when SUBSTRING(COALESCE(Tenor, term), 5, 1) = 'W' THEN cast(SUBSTRING(COALESCE(Tenor, term), 1, 4) AS int)*7
            END,0) AS DAY_TIME
            
            ,CASE when prod_ln = 'DEPOSITS' THEN COALESCE(Tenor, term) END AS TENR_TIME
            
            ,coalesce(ACCT_LNKD.FUNDNG_PAYIN_ACCT_KEY , '-1')   as FUNDNG_PAYIN_ACCT_KEY
            ,coalesce(ACCT_LNKD.REDMPTN_PAYOUT_ACCT_KEY, '-1')  as REDMPTN_PAYOUT_ACCT_KEY
            ,coalesce(ACCT_LNKD.INT_STLMNT_ACCT_KEY , '-1'   )  as INT_STLMNT_ACCT_KEY
            ,AA_PYMNT.PAYMENTMETHOD AS PYMNT_TYP
            ,CASE
              when upper(AA_PYMNT.PAYMENTMETHOD) LIKE 'CAPITALISE' THEN 'Y'
              ELSE 'N'
            END AS CAPTLIZ_FLG
            ,CASE
              when ACT_DLT.context_operation is not null THEN 'Deleted'
              when ACCT_DLT.context_operation is not null THEN 'Deleted'
              ELSE 'Active'
            END as TEC_STS
             
            FROM cal as cal
             
            INNER join
            (
            	SELECT DISTINCT 
            	Arr.k_entityid,
            	ARR.arrstatus AS STS,
            	Arr.currency  AS CCY_KEY,
            	cast(regexp_replace(Arr.startdate, '(\\d{4})(\\d{2})(\\d{2})', '$1-$2-$3') AS DATE) as prod_strt_dt,
                trim(arr.productgroup)  as prod_grp ,
                trim(arr.productline )  as prod_ln, 
            	trim(arr.Activeproduct) as Actv_prod ,	
            	cast(regexp_replace(ARR.DT, '(\\d{4})(\\d{2})(\\d{2})', '$1-$2-$3') AS DATE) AS STRT_DT,
            	COALESCE(date_sub(LEAD(cast(regexp_replace(ARR.DT, '(\\d{4})(\\d{2})(\\d{2})', '$1-$2-$3') AS DATE)) OVER (PARTITION by ARR.k_entityid 
            	ORDER BY cast(regexp_replace(ARR.DT, '(\\d{4})(\\d{2})(\\d{2})', '$1-$2-$3') AS DATE) ASC), 1),
            	cast(regexp_replace('2999-12-31', '(\\d{4})(\\d{2})(\\d{2})', '$1-$2-$3') AS DATE)) AS END_DT	
             
            	FROM 
            	(
            		SELECT   
            		K_ENTITYID
            		FROM BASE
            		GROUP BY K_ENTITYID
            	)Cal_Base 
               
                INNER JOIN 
            	(
            		SELECT
            		k_entityid,
            		CASE
            		  when context_cobdate = 'null' THEN context_bankingdate
            		  when context_cobdate = '' THEN context_bankingdate
            		  when context_cobdate is null THEN context_bankingdate
            		  ELSE context_cobdate 
            		END AS DT,
            		currency,
            		startdate,
            		productline,
            		productgroup,
            		activeproduct,
            		arrstatus,	
            		RANK() OVER (PARTITION BY k_entityid, CASE when context_cobdate = 'null' or context_cobdate = '' THEN context_bankingdate when context_cobdate is null THEN context_bankingdate  ELSE context_cobdate 
            		                                      END ORDER BY k_processingtime DESC) AS RNK
            		
            		FROM stg_t24.Fodb_aa_arrangement					
            		where Productline IN ('DEPOSITS', 'ACCOUNTS')
            		and context_operation = 'WRITE'
            	)ARR 
            	ON ARR.k_entityid = Cal_Base.k_entityid 
                WHERE ARR.RNK = 1            	
            )PROD 
            on PROD.k_entityid = cal.k_entityid
            and cal.calendar_Dt BETWEEN  PROD.strt_dt and PROD.end_Dt
             
            INNER JOIN
            (
            	SELECT distinct
            	AA_ACCT.k_entityid
            	,acct_key
            	,Iban
            	,dt
            	FROM
            	(
            		SELECT   
            		K_ENTITYID
            		FROM BASE
            		GROUP BY K_ENTITYID
            	)Cal_Base 
            	
            	INNER JOIN
            	(
            		SELECT DISTINCT
            		k_entityid,
            		LINKEDAPPLID AS acct_key,
            		CASE 
            		 when context_cobdate = 'null' THEN context_bankingdate
            		 when context_cobdate = '' THEN context_bankingdate
            		 when context_cobdate is null THEN context_bankingdate
            		 ELSE context_cobdate
            		END AS DT,
            		RANK() OVER (PARTITION BY K_ENTITYID ORDER BY k_processingtime DESC) AS RNK
            		
            		FROM stg_t24.fodb_aa_arrangement_linkedappl
            		where context_operation = 'WRITE'
            	
            	)AA_ACCT 
            	ON AA_ACCT.k_entityid = Cal_Base.k_entityid
            	
            	LEFT JOIN 
            	(
            		SELECT DISTINCT 
            		K_ENTITYID, 
            		CASE when altacctid = 'null' OR altacctid = '' THEN NULL ELSE altacctid END AS IBAN
            		
            		from stg_t24.fodb_account_altaccttype 
            		where altaccttype = 'T24.IBAN'
            		and context_operation = 'WRITE'
            	)Acct_Iban 
            	ON Acct_Iban.K_ENTITYID = AA_ACCT.acct_key
             
            			
            	WHERE AA_ACCT.RNK = 1
            )LNKD_ACCT
            ON LNKD_ACCT.k_entityid = cal.k_entityid
            
            
            INNER JOIN
            (
            	SELECT distinct
            	AA_CUST.k_entityid
            	,cust_key
            	,cust_typ
            	,DT
                FROM 
            	(
            		SELECT   
            		K_ENTITYID
            		FROM BASE
            		GROUP BY K_ENTITYID
            	)Cal_Base 
            
            	INNER JOIN
            	(
            		SELECT
            		K_ENTITYID,
            		Customer as cust_key,		
            		CASE
            			when customerrole = 'OWNER' THEN 'Single'
            			when customerrole = 'JOINT.OR.FIRST' THEN 'Primary Joint'
            			when customerrole = 'JOINT.OR.OTHER' THEN 'Joint'
            			ELSE customerrole		
            		END AS cust_typ,
            		CASE 
            			when context_cobdate = 'null' THEN context_bankingdate
            			when context_cobdate = '' THEN context_bankingdate
            			when context_cobdate is null THEN context_bankingdate
            			ELSE context_cobdate 
            		END AS DT,
            		RANK() OVER (PARTITION BY K_ENTITYID ORDER BY k_processingtime DESC) RNK
            		FROM stg_t24.fodb_aa_arrangement_customer
            		where context_operation = 'WRITE'
            	        and rec_index = '0'
            	)AA_CUST 
            	ON AA_CUST.k_entityid = Cal_Base.k_entityid
            	WHERE AA_CUST.RNK=1
            )CUST
            ON CUST.k_entityid = cal.k_entityid
            
            LEFT JOIN
            (
            	select 
            	K_ENTITYID 
            	,val_dt
            	,Renwl_dt
            	,mat_dt
            	,case when rnk=1 then val_dt else strt_Dt END as strt_dtt
            	,end_dt
             
            	from
            	(
            	SELECT DISTINCT  
            	ACCT_DETAILS.K_ENTITYID
            	,CASE
            	  when((COALESCE(trim(valuedate), '') = 'null') OR (COALESCE(trim(valuedate), '') = '') OR (valuedate IS NULL)) THEN NULL
            	  ELSE cast(regexp_replace(valuedate, '(\\d{4})(\\d{2})(\\d{2})', '$1-$2-$3') AS DATE)
            	 END AS val_dt
            	,CASE
            	  when((COALESCE(trim(renewaldate), '') = 'null') OR (COALESCE(trim(renewaldate), '') = '') OR (renewaldate IS NULL)) THEN NULL
            	  ELSE cast(regexp_replace(renewaldate, '(\\d{4})(\\d{2})(\\d{2})', '$1-$2-$3') AS DATE)
            	 END AS Renwl_dt 
            	,coalesce(CASE 
            	           when ((COALESCE(trim(MATURITYDATE), '') = 'null') OR (COALESCE(trim(MATURITYDATE), '') = '') OR (MATURITYDATE IS NULL) ) THEN NULL
            			   ELSE cast(regexp_replace(MATURITYDATE, '(\\d{4})(\\d{2})(\\d{2})', '$1-$2-$3') AS DATE) 
            			   END
                          ,CASE 
            			    when ((COALESCE(trim(renewaldate), '') = 'null') OR (COALESCE(trim(renewaldate), '') = '') OR  (RENEWALDATE IS NULL)) THEN NULL
            				ELSE cast(regexp_replace(renewaldate, '(\\d{4})(\\d{2})(\\d{2})', '$1-$2-$3') AS DATE) 
            			   END ) AS mat_dt
            	,cast(regexp_replace(DT, '(\\d{4})(\\d{2})(\\d{2})', '$1-$2-$3') AS DATE) strt_dt
            	,COALESCE(date_sub(LEAD(cast(regexp_replace(DT, '(\\d{4})(\\d{2})(\\d{2})', '$1-$2-$3') AS DATE)) OVER (PARTITION by ACCT_DETAILS.K_ENTITYID ORDER BY cast(regexp_replace(DT, '(\\d{4})(\\d{2})(\\d{2})', '$1-$2-$3') AS DATE)), 1)
                                             ,cast(regexp_replace('2999-12-31', '(\\d{4})(\\d{2})(\\d{2})', '$1-$2-$3') AS DATE)) AS END_DT
            	,ROW_NUMBER () OVER(PARTITION BY ACCT_DETAILS.K_ENTITYID order by k_processingtime) rnk
            	FROM
            	(
            		SELECT   
            		K_ENTITYID
            		FROM base
            		GROUP BY K_ENTITYID
            	)Cal_Base  
            	
            	INNER JOIN
            	(
            		SELECT DISTINCT
            		K_ENTITYID,
            		MATURITYDATE,
            		RENEWALDATE,
            		VALUEDATE,
            		CASE 
            		 when context_cobdate = 'null' THEN context_bankingdate
            		 when context_cobdate = '' THEN context_bankingdate
            		 when context_cobdate is null THEN context_bankingdate
            		 ELSE context_cobdate
            		END AS DT,
            		cast(from_unixtime(cast(CAST(k_processingtime as BIGINT) / 1000 as int), "yyyy-MM-dd") AS DATE) k_processingtime,
            		ROW_NUMBER () OVER (PARTITION BY k_entityid,CASE 
            													  when context_cobdate = 'null' OR  context_cobdate = '' THEN context_bankingdate 
            											          when context_cobdate is null THEN context_bankingdate
            													  ELSE context_cobdate
            													END  ORDER BY k_processingtime desc,INSERT_DATE desc)AS RNK 
            		FROM stg_t24.fodb_aa_account_details
            		where context_operation = 'WRITE'
             
            	)ACCT_DETAILS 
            	ON ACCT_DETAILS.K_ENTITYID = Cal_Base.K_ENTITYID
                
                WHERE ACCT_DETAILS.RNK = 1
              )actt
            )ACCT_DTLS
            ON ACCT_DTLS.K_ENTITYID = cal.k_entityid
            and cal.calendar_Dt between ACCT_DTLS.strt_dtt AND ACCT_DTLS.end_dt
            
             
            LEFT JOIN
            (
            	SELECT DISTINCT
            	cntr.K_ENTITYID as ACCOUNT_NUM
            	,workingbalance
            	,DT  AS STRT_DT
            	,COALESCE(date_sub(LEAD(dt) OVER (PARTITION by cntr.K_ENTITYID ORDER BY cntr.k_processingtime ASC), 1)
            	         ,cast(regexp_replace('2999-12-31', '(\\d{4})(\\d{2})(\\d{2})', '$1-$2-$3') AS DATE)) AS END_DT	
            	FROM 
            	(
             
            		SELECT *
            		,CASE when context_cobdate = 'null' THEN cast(regexp_replace(context_bankingdate, '(\\d{4})(\\d{2})(\\d{2})', '$1-$2-$3') AS DATE) 
            			  when context_cobdate = '' THEN cast(regexp_replace(context_bankingdate, '(\\d{4})(\\d{2})(\\d{2})', '$1-$2-$3') AS DATE) 
            			  when context_cobdate is null THEN cast(regexp_replace(context_bankingdate, '(\\d{4})(\\d{2})(\\d{2})', '$1-$2-$3') AS DATE)
            		ELSE cast(regexp_replace(context_cobdate, '(\\d{4})(\\d{2})(\\d{2})', '$1-$2-$3') AS DATE) END AS dt
            		FROM stg_t24.fodb_eb_contract_balances  
                    
            		where context_operation = 'WRITE'
            		
            		QUALIFY ROW_NUMBER() over(partition by K_ENTITYID, CASE when context_cobdate = 'null' THEN cast(regexp_replace(context_bankingdate, '(\\d{4})(\\d{2})(\\d{2})', '$1-$2-$3') AS DATE) 
            		when context_cobdate = '' THEN cast(regexp_replace(context_bankingdate, '(\\d{4})(\\d{2})(\\d{2})', '$1-$2-$3') AS DATE) 
            		when context_cobdate is null THEN cast(regexp_replace(context_bankingdate, '(\\d{4})(\\d{2})(\\d{2})', '$1-$2-$3') AS DATE) 
            		ELSE cast(regexp_replace(context_cobdate, '(\\d{4})(\\d{2})(\\d{2})', '$1-$2-$3') AS DATE) END  
            		                          order by k_processingtime DESC) = 1  
             
            	)cntr
              where openassettype in ('CURACCOUNT','DUENEWARRFEES') and `application` =  'ACCOUNT'
            )AA_CNTR
            on cal.calendar_Dt between AA_CNTR.strt_dt AND AA_CNTR.end_dt
            AND LNKD_ACCT.acct_key = AA_CNTR.ACCOUNT_NUM
             
            LEFT JOIN 
            (
            	SELECT 
                RATES.K_ENTITYID
               ,int_rt  as int_rt
               ,mrgn_rt as mrgn_rt              
               ,STRT_DT
               ,END_DT
               FROM 
               (
            		SELECT   
            		K_ENTITYID
            		FROM BASE
            		GROUP BY K_ENTITYID
                )Cal_Base     
                inner join 
                (
            		SELECT DISTINCT
            		BB.K_ENTITYID                
            		,CASE when BB.idcomp_d_2 = 'DEPOSITINT' THEN EFFECTIVERATE END int_rt
            		,CASE when BB.idcomp_d_2 = 'DEPOSITINT' THEN MARGINRATE END mrgn_rt	
            		,cast(regexp_replace(BB.DT, '(\\d{4})(\\d{2})(\\d{2})', '$1-$2-$3') AS DATE) AS STRT_DT
            		,COALESCE(date_sub(LEAD(cast(regexp_replace(BB.DT, '(\\d{4})(\\d{2})(\\d{2})', '$1-$2-$3') AS DATE)) OVER (PARTITION by bb.k_entityid 
            		ORDER BY cast(regexp_replace(bb.DT, '(\\d{4})(\\d{2})(\\d{2})', '$1-$2-$3') AS DATE) ASC), 1),
            		cast(regexp_replace('2999-12-31', '(\\d{4})(\\d{2})(\\d{2})', '$1-$2-$3') AS DATE)) AS END_DT	
            		
                   	FROM 
                    (
            			   SELECT DISTINCT
            			   K_ENTITYID
            			   ,idcomp_d_2
            			   ,DT
            			    FROM 
            			    (
            					  SELECT DISTINCT
            					  IDCOMP_D_1 AS K_ENTITYID
            					  ,IDCOMP_D_2
            					  ,CASE when context_cobdate = 'null' THEN cast(regexp_replace(context_bankingdate, '(\\d{4})(\\d{2})(\\d{2})', '$1-$2-$3') AS DATE) 
            			      			when context_cobdate = '' THEN cast(regexp_replace(context_bankingdate, '(\\d{4})(\\d{2})(\\d{2})', '$1-$2-$3') AS DATE) 
            			  				when context_cobdate is null THEN cast(regexp_replace(context_bankingdate, '(\\d{4})(\\d{2})(\\d{2})', '$1-$2-$3') AS DATE)
            							ELSE cast(regexp_replace(context_cobdate, '(\\d{4})(\\d{2})(\\d{2})', '$1-$2-$3') AS DATE) END AS dt
            	
            					  ,ROW_NUMBER() OVER (PARTITION BY IDCOMP_D_1, K_PROCESSINGTIME  ORDER BY K_PROCESSINGTIME DESC) AS RNK
            					  FROM  stg_t24.fodb_aa_arr_interest
            					  where context_operation = 'WRITE'
            			    )PROD
            			    WHERE PROD.RNK = 1
                    )BB
                    INNER JOIN 
                    (
                    select * from 
                    (
            			   SELECT DISTINCT 
            			   SUBSTRING(K_ENTITYID ,0,12) AS K_ENTITYID
            			   ,REC_INDEX
            			   ,CASE when context_cobdate = 'null' THEN cast(regexp_replace(context_bankingdate, '(\\d{4})(\\d{2})(\\d{2})', '$1-$2-$3') AS DATE) 
            			      			when context_cobdate = '' THEN cast(regexp_replace(context_bankingdate, '(\\d{4})(\\d{2})(\\d{2})', '$1-$2-$3') AS DATE) 
            			  				when context_cobdate is null THEN cast(regexp_replace(context_bankingdate, '(\\d{4})(\\d{2})(\\d{2})', '$1-$2-$3') AS DATE)
            							ELSE cast(regexp_replace(context_cobdate, '(\\d{4})(\\d{2})(\\d{2})', '$1-$2-$3') AS DATE) END AS dt
            			   ,EFFECTIVERATE
            			   ,TIERAMOUNT
            			   ,ROW_NUMBER() OVER (PARTITION BY SUBSTRING(K_ENTITYID ,0,12),
            CASE when context_cobdate = 'null' THEN cast(regexp_replace(context_bankingdate, '(\\d{4})(\\d{2})(\\d{2})', '$1-$2-$3') AS DATE) 
            			      			when context_cobdate = '' THEN cast(regexp_replace(context_bankingdate, '(\\d{4})(\\d{2})(\\d{2})', '$1-$2-$3') AS DATE) 
            			  				when context_cobdate is null THEN cast(regexp_replace(context_bankingdate, '(\\d{4})(\\d{2})(\\d{2})', '$1-$2-$3') AS DATE)
            							ELSE cast(regexp_replace(context_cobdate, '(\\d{4})(\\d{2})(\\d{2})', '$1-$2-$3') AS DATE) END			   ORDER BY K_PROCESSINGTIME DESC) AS RNK
            
            			 FROM stg_t24.fodb_aa_arr_interest_fixedrate
            			  where context_operation = 'WRITE'
            			  	)int_fixrate
            			where rnk =1
            			  
                    
            			  
                    )AA_FIXEDRATE 
            		ON AA_FIXEDRATE.K_ENTITYID = BB.K_ENTITYID
            		AND AA_FIXEDRATE.DT = BB.DT
            		
            		LEFT JOIN 
            		(
            			   SELECT distinct
            			   SUBSTRING(K_ENTITYID ,0,12) AS K_ENTITYID
            			   ,SUBSTRING(REC_INDEX ,0,1) AS REC_INDEX
            			     ,CASE when context_cobdate = 'null' THEN cast(regexp_replace(context_bankingdate, '(\\d{4})(\\d{2})(\\d{2})', '$1-$2-$3') AS DATE) 
            			      			when context_cobdate = '' THEN cast(regexp_replace(context_bankingdate, '(\\d{4})(\\d{2})(\\d{2})', '$1-$2-$3') AS DATE) 
            			  				when context_cobdate is null THEN cast(regexp_replace(context_bankingdate, '(\\d{4})(\\d{2})(\\d{2})', '$1-$2-$3') AS DATE)
            							ELSE cast(regexp_replace(context_cobdate, '(\\d{4})(\\d{2})(\\d{2})', '$1-$2-$3') AS DATE) END AS dt
            			   ,MARGINRATE
            			   FROM stg_t24.fodb_aa_arr_interest_fixedrate_margintype 
            			   where context_operation = 'WRITE'
            		)AA_MARGINTYPE
            		ON AA_MARGINTYPE.K_ENTITYID =  AA_FIXEDRATE.K_ENTITYID
            		AND AA_MARGINTYPE.REC_INDEX = AA_FIXEDRATE.REC_INDEX
            		AND AA_MARGINTYPE.DT = BB.DT
             
            	   QUALIFY ROW_NUMBER() OVER (PARTITION BY BB.K_ENTITYID, AA_FIXEDRATE.REC_INDEX , AA_MARGINTYPE.REC_INDEX, BB.DT ORDER BY BB.DT DESC) =1    
                )RATES
                ON Cal_Base.K_ENTITYID = RATES.K_ENTITYID        
            )FX on cal.calendar_Dt between FX.strt_dt AND FX.end_dt
            and FX.K_ENTITYID = cal.K_ENTITYID
            
             
            LEFT JOIN 
            (
                    SELECT 
            		trim(ACCOUNT_NUM) AS ACCOUNT_NUM,
            		max(CASE when typesysdate = 'TOTCOMMITMENT' THEN COALESCE(openbalance ,'0' ) END) Commitment_Amount, 
            		max(CASE when typesysdate = 'CURACCOUNT'    THEN COALESCE(openbalance ,'0' ) END) PRINCIPAL_CURRENT
                    FROM 
                    (               
            			SELECT DISTINCT 
            			  typesysdate
            			,ACCT_TYPES.k_entityid AS ACCOUNT_NUM
            			,CAST(OPENBALANCE AS FLOAT) OPENBALANCE
            			,ACCT_TYPES.DT
                        FROM 
                        (
            				SELECT  * 
            				FROM 
                            (
            							SELECT  DISTINCT K_ENTITYID,
            							typesysdate,
            							rec_index,
            							CASE when context_cobdate = 'null' THEN context_bankingdate when context_cobdate = '' THEN context_bankingdate when context_cobdate is null THEN context_bankingdate ELSE context_cobdate END AS dt,
            							Rank() OVER(PARTITION BY K_ENTITYID, typesysdate ORDER BY k_processingtime ASC,INSERT_DATE ASC) RNK
            							FROM stg_t24.fodb_eb_contract_balances_typesysdate
            							where context_operation = 'WRITE'
                            )EB_TYPESYSDATE
                            WHERE RNK = 1
                        )ACCT_TYPES
                        INNER JOIN
                        (
            				   SELECT DISTINCT * 
            				   FROM 
            				   (
            						SELECT  DISTINCT
            						
            						K_ENTITYID,
            						OPENBALANCE,
            						substr(rec_index, 1, 1) rec_ind,
            						CASE when context_cobdate = 'null' THEN context_bankingdate when context_cobdate = '' THEN context_bankingdate when context_cobdate is null THEN context_bankingdate ELSE context_cobdate END AS dt,
            						rank() OVER(PARTITION BY K_ENTITYID ORDER BY k_processingtime ASC,INSERT_DATE ASC) RNK
            						FROM stg_t24.fodb_eb_contract_balances_typesysdate_matdate
            						where context_operation = 'WRITE'
            			        )BALANCES_MATDATE
            					WHERE RNK = 1
            			)ACCT_BAL
            			ON  ACCT_BAL.K_ENTITYID =  ACCT_TYPES.K_ENTITYID
            		    AND ACCT_BAL.rec_ind = ACCT_TYPES.rec_index
            		    AND ACCT_BAL.dt = ACCT_TYPES.dt
             
                    )cal
                    GROUP BY ACCOUNT_NUM
            )BAL 
            ON BAL.ACCOUNT_NUM = LNKD_ACCT.acct_key
             
            LEFT JOIN
            (
            	SELECT
            	Idcomp_D_1
            	,Tenor
             
            	FROM
            	(
            			SELECT   
            			K_ENTITYID
            			FROM BASE
            			GROUP BY K_ENTITYID
            	)Cal_Base    
            	INNER JOIN
            	(
            			SELECT DISTINCT
            			Idcomp_D_1
            			,changeperiod  AS Tenor 
            			,RANK() OVER (PARTITION BY Idcomp_D_1 ORDER BY k_processingtime DESC)AS RNK
            			FROM stg_t24.fodb_aa_arr_change_product
            			where context_operation = 'WRITE'
            	)prod 
            	ON Cal_Base.K_ENTITYID = prod.Idcomp_D_1
            	WHERE prod.RNK = 1
            )AA_TNOR 
            ON AA_TNOR.IDCOMP_D_1 = cal.K_ENTITYID
             
            LEFT JOIN
            (
            	SELECT
            	Idcomp_D_1
            	,Term
            	FROM 
            	(
            		SELECT   
            		K_ENTITYID
            		FROM BASE
            		GROUP BY K_ENTITYID
            	)Cal_Base   
                INNER JOIN
            	(
            		SELECT DISTINCT
            		idcomp_d_1
            		,term
            		,ROW_NUMBER() OVER (PARTITION BY idcomp_d_1 ORDER BY k_processingtime DESC) AS RNK
            		FROM stg_t24.fodb_aa_arr_term_amount
            		where context_operation = 'WRITE'
            	)AA_AMT 
                ON Cal_Base.K_ENTITYID = AA_AMT.Idcomp_D_1
                WHERE AA_AMT.RNK = 1
            )AA_TERM
            ON AA_TERM.idcomp_d_1 = cal.k_entityid
             
            LEFT JOIN
            (
            	  SELECT
            	  k_entityid
            	  ,ACCOUNTTITLE_D_1 AS PROD_TITL
            	  FROM 
            	  (
            		    SELECT DISTINCT
            			k_entityid
            			,ACCOUNTTITLE_D_1
            			,ROW_NUMBER() OVER (PARTITION BY k_entityid ORDER BY k_processingtime DESC) AS RNK
            			
            			FROM stg_t24.fodb_account_accounttitle_d_1 
            			where context_operation = 'WRITE'
            	  )TITLE
             
            	  WHERE TITLE.RNK = 1
            )ACCT_TITL
            ON ACCT_TITL.K_ENTITYID = LNKD_ACCT.acct_key
             
             
            LEFT JOIN 
            (
               SELECT  
            	AA_LINKTYPE.K_ENTITYID
               ,MAX(CASE when LINKTYPE = 'PAYIN.ACCOUNT' THEN LINKEDAPPLID END)  as FUNDNG_PAYIN_ACCT_KEY
               ,MAX(CASE when LINKTYPE = 'PAYOUT.ACCOUNT' THEN LINKEDAPPLID END) as REDMPTN_PAYOUT_ACCT_KEY
               ,MAX(CASE when LINKTYPE = 'SETTLEMENT.ACCOUNT' THEN LINKEDAPPLID END) as INT_STLMNT_ACCT_KEY
               ,cast(regexp_replace(AA_LINKTYPE.DT, '(\\d{4})(\\d{2})(\\d{2})', '$1-$2-$3') AS DATE)  AS STRT_DT
               ,COALESCE(date_sub(LEAD(cast(regexp_replace(AA_LINKTYPE.DT, '(\\d{4})(\\d{2})(\\d{2})', '$1-$2-$3') AS DATE)) OVER (PARTITION by AA_LINKTYPE.K_ENTITYID ORDER BY cast(regexp_replace(AA_LINKTYPE.DT, '(\\d{4})(\\d{2})(\\d{2})', '$1-$2-$3') AS DATE) ASC), 1)
                         ,cast(regexp_replace('2999-12-31', '(\\d{4})(\\d{2})(\\d{2})', '$1-$2-$3') AS DATE)) AS END_DT	
            	FROM
            	(
            		SELECT   
            		K_ENTITYID
            		FROM BASE
            		GROUP BY K_ENTITYID
            	)Cal_Base     
             
                                                
                INNER JOIN 
                (
            		SELECT  * 
            		FROM 
            		(
            			SELECT   
            			K_ENTITYID,
            		    LINKTYPE,
            			LINKARRANGEMENT,
            			k_processingtime,
            			CASE when context_cobdate = 'null' THEN context_bankingdate when context_cobdate = '' THEN context_bankingdate when context_cobdate is null THEN context_bankingdate ELSE context_cobdate END AS dt,
            			Rank() OVER(PARTITION BY K_ENTITYID, CASE when context_cobdate = 'null' THEN context_bankingdate when context_cobdate = '' THEN context_bankingdate when context_cobdate is null THEN context_bankingdate ELSE context_cobdate END ORDER BY k_processingtime DESC) RNK
             
            			FROM stg_t24.fodb_aa_arrangement_linkdate_linktype 
            			where context_operation = 'WRITE'
             
                    )LINKTYPE
            		WHERE RNK = 1
            	)AA_LINKTYPE 
            	on Cal_Base.K_ENTITYID = AA_LINKTYPE.K_ENTITYID
            	INNER JOIN
            	(
            		SELECT  DISTINCT
            		K_ENTITYID,
            		LINKEDAPPLID
            		FROM stg_t24.fodb_aa_arrangement_linkedappl
            		where context_operation = 'WRITE'
            	)ACCT_LINKDAPP
            	ON ACCT_LINKDAPP.K_ENTITYID = AA_LINKTYPE.LINKARRANGEMENT 
            	GROUP BY  AA_LINKTYPE.K_ENTITYID , AA_LINKTYPE.DT
            )ACCT_LNKD
            ON ACCT_LNKD.K_ENTITYID = cal.K_ENTITYID
            AND cal.calendar_Dt between ACCT_LNKD.strt_dt AND ACCT_LNKD.end_dt
             
             
            LEFT JOIN
            (
            	SELECT DISTINCT 
            	PYMNTYPE.k_entityid
            	,cast(regexp_replace(PYMNTYPE.dt, '(\\d{4})(\\d{2})(\\d{2})', '$1-$2-$3') AS DATE) as strt_dt
            	,COALESCE(date_sub(LEAD(cast(regexp_replace(PYMNTYPE.dt, '(\\d{4})(\\d{2})(\\d{2})', '$1-$2-$3') AS DATE)) OVER (PARTITION by PYMNTYPE.K_ENTITYID ORDER BY cast(regexp_replace(PYMNTYPE.dt, '(\\d{4})(\\d{2})(\\d{2})', '$1-$2-$3') AS DATE) ASC), 1)
            	       ,cast(regexp_replace('2999-12-31', '(\\d{4})(\\d{2})(\\d{2})', '$1-$2-$3') AS DATE)) AS END_DT	
            	,PAYMENTMETHOD
                FROM
            	(
            			SELECT DISTINCT  
            			K_ENTITYID
            			FROM BASE
            			GROUP BY K_ENTITYID
                )Cal_Base 
            	INNER JOIN
            	(
            		   SELECT 
            		   SUBSTRING(k_entityid, 1, LOCATE('-', k_entityid)-1) AS k_entityid,
            		   CASE when context_cobdate = 'null' THEN context_bankingdate when context_cobdate = '' THEN context_bankingdate when context_cobdate is null THEN context_bankingdate ELSE context_cobdate END AS dt,
            		   PAYMENTMETHOD,
            		   ROW_NUMBER() OVER(PARTITION BY SUBSTRING(k_entityid, 1, LOCATE('-', k_entityid)-1), CASE when context_cobdate = 'null' THEN context_bankingdate when context_cobdate = '' THEN context_bankingdate when context_cobdate is null THEN context_bankingdate ELSE context_cobdate END ORDER BY k_processingtime DESC) AS RNK
             
            		   FROM stg_t24.fodb_aa_arr_payment_schedule_paymenttype 
                       WHERE COALESCE(PAYMENTMETHOD,'NA') != 'DUE'
                       and context_operation = 'WRITE'
                )PYMNTYPE
                ON Cal_Base.K_ENTITYID = PYMNTYPE.K_ENTITYID
            	WHERE PYMNTYPE.RNK = 1 
            )AA_PYMNT
            ON AA_PYMNT.K_ENTITYID = cal.K_ENTITYID
            AND  cal.calendar_Dt between AA_PYMNT.strt_dt AND AA_PYMNT.end_dt
             
            LEFT JOIN
            (
             
            	SELECT
            	ACCT_FODB.k_entityid
            	,arrangementid
            	,Category      as ctgy_key
            	,opencategory  as opn_ctgy_key 
            	,parentaccount as prnt_acct_key
            	,cocode        as chnl_key 
            	,context_operation
            	,cast(regexp_replace(ACCT_FODB.dt, '(\\d{4})(\\d{2})(\\d{2})', '$1-$2-$3') AS DATE) as strt_dt
            	,COALESCE(date_sub(LEAD(cast(regexp_replace(ACCT_FODB.dt, '(\\d{4})(\\d{2})(\\d{2})', '$1-$2-$3') AS DATE)) OVER (PARTITION by ACCT_FODB.K_ENTITYID ORDER BY cast(regexp_replace(ACCT_FODB.dt, '(\\d{4})(\\d{2})(\\d{2})', '$1-$2-$3') AS DATE) ASC), 1)
            	          ,cast(regexp_replace('2999-12-31', '(\\d{4})(\\d{2})(\\d{2})', '$1-$2-$3') AS DATE)) AS END_DT	
             
            	FROM 
            	(
            		
            			select 
            			k_entityid
            			,arrangementid
            			,CASE when context_cobdate = 'null' THEN context_bankingdate when context_cobdate = '' THEN context_bankingdate when context_cobdate is null THEN context_bankingdate ELSE context_cobdate END AS dt
            			,category
            			,opencategory
            			,CASE when parentaccount = 'null' OR parentaccount = '' THEN NULL ELSE parentaccount END AS parentaccount
            			,cocode
            			,context_operation
            			, ROW_NUMBER() OVER(PARTITION BY K_ENTITYID, CASE when context_cobdate = 'null' THEN context_bankingdate when context_cobdate = '' THEN context_bankingdate when context_cobdate is null THEN context_bankingdate ELSE context_cobdate END ORDER BY k_processingtime DESC) RNK
            			 from stg_t24.fodb_account  
            	        
            			where context_operation = 'WRITE'
             
            	)ACCT_FODB
            	where rnk=1
            	
            )ACCT
            ON ACCT.k_entityid = LNKD_ACCT.acct_key
            AND cal.calendar_Dt between ACCT.strt_dt AND ACCT.end_dt
             
            LEFT JOIN
            (
             
            	SELECT
            	Acct_f.k_entityid,context_operation
            	,cast(regexp_replace(Acct_f.dt, '(\\d{4})(\\d{2})(\\d{2})', '$1-$2-$3') AS DATE) as strt_dt
            	,COALESCE(date_sub(LEAD(cast(regexp_replace(Acct_f.dt, '(\\d{4})(\\d{2})(\\d{2})', '$1-$2-$3') AS DATE)) OVER (PARTITION by Acct_f.K_ENTITYID ORDER BY cast(regexp_replace(Acct_f.dt, '(\\d{4})(\\d{2})(\\d{2})', '$1-$2-$3') AS DATE) ASC), 1)
            	          ,cast(regexp_replace('2999-12-31', '(\\d{4})(\\d{2})(\\d{2})', '$1-$2-$3') AS DATE)) AS END_DT	
             
            	FROM 
            	(
            		select *
            		from 
            		(
            			select 
            			k_entityid
            			,CASE when context_cobdate = 'null' THEN context_bankingdate when context_cobdate = '' THEN context_bankingdate when context_cobdate is null THEN context_bankingdate ELSE context_cobdate END AS dt
            			,context_operation
            			,ROW_NUMBER() OVER(PARTITION BY K_ENTITYID, CASE when context_cobdate = 'null' THEN context_bankingdate when context_cobdate = '' THEN context_bankingdate when context_cobdate is null THEN context_bankingdate ELSE context_cobdate END ORDER BY k_processingtime DESC) RNK
            			FROM  stg_t24.FODB_AA_ARRANGEMENT	
            			 where 
            		context_operation = 'DELETE'
            		)rr
            		where rnk=1
            	)Acct_f 
            )ACCT_DLT
            ON ACCT_DLT.k_entityid = cal.k_entityid
            AND  cal.calendar_Dt between ACCT_DLT.strt_dt AND ACCT_DLT.end_dt
            
            LEFT JOIN
            (
             
            	SELECT
            	Acct_f.k_entityid,context_operation
            	,cast(regexp_replace(Acct_f.dt, '(\\d{4})(\\d{2})(\\d{2})', '$1-$2-$3') AS DATE) as strt_dt
            	,COALESCE(date_sub(LEAD(cast(regexp_replace(Acct_f.dt, '(\\d{4})(\\d{2})(\\d{2})', '$1-$2-$3') AS DATE)) OVER (PARTITION by Acct_f.K_ENTITYID ORDER BY cast(regexp_replace(Acct_f.dt, '(\\d{4})(\\d{2})(\\d{2})', '$1-$2-$3') AS DATE) ASC), 1)
            	          ,cast(regexp_replace('2999-12-31', '(\\d{4})(\\d{2})(\\d{2})', '$1-$2-$3') AS DATE)) AS END_DT	
             
            	FROM 
            	(
            		select *
            		from 
            		(
            			select 
            			k_entityid
            			,CASE when context_cobdate = 'null' THEN context_bankingdate when context_cobdate = '' THEN context_bankingdate when context_cobdate is null THEN context_bankingdate ELSE context_cobdate END AS dt
            			,context_operation
            			,ROW_NUMBER() OVER(PARTITION BY K_ENTITYID, CASE when context_cobdate = 'null' THEN context_bankingdate when context_cobdate = '' THEN context_bankingdate when context_cobdate is null THEN context_bankingdate ELSE context_cobdate END ORDER BY k_processingtime DESC) RNK
            			FROm stg_t24.fodb_account 			
            			 where 
            		context_operation = 'DELETE'
            		)rr
            		where rnk=1
            	)Acct_f 
            )ACT_DLT
            ON ACT_DLT.k_entityid = LNKD_ACCT.acct_key
            AND  cal.calendar_Dt between ACT_DLT.strt_dt AND ACT_DLT.end_dt
             
            where cal.calendar_Dt between CAST('${strt_dt}' AS DATE) AND CAST('${end_dt}' AS DATE)
        ) BUS_QRY
    ) HASH_PREP
) FINAL WHERE FK_UP <> 1
