SELECT COUNT(*) FROM (
    SELECT hash_prep.*,
        CASE WHEN HASH_PREP.HASH_KEY = FIRST_VALUE(HASH_PREP.HASH_KEY) OVER(
            PARTITION BY HASH_PREP.Consl_Key, HASH_PREP.BAL_TYP ORDER BY HASH_PREP.strt_dt ASC
            ROWS BETWEEN 1 PRECEDING AND 1 PRECEDING)
        THEN 1 ELSE 0 END AS FK_UP
    FROM (
        SELECT BUS_QRY.*,
            sha2(
coalesce(CCY_KEY, '') ||
coalesce(CTGY_KEY, '') ||
coalesce(INDSTRY_KEY, '') ||
coalesce(SCTR_KEY, '') ||
coalesce(APP_KEY, '') ||
coalesce(PSTN_TYP, '') ||
coalesce(OFCR_KEY, '') ||
coalesce(TENR, '') ||
coalesce(month_time, '') ||
coalesce(day_time, '') ||
coalesce(BAL, '') ||
coalesce(DBT_MVT, '') ||
coalesce(CRD_MVT, '') ||
coalesce(LCL_BAL, '') ||
coalesce(LCL_DBT_MVT, '') ||
coalesce(LCL_CRD_MVT, '') ||
coalesce(TOT_LCL_BAL, '') ||
coalesce(TOT_FCY_BAL, '') ||
coalesce(TEC_STS, '')
            , 256) AS HASH_KEY
        FROM (
            
                                     with Base as  
                                         (
                                            SELECT 
                                        	Al_bal.*
                                        	,Case  
                                        		When	
                                        		coalesce(
                                        		 LEAD(Al_bal.strt_dt) OVER (PARTITION BY Al_bal.Consl_Key,Al_bal.Bal_typ ORDER BY Al_bal.Strt_dt) ,date '2999-12-31') > End_Dt_per_consl then 'Deleted'
                                        			
                                        		ELSe 'Active'
                                        	 End as CONSL_BAL_STS_FLG 
                                        	,COALESCE(End_Dt_per_consl, DATE '2999-12-31' ) AS end_dt
                                        	From 
                                        	(
                                        			select 
                                        			Consl_Key
                                        			,strt_dt
                                        			,COALESCE(
                                        				DATE_ADD(
                                        						LEAD(strt_dt) OVER (PARTITION BY Consl_Key ORDER BY strt_dt),0 ),DATE '2999-12-31'
                                        			  ) AS End_Dt_per_consl
                                        			
                                        			From 
                                        			(
                                        				select distinct 
                                        				k_entityid as Consl_Key,
                                        				From_unixtime(unix_timestamp(case when context_cobdate in ('','null') OR context_cobdate IS NULL then context_bankingdate else context_cobdate end ,'yyyyMMdd'),'yyyy-MM-dd') STRT_DT
                                        				
                                        				From stg_t24.fodb_consolidate_asst_liab_type
                                        				
                                        			)AL	
                                        		    
                                        	)CNSL_BAL_BASE
                                        		  
                                        	inner join 
                                        	(
                                        			select * 
                                        			From 
                                        			(
                                        				Select
                                        				K_ENTITYID AS Consl_Key,
                                        				TYPE AS BAL_TYP,
                                        				CAST(CASE WHEN BALANCE IN ('','null') OR BALANCE IS NULL THEN '0.00' ELSE BALANCE END AS DECIMAL(18,2)) AS BAL,
                                        				CAST(CASE WHEN DEBITMOVEMENT IN ('','null') OR DEBITMOVEMENT IS NULL THEN '0.00' ELSE DEBITMOVEMENT END AS DECIMAL(18,2)) AS DBT_MVT,
                                        				CAST(CASE WHEN CREDITMOVEMENT IN ('','null')OR CREDITMOVEMENT IS NULL THEN '0.00' ELSE CREDITMOVEMENT END AS DECIMAL(18,2)) AS CRD_MVT,
                                        				CAST(CASE WHEN LOCALBALANCE IN ('','null')  OR LOCALBALANCE   IS NULL  THEN '0.00' ELSE LOCALBALANCE END AS DECIMAL(18,2)) AS LCL_BAL,
                                        				CAST(CASE WHEN LOCALDEBITMVE IN ('','null') OR LOCALDEBITMVE IS NULL THEN '0.00' ELSE LOCALDEBITMVE END AS DECIMAL(18,2)) AS LCL_DBT_MVT,
                                        				CAST(CASE WHEN LOCALCREDTMVE IN ('','null') OR LOCALCREDTMVE IS NULL THEN '0.00' ELSE LOCALCREDTMVE END AS DECIMAL(18,2)) AS LCL_CRD_MVT,
                                        				From_unixtime(unix_timestamp(case when context_cobdate in ('','null') OR context_cobdate IS NULL then context_bankingdate else context_cobdate end ,'yyyyMMdd'),'yyyy-MM-dd') STRT_DT,
                                        				ROW_NUMBER() OVER(PARTITION BY K_ENTITYID,TYPE, CASE WHEN context_cobdate IN( 'null','') OR  context_cobdate IS NULL then context_bankingdate else context_cobdate END  ORDER BY k_processingtime DESC,insert_date desc) RNK
                                        			
                                        				From stg_t24.fodb_consolidate_asst_liab_type 
                                        				
                                        			)AL_TYP
                                        			WHERE RNK = 1 
                                        	)Al_bal        
                                        	ON Al_bal.Consl_Key = CNSL_BAL_BASE.Consl_Key 
                                        	and  Al_bal.strt_dt = CNSL_BAL_BASE.strt_dt 
                                        	
                                        			 
                                        ) 
                                        
                                        
                                        SELECT  
                                        ASST_LIAB.Consl_Key, --KEY
                                        BAL_TYP,   --KEY
                                        CAL_Base.Calendar_dt as strt_dt,
                                        COALESCE(AL_DLTD.CCY_KEY,ASST_LIAB.CCY_KEY) AS CCY_KEY,
                                        COALESCE(AL_DLTD.CTGY,ASST_LIAB.CTGY) AS CTGY_KEY,
                                        COALESCE(AL_DLTD.INDSTRY,ASST_LIAB.INDSTRY) AS INDSTRY_KEY,
                                        COALESCE(AL_DLTD.SCTR_KEY,ASST_LIAB.SCTR_KEY) AS SCTR_KEY,
                                        COALESCE(AL_DLTD.APP_KEY,ASST_LIAB.APP_KEY) AS APP_KEY,
                                        COALESCE(AL_DLTD.PSTN_TYP,ASST_LIAB.PSTN_TYP) AS PSTN_TYP,
                                        COALESCE(AL_DLTD.OFCR_KEY,ASST_LIAB.OFCR_KEY) AS OFCR_KEY,
                                        COALESCE(AL_DLTD.TENR,ASST_LIAB.TENR) AS TENR,
                                        COALESCE(CASE 
                                        	  WHEN SUBSTRING(COALESCE(AL_DLTD.TENR,ASST_LIAB.TENR), 2, 1) = 'M' then cast(SUBSTRING(COALESCE(AL_DLTD.TENR,ASST_LIAB.TENR), 1, 1) as int)
                                        	  WHEN SUBSTRING(COALESCE(AL_DLTD.TENR,ASST_LIAB.TENR), 2, 1) = 'Y' then cast(SUBSTRING(COALESCE(AL_DLTD.TENR,ASST_LIAB.TENR), 1, 1) as int)*12
                                        	  WHEN SUBSTRING(COALESCE(AL_DLTD.TENR,ASST_LIAB.TENR), 2, 1) = 'W' then cast(SUBSTRING(COALESCE(AL_DLTD.TENR,ASST_LIAB.TENR), 1, 1) as int)/4
                                        	 END,0) AS month_time,
                                        COALESCE(CASE 
                                        	  WHEN SUBSTRING(COALESCE(AL_DLTD.TENR,ASST_LIAB.TENR), 2, 1) = 'D' then cast(SUBSTRING(COALESCE(AL_DLTD.TENR,ASST_LIAB.TENR), 1, 1) as int)
                                        	  WHEN SUBSTRING(COALESCE(AL_DLTD.TENR,ASST_LIAB.TENR), 2, 1) = 'M' then cast(SUBSTRING(COALESCE(AL_DLTD.TENR,ASST_LIAB.TENR), 1, 1) as int)*30
                                        	  WHEN SUBSTRING(COALESCE(AL_DLTD.TENR,ASST_LIAB.TENR), 2, 1) = 'Y' then cast(SUBSTRING(COALESCE(AL_DLTD.TENR,ASST_LIAB.TENR), 1, 1) as int)*365
                                        	  WHEN SUBSTRING(COALESCE(AL_DLTD.TENR,ASST_LIAB.TENR), 2, 1) = 'W' then cast(SUBSTRING(COALESCE(AL_DLTD.TENR,ASST_LIAB.TENR), 1, 1) as int)*7
                                        	 END,0) day_time,
                                        CASE WHEN context_operation = 'DELETE' THEN 0 ELSE BAL END        AS BAL,
                                        CASE WHEN context_operation = 'DELETE' THEN 0 ELSE DBT_MVT END    AS DBT_MVT,
                                        CASE WHEN context_operation = 'DELETE' THEN 0 ELSE CRD_MVT END    AS CRD_MVT,
                                        CASE WHEN context_operation = 'DELETE' THEN 0 ELSE LCL_BAL END    AS LCL_BAL,
                                        CASE WHEN context_operation = 'DELETE' THEN 0 ELSE LCL_DBT_MVT END AS LCL_DBT_MVT,
                                        CASE WHEN context_operation = 'DELETE' THEN 0 ELSE LCL_CRD_MVT END AS LCL_CRD_MVT,
                                        CASE 
                                          WHEN ASST_LIAB.context_operation = 'DELETE' THEN 0
                                          WHEN ASST_LIAB.CCY_KEY != 'EGP'
                                        	   THEN (LCL_BAL + LCL_DBT_MVT + LCL_CRD_MVT)
                                          ELSE (BAL + DBT_MVT + CRD_MVT)
                                        END AS TOT_LCL_BAL,
                                        CASE 
                                          WHEN ASST_LIAB.context_operation = 'DELETE' THEN 0
                                          WHEN ASST_LIAB.CCY_KEY = 'EGP' THEN 0
                                          ELSE (BAL + DBT_MVT + CRD_MVT)
                                        END AS TOT_FCY_BAL,
                                        prcsng_dttm,
                                        case 
                                         when context_operation = 'WRITE'  and  ASST_TYP.CONSL_BAL_STS_FLG = 'Active' then 'Active' 
                                         when context_operation = 'WRITE'  and  ASST_TYP.CONSL_BAL_STS_FLG = 'Deleted' then 'Deleted'
                                         ELSE 'Deleted' 
                                        End TEC_STS
                                        From 
                                        (	
                                        	SELECT Calendar_dt
                                        	From reporting_schema.calendar_base
                                        	WHERE Calendar_dt  BETWEEN '${strt_dt}' AND '${end_dt}'
                                        )CAL_Base
                                        
                                        inner join 
                                        (
                                          SELECT 
                                           *
                                          ,COALESCE(
                                        		  DATE_ADD(
                                        			  LEAD(strt_dt) OVER (PARTITION BY Consl_Key ORDER BY strt_dt),-1
                                        		  ),DATE '2999-12-31'
                                        	) AS end_dt
                                          From
                                          (
                                        		SELECT 
                                        		k_entityid AS Consl_Key,
                                        		CURRENCY AS CCY_KEY,
                                        		applicid AS APP_KEY,
                                        		positiontype AS PSTN_TYP,
                                        		CAST(CASE WHEN CATEGORY IN ('null','') THEN null ELSE CATEGORY END AS int) CTGY,
                                        		CAST(CASE WHEN INDUSTRY IN ('null','') THEN null ELSE INDUSTRY END AS int) INDSTRY,
                                        		CAST(CASE WHEN SECTOR   IN ('null','') THEN null ELSE SECTOR   END AS int) SCTR_KEY,
                                        		CASE WHEN `time`  in( 'null', '') then NULL else `time` END TENR,
                                        		CAST(CASE WHEN dao   IN ('null','') THEN null ELSE dao   END AS int) OFCR_KEY,
                                        		From_unixtime(cast(CAST(k_processingtime as BIGINT) / 1000 as int), "yyyy-MM-dd HH:mm:ss") prcsng_dttm,
                                        		context_operation,
                                        		From_unixtime(unix_timestamp(case when context_cobdate in ('','null') OR context_cobdate IS NULL then context_bankingdate else context_cobdate end ,'yyyyMMdd'),'yyyy-MM-dd') STRT_DT, 
                                        		row_number() OVER(PARTITION BY k_entityid, CASE WHEN context_cobdate IN('null', '') OR context_cobdate IS NULL then context_bankingdate else context_cobdate END  ORDER BY k_processingtime DESC,insert_date DESC) RNK
                                        		
                                        		From stg_t24.fodb_consolidate_asst_liab 
                                          )Al 
                                          WHERE RNK = 1
                                        )ASST_LIAB 
                                        ON  CAL_Base.Calendar_dt BETWEEN ASST_LIAB.STRT_DT AND ASST_LIAB.end_dt
                                        
                                        LEFT JOIN 
                                        (
                                        	
                                        	select   Consl_Key , bal_typ , bal , dbt_mvt , crd_mvt , lcl_bal , lcl_dbt_mvt , lcl_crd_mvt , strt_dt , rnk , 'Active' as CONSL_BAL_STS_FLG , DATE_ADD(end_dt,-1) AS end_dt
                                        	From Base
                                        	
                                        	UNION 
                                        	 
                                        	select   Consl_Key , bal_typ , bal , dbt_mvt , crd_mvt , lcl_bal , lcl_dbt_mvt , lcl_crd_mvt ,cast(end_dt as string) AS strt_dt , rnk , CONSL_BAL_STS_FLG ,end_dt 
                                        	From Base
                                        	where  CONSL_BAL_STS_FLG = 'Deleted'	
                                        )ASST_TYP 
                                        ON ASST_TYP.Consl_Key = ASST_LIAB.Consl_Key 
                                        AND CAL_Base.Calendar_dt BETWEEN ASST_TYP.STRT_DT AND ASST_TYP.end_dt
                                        
                                        LEFT JOIN 
                                        (
                                            SELECT 
                                        	*
                                        	,COALESCE(
                                        		  DATE_ADD(
                                        			  LEAD(strt_dt) OVER (PARTITION BY Consl_Key ORDER BY strt_dt),-1
                                        		  ),DATE '2999-12-31'
                                        	  ) AS end_dt
                                        	From
                                        	(
                                        		SELECT 
                                        		k_entityid AS Consl_Key,
                                        		CURRENCY AS CCY_KEY,
                                        		applicid AS APP_KEY,
                                        		positiontype AS PSTN_TYP,
                                        		CAST(CASE WHEN CATEGORY IN ('null','') THEN null ELSE CATEGORY END AS int) CTGY,
                                        		CAST(CASE WHEN INDUSTRY IN ('null','') THEN null ELSE INDUSTRY END AS int) INDSTRY,
                                        		CAST(CASE WHEN SECTOR   IN ('null','') THEN null ELSE SECTOR   END AS int) SCTR_KEY,
                                        			CASE WHEN `time`  in( 'null', '') then NULL else `time` END TENR,
                                        			CAST(CASE WHEN dao   IN ('null','') THEN null ELSE dao   END AS int) OFCR_KEY,
                                        		From_unixtime(unix_timestamp(case when context_cobdate in ('','null') OR context_cobdate IS NULL then context_bankingdate else context_cobdate end ,'yyyyMMdd'),'yyyy-MM-dd') STRT_DT,
                                        		case when context_operation = 'WRITE' then 'Active' ELSE 'Deleted' end TEC_STS, 
                                        		row_number() OVER(PARTITION BY k_entityid, CASE WHEN context_cobdate IN('null', '') OR context_cobdate IS NULL then context_bankingdate else context_cobdate END  ORDER BY k_processingtime DESC,insert_date DESC) RNK
                                        		
                                        		From stg_t24.fodb_consolidate_asst_liab 
                                        		WHERE context_operation = 'WRITE'
                                            )Al 
                                            WHERE RNK = 1
                                        )AL_DLTD
                                        ON AL_DLTD.Consl_Key = ASST_LIAB.Consl_Key 
                                        AND CAL_Base.Calendar_dt BETWEEN AL_DLTD.STRT_DT AND AL_DLTD.end_dt
                                        AND ASST_LIAB.context_operation = 'DELETE'
        ) BUS_QRY
    ) HASH_PREP
) FINAL WHERE FK_UP <> 1
