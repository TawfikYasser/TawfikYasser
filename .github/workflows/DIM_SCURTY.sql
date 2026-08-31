SELECT COUNT(*) FROM (
    SELECT hash_prep.*,
        CASE WHEN HASH_PREP.HASH_KEY = FIRST_VALUE(HASH_PREP.HASH_KEY) OVER(
            PARTITION BY HASH_PREP.scurty_key ORDER BY HASH_PREP.strt_dt ASC
            ROWS BETWEEN 1 PRECEDING AND 1 PRECEDING)
        THEN 1 ELSE 0 END AS FK_UP
    FROM (
        SELECT BUS_QRY.*,
            sha2(
coalesce(isin, '') ||
coalesce(mnemic, '') ||
coalesce(descr, '') ||
coalesce(Ccy_key, '') ||
coalesce(ctry_key, '') ||
coalesce(sub_asset_typ, '') ||
coalesce(price_typ, '') ||
coalesce(int_rate, '') ||
coalesce(mrkt_price, '') ||
coalesce(indstry_cd, '') ||
coalesce(stk_exch, '') ||
coalesce(dpostry, '') ||
coalesce(pymnt_num, '') ||
coalesce(authrzr, '') ||
coalesce(inputr, '') ||
coalesce(chnl_key, '') ||
coalesce(dept_code, '')
            , 256) AS HASH_KEY
        FROM (
            SELECT 
             Scurty_mstr.k_entityid as scurty_key
            ,scurty_mstr.strt_dt
            ,scurty_mstr.isin_d_ as isin
            ,scurty_mstr.mnemonic  as mnemic
            ,scurty_shortname.shortname as descr
            ,scurty_mstr.securitycurrency as Ccy_key
            ,scurty_mstr.securitydomicile as ctry_key
            ,scurty_mstr.subassettype as sub_asset_typ
            ,scurty_mstr.pricetype	as price_typ
            ,scurty_intrate.interestrate as int_rate
            ,scurty_mstr.lastprice  as mrkt_price
            ,scurty_mstr.industrycode as indstry_cd
            ,scurty_mstr.stockexchange as stk_exch
            ,scurty_mstr.dpostry
            ,scurty_mstr.issu_dt
            ,scurty_mstr.int_pymnt_dt  --- added   20-05-26
            ,scurty_mstr.copn_divcut_dt -- added   20-05-26
            ,scurty_mstr.mat_dt
            ,scurty_mstr.noofpayments as pymnt_num
            ,scurty_mstr.authoriser as authrzr
            ,scurty_inputr.inputter as inputr
            ,scurty_mstr.cocode as chnl_key
            ,scurty_mstr.deptcode as dept_code
            
            FROM
                (
            		SELECT *
            		FROM
            		(
            				SELECT 
            				k_entityid,
            				from_unixtime(unix_timestamp(CASE When context_cobdate in ('','null')  or context_cobdate is null Then context_bankingdate ELSE context_cobdate End ,'yyyyMMdd'),'yyyy-MM-dd') STRT_DT,
            				CASE WHEN TRIM(mnemonic) IN ('','null')  THEN null ELSE mnemonic END AS mnemonic,
            				securitycurrency,
            				subassettype,
            				isin_d_,
            				pricetype,
            				Cast(CASE WHEN lastprice IN('','null') or lastprice is null THEN '1.00' ELSE lastprice END  AS DECIMAL(6,4)) as lastprice,
            				Companydomicile,
            				Securitydomicile,
            				industrycode,
            				stockexchange,
            				CASE WHEN TRIM(defaultdepository) IN ('','null') or defaultdepository is null THEN '-1' ELSE defaultdepository END AS DPOSTRY,
            				noofpayments,
            				from_unixtime(unix_timestamp(issuedate,'yyyyMMdd'),'yyyy-MM-dd')AS Issu_Dt,
            				from_unixtime(unix_timestamp(maturitydate,'yyyyMMdd'),'yyyy-MM-dd') AS Mat_Dt,
            				from_unixtime(unix_timestamp(intpaymentdate,'yyyyMMdd'),'yyyy-MM-dd') AS 	Int_Pymnt_dt,
            				from_unixtime(unix_timestamp(coupdivcutdate,'yyyyMMdd'),'yyyy-MM-dd') AS 	copn_divcut_dt,
            				authoriser,
            				Cocode,
            				deptcode,
            				Cast(from_unixtime(Cast(Cast(k_processingtime as BIGINT) / 1000 as int), "yyyy-MM-dd HH:mm:ss") AS TIMESTAMP) Strt_Dttm,
            				ROW_NUMBER() over(PARTITION by k_entityid ORDER by k_processingtime desc ) rnk
                            FROM STG_t24.f_security_master 
            				WHERE  from_unixtime(unix_timestamp(CASE When context_cobdate in ('','null')  or context_cobdate is null Then context_bankingdate ELSE context_cobdate End ,'yyyyMMdd'),'yyyy-MM-dd') 
            				BETWEEN '${STRT_DT}'  AND '${END_DT}'
            
            		)s
            		WHERE s.rnk = 1
            	)SCURTY_MSTR
            	
            	
            	LEFT JOIN 
            	(
            		SELECT * 
            		FROM 
            		(		SELECT 
            				k_entityid,
            				shortname,
            				ROW_NUMBER() over(PARTITION by k_entityid ORDER by k_processingtime desc ) rnk
            				
            				FROM stg_t24.f_security_master_shortname
                    )SHORTNAME
            		WHERE rnk = 1
            		
            	)SCURTY_SHORTNAME
            	ON SCURTY_SHORTNAME.k_entityid = SCURTY_MSTR.k_entityid
            
            
            
            	
            
            	LEFT JOIN 
            	(
            		SELECT * 
            		FROM 
            		(		SELECT 
            				k_entityid,
            				Cast(CASE WHEN TRIM(interestrate) IN('','null') or interestrate is null THEN '1.00' ELSE interestrate END  AS DECIMAL(6,4)) AS interestrate,
            				ROW_NUMBER() over(PARTITION by k_entityid ORDER by k_processingtime desc ) rnk
            				
            			FROM stg_t24.f_security_master_interestrate
            				WHERE REC_INDEX = '0'
            			
                    )SCURTY_RATE
            		WHERE rnk = 1
            	)SCURTY_INTRATE
            	ON SCURTY_INTRATE.k_entityid = SCURTY_MSTR.k_entityid 
            
            	LEFT JOIN 
            	(
            		SELECT * 
            		FROM 
            		(		SELECT 
            				k_entityid,
            				Inputter,
            				ROW_NUMBER() over(PARTITION by k_entityid ORDER by k_processingtime desc ) rnk
            				
            				FROM stg_t24.f_security_master_inputter
            				WHERE REC_INDEX = '0'
            			
                    )INPUTR
            		WHERE rnk = 1
            		
            	)SCURTY_INPUTR
            	ON SCURTY_INPUTR.k_entityid = SCURTY_MSTR.k_entityid
        ) BUS_QRY
    ) HASH_PREP
) FINAL WHERE FK_UP <> 1
