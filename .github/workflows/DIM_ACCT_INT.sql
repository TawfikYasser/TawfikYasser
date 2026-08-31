SELECT COUNT(*) FROM (
    SELECT hash_prep.*,
        CASE WHEN HASH_PREP.HASH_KEY = FIRST_VALUE(HASH_PREP.HASH_KEY) OVER(
            PARTITION BY HASH_PREP.ACCT_KEY, HASH_PREP.INT_TYP ORDER BY HASH_PREP.strt_dt ASC
            ROWS BETWEEN 1 PRECEDING AND 1 PRECEDING)
        THEN 1 ELSE 0 END AS FK_UP
    FROM (
        SELECT BUS_QRY.*,
            sha2(
coalesce(PROD_KEY, '') ||
coalesce(WRKNG_BAL, '') ||
coalesce(TIER_RNG_STRT, '') ||
coalesce(TIER_RNG_END, '') ||
coalesce(INT_RT, '') ||
coalesce(MRGN_RT, '') ||
coalesce(TEC_STS, '')
            , 256) AS HASH_KEY
        FROM (
            SELECT * 
            FROM
            (
            SELECT 
            AA_RT.PROD_KEY 
            ,AA_ACCT.ACCT_KEY
            ,AA_RT.INT_TYP
            ,WRKNG_BAL
            ,TIER_RNG_STRT
            ,TIER_RNG_END
            ,CASE
                WHEN AA_RT.INT_TYP in('DRINTEREST','PENALTYINT','PRINCIPALINT') AND (ABS(WRKNG_BAL) > TIER_RNG_STRT) AND ABS(WRKNG_BAL) <= TIER_RNG_END THEN Eff_RT
                WHEN AA_RT.INT_TYP in( 'CRINTEREST','DEPOSITINT') AND (WRKNG_BAL >= TIER_RNG_STRT AND WRKNG_BAL < TIER_RNG_END) THEN Eff_RT
                ELSE NULL
            END AS INT_RT
            ,MRGN_RT
            ,CASE WHEN AA.Context_operation = 'DELETE' THEN 'Deleted' else 'Active' end as TEC_STS
            ,Calendar_dt AS strt_dt
            
            
            
            FROM 
            (	
            	SELECT Calendar_dt
            	FROM dwh_base.calendar_base
                
            	WHERE Calendar_dt  BETWEEN '${strt_dt}' AND '${end_dt}'
            
            )BASE
            
            
            INNER JOIN 
            (
            	SELECT
            	*
                ,COALESCE(
            		  DATE_ADD(
            			    LEAD(strt_dt) OVER (PARTITION BY SPLIT(k_Entityid, '-')[0], SPLIT(k_Entityid, '-')[1]  order by strt_dt),-1
            		        ),DATE '2999-12-31'
            		) AS end_dt
                FROM 
            	(
            		SELECT 
            		 K_ENTITYID
            		,idcomp_d_1
            		,idcomp_d_2
            		,Context_operation
            		,from_unixtime(unix_timestamp(REGEXP_REPLACE(split(K_ENTITYID, '-')[size(split(K_ENTITYID, '-')) - 1], '\\.\\d+', '')  ,'yyyyMMdd'),'yyyy-MM-dd') as  strt_dt
            
                    ,RANK() OVER (PARTITION BY  SPLIT(k_Entityid, '-')[0], SPLIT(k_Entityid, '-')[1], from_unixtime(unix_timestamp(REGEXP_REPLACE(split(K_ENTITYID, '-')[size(split(K_ENTITYID, '-')) - 1], '\\.\\d+', '')  ,'yyyyMMdd'),'yyyy-MM-dd')
            	                   ORDER BY K_PROCESSINGTIME desc, k_Entityid DESC, tec_insrt_dttm desc) AS RNK
            		                     
            		FROM stg_t24.fodb_aa_arr_interest
            		
            	)AA_INTRST
            	
            	WHERE RNK = 1
            )AA
            ON  BASE.Calendar_dt BETWEEN AA.STRT_DT AND AA.END_DT
            
            LEFT JOIN 
            (
            
            	SELECT
            	*
            	,COALESCE(
            		  DATE_ADD(
            			    LEAD(strt_dt) OVER (PARTITION BY PROD_KEY, INT_TYP ,REC_INDEX order by strt_dt),-1
            		        ),DATE '2999-12-31'
            		) AS end_dt
            	FROM 
            	(
            		SELECT 
            		 K_ENTITYID
            		,SPLIT(k_Entityid, '-')[0] AS PROD_KEY
                    ,SPLIT(k_Entityid, '-')[1] AS INT_TYP
                    ,from_unixtime(unix_timestamp(REGEXP_REPLACE(split(K_ENTITYID, '-')[size(split(K_ENTITYID, '-')) - 1], '\\.\\d+', '')  ,'yyyyMMdd'),'yyyy-MM-dd') AS int_dt
            		,REC_INDEX
            		,k_processingtime
            		,From_unixtime(unix_timestamp(case when context_cobdate in ('','null') OR context_cobdate IS NULL then context_bankingdate else context_cobdate end ,'yyyyMMdd'),'yyyy-MM-dd') STRT_DT
            		,EFFECTIVERATE AS EFF_RT
            		,coalesce(LAG(TIERAMOUNT) OVER (PARTITION BY k_Entityid, CASE WHEN context_cobdate in('', 'null') or context_cobdate is null  THEN context_bankingdate ELSE  context_cobdate END , insert_date  ORDER BY rec_index asc, tec_insrt_dttm desc) , 0.0) AS TIER_RNG_STRT
            		,coalesce(cast(TIERAMOUNT as decimal(18,4)), 9999999999)  AS TIER_RNG_END
            		,CASE WHEN context_cobdate in('', 'null') or context_cobdate is null  THEN context_bankingdate ELSE  context_cobdate END as cob_Dt
            		,insert_Date
            		,CONTEXT_OPERATION
            		,ROW_NUMBER() OVER (PARTITION BY  SPLIT(k_Entityid, '-')[0], SPLIT(k_Entityid, '-')[1], REC_INDEX,SPLIT(rec_index, '[.]')[0], from_unixtime(unix_timestamp(REGEXP_REPLACE(split(K_ENTITYID, '-')[size(split(K_ENTITYID, '-')) - 1], '\\.\\d+', '')  ,'yyyyMMdd'),'yyyy-MM-dd')
            					         , CASE WHEN context_cobdate in('', 'null') or context_cobdate is null  THEN context_bankingdate ELSE  context_cobdate END ORDER BY K_PROCESSINGTIME desc, k_Entityid DESC, tec_insrt_dttm desc) as rnk
                
            		FROM stg_t24.fodb_aa_arr_interest_fixedrate
            		WHERE from_unixtime(unix_timestamp(CASE WHEN context_cobdate in('', 'null') or context_cobdate is null  THEN context_bankingdate ELSE context_cobdate END  ,'yyyyMMdd'),'yyyy-MM-dd') 
            		BETWEEN '${strt_dt}' AND '${end_dt}'
            		
            	)AA_RT
            	
            	WHERE RNK = 1
            
            )AA_RT 
            ON  BASE.Calendar_dt BETWEEN AA_RT.STRT_DT AND AA_RT.END_DT
            AND AA_RT.K_ENTITYID = AA.K_ENTITYID
            
            LEFT JOIN 
            (
            
            	SELECT
            	*
            	,COALESCE(
            	  DATE_ADD(
            			LEAD(strt_dt) OVER (PARTITION BY  PROD_KEY,INT_TYP, REC_INDEX order by strt_dt),-1
            			),DATE '2999-12-31'
            	) AS end_dt
            
                FROM 
                (
            		SELECT 
            		k_entityid
            		,SPLIT(k_Entityid, '-')[0] AS PROD_KEY
                    ,SPLIT(k_Entityid, '-')[1] AS INT_TYP
                    ,from_unixtime(unix_timestamp(REGEXP_REPLACE(split(K_ENTITYID, '-')[size(split(K_ENTITYID, '-')) - 1], '\\.\\d+', '')  ,'yyyyMMdd'),'yyyy-MM-dd') AS INT_DT
            		,SPLIT(rec_index, '[.]')[0] AS REC_INDEX
            		,From_unixtime(unix_timestamp(case when context_cobdate in ('','null') OR context_cobdate IS NULL then context_bankingdate else context_cobdate end ,'yyyyMMdd'),'yyyy-MM-dd') STRT_DT
            		,MARGINRATE AS MRGN_RT
            		,ROW_NUMBER() OVER (PARTITION BY SPLIT(k_Entityid, '-')[0], SPLIT(k_Entityid, '-')[1], REC_INDEX,SPLIT(rec_index, '[.]')[0], from_unixtime(unix_timestamp(REGEXP_REPLACE(split(K_ENTITYID, '-')[size(split(K_ENTITYID, '-')) - 1], '\\.\\d+', '')  ,'yyyyMMdd'),'yyyy-MM-dd')
            		ORDER BY K_PROCESSINGTIME desc, k_Entityid desc, tec_insrt_dttm desc) AS RNK
            
            		FROM stg_t24.fodb_aa_arr_interest_fixedrate_margintype
            		WHERE  from_unixtime(unix_timestamp(CASE WHEN context_cobdate in('', 'null') or context_cobdate is null  THEN context_bankingdate ELSE context_cobdate END  ,'yyyyMMdd'),'yyyy-MM-dd') 
            		BETWEEN '${strt_dt}' AND '${end_dt}'
            		
            	)MRGN
            	WHERE RNK = 1
            
            )AA_MRGN
            ON AA_MRGN.k_entityid =  AA_RT.k_entityid
            AND AA_MRGN.REC_INDEX = AA_RT.REC_INDEX
            AND BASE.Calendar_dt BETWEEN AA_MRGN.STRT_DT AND AA_MRGN.END_DT
            
            lEFT JOIN
            (
            	SELECT *
            	FROM 
            	(
            
            		SELECT 
            		 k_entityid
            		,LINKEDAPPLID AS ACCT_KEY
            		,ROW_NUMBER() OVER (PARTITION BY K_ENTITYID  ORDER BY K_PROCESSINGTIME desc) AS RNK
            
            		FROM  stg_t24.fodb_aa_arrangement_linkedappl
            	
            	
            	)AA_ACCT
            	WHERE RNK = 1
            
            )AA_ACCT
            ON AA_ACCT.k_entityid = AA_RT.PROD_KEY
            
            
            LEFT JOIN
            (
            	SELECT
            	*
            	,COALESCE(
            	  DATE_ADD(
            			LEAD(strt_dt) OVER (PARTITION BY  k_Entityid order by strt_dt),-1
            			),DATE '2999-12-31'
            	) AS end_dt
            
            
            	FROM 
            	(
            
            		SELECT 
                    k_entityid
            	    ,CAST( CASE WHEN TRIM(workingbalance) = '' OR TRIM(workingbalance) = 'null' OR workingbalance IS NULL THEN 0.00 ELSE  workingbalance END AS DECIMAL(18,4) ) AS WRKNG_BAL
            		,From_unixtime(unix_timestamp(case when context_cobdate in ('','null') OR context_cobdate IS NULL then context_bankingdate else context_cobdate end ,'yyyyMMdd'),'yyyy-MM-dd') STRT_DT
            		,ROW_NUMBER() OVER (PARTITION BY K_ENTITYID ORDER BY K_PROCESSINGTIME desc, tec_insrt_dttm desc) AS RNK
            		
            		FROM stg_t24.fodb_eb_contract_balances	
            		WHERE from_unixtime(unix_timestamp(CASE WHEN context_cobdate in('', 'null') or context_cobdate is null  THEN context_bankingdate ELSE context_cobdate END  ,'yyyyMMdd'),'yyyy-MM-dd') 
            		BETWEEN '${strt_dt}' AND '${end_dt}'
            	)CNTRCT
            	WHERE RNK = 1
            	
            )CNTRCT_BAL
            ON CNTRCT_BAL.k_entityid = AA_ACCT.ACCT_KEY
            AND BASE.Calendar_dt BETWEEN CNTRCT_BAL.STRT_DT AND CNTRCT_BAL.END_DT
            
            )ACCT_INT
            
            WHERE INT_RT IS NOT NULL
        ) BUS_QRY
    ) HASH_PREP
) FINAL WHERE FK_UP <> 1
