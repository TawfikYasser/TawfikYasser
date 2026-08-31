SELECT COUNT(*) FROM (
    SELECT hash_prep.*,
        CASE WHEN HASH_PREP.HASH_KEY = FIRST_VALUE(HASH_PREP.HASH_KEY) OVER(
            PARTITION BY HASH_PREP.cust_key, HASH_PREP.indx ORDER BY HASH_PREP.strt_dt ASC
            ROWS BETWEEN 1 PRECEDING AND 1 PRECEDING)
        THEN 1 ELSE 0 END AS FK_UP
    FROM (
        SELECT BUS_QRY.*,
            sha2(
coalesce(src_of_income, '')
            , 256) AS HASH_KEY
        FROM (
            
            SELECT
            Base.cust_key
            ,base.strt_dt
            ,base.indx
            ,income_lkp.ref_val as src_of_income
            
            FROM
            (
                SELECT 
            	cust_key
            	,strt_dt
            	,EXP.SPLTD AS INDX
            	FROM
            	(	
            		
            					
            				Select
            				*,
            				Coalesce(
            					date_add(
            						lead(strt_dt) over (partition by cust_key order by strt_dt),-1
            					),date '2999-12-31'
            				) as end_dt
            				from 
            				(	
            						Select 
            						atos_customerid  as cust_key
            						,atos_sourceofincome as income_indx
            						,cast(from_unixtime(cast(modifiedon as bigint) div 1000) as date)as strt_dt
            						,row_number() over (partition by atos_customerid,atos_sourceofincome order by modifiedon asc) as rnk
            
            
            						From stg_crm.contactbase cbase
            						where  atos_customerid is not null 
            				)cntct
            				where cntct.rnk = 1
            				
            	)CUST_INCOME
                LATERAL VIEW OUTER explode(split(cast(income_indx as string), ',')) EXP AS SPLTD
            	
            	WHERE  EXP.SPLTD > 0
                AND income_indx IS NOT NULL 
            )BASE
            
            
            LEFT JOIN  dwh_base.crm_ref Income_lkp
            ON Income_lkp.ref_cd = Base.indx
            and upper(attribute_cat) = 'ATOS_SOURCEOFINCOME'
            AND Income_lkp.Lang = '1033'  
            AND Income_lkp.entity_cat = 'Contact'
            and enddt is null
        ) BUS_QRY
    ) HASH_PREP
) FINAL WHERE FK_UP <> 1
