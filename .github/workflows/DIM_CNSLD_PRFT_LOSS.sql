SELECT COUNT(*) FROM (
    SELECT hash_prep.*,
        CASE WHEN HASH_PREP.HASH_KEY = FIRST_VALUE(HASH_PREP.HASH_KEY) OVER(
            PARTITION BY HASH_PREP.CONSL_KEY, HASH_PREP.CCY_KEY ORDER BY HASH_PREP.strt_dt ASC
            ROWS BETWEEN 1 PRECEDING AND 1 PRECEDING)
        THEN 1 ELSE 0 END AS FK_UP
    FROM (
        SELECT BUS_QRY.*,
            sha2(
coalesce(PROD_TYP_KEY, '') ||
coalesce(SUB_ASST_KEY, '') ||
coalesce(CTGY_KEY, '') ||
coalesce(INDSTRY_KEY, '') ||
coalesce(SCTR_KEY, '') ||
coalesce(TRGT_KEY, '') ||
coalesce(OFCR_KEY, '') ||
coalesce(DEPT_KEY, '') ||
coalesce(TENR, '') ||
coalesce(month_time, '') ||
coalesce(day_time, '') ||
coalesce(LCL_BAL, '') ||
coalesce(LCL_DBT_MVT, '') ||
coalesce(LCL_CRD_MVT, '') ||
coalesce(FCY_BAL, '') ||
coalesce(FCY_DBT_MVT, '') ||
coalesce(FCY_CRD_MVT, '') ||
coalesce(LCL_BAL_YTD, '') ||
coalesce(FCY_BAL_YTD, '') ||
coalesce(TOT_LCL_BAL, '') ||
coalesce(TOT_FCY_BAL, '') ||
coalesce(TOT_LCL_BAL_YTD, '') ||
coalesce(TOT_FCY_BAL_YTD, '') ||
coalesce(TEC_STS, '')
            , 256) AS HASH_KEY
        FROM (
            
            SELECT
            PL.CONSL_KEY, --KEY
            BASE.Calendar_dt as strt_dt, --KEY
            COALESCE(PL_DLTD.CCY_KEY , PL_BAL.CCY_KEY) AS CCY_KEY, --KEY
            PROD_TYP_KEY,
            SUB_ASST_KEY,
            CTGY_KEY,
            INDSTRY_KEY,
            SCTR_KEY,
            TRGT_KEY,
            OFCR_KEY,
            DEPT_KEY,
            TENR,
            COALESCE(CASE 
                    WHEN SUBSTRING(PL.TENR, 2, 1) = 'M' then cast(SUBSTRING(PL.TENR, 1, 1) as int)
                    WHEN SUBSTRING(PL.TENR, 2, 1) = 'Y' then cast(SUBSTRING(PL.TENR, 1, 1) as int)*12
                    WHEN SUBSTRING(PL.TENR, 2, 1) = 'W' then cast(SUBSTRING(PL.TENR, 1, 1) as int)/4
                    END,0) AS month_time,
            COALESCE(CASE 
                    WHEN SUBSTRING(PL.TENR, 2, 1) = 'D' then cast(SUBSTRING(PL.TENR, 1, 1) as int)
                    WHEN SUBSTRING(PL.TENR, 2, 1) = 'M' then cast(SUBSTRING(PL.TENR, 1, 1) as int)*30
                    WHEN SUBSTRING(PL.TENR, 2, 1) = 'Y' then cast(SUBSTRING(PL.TENR, 1, 1) as int)*365
                    WHEN SUBSTRING(PL.TENR, 2, 1) = 'W' then cast(SUBSTRING(PL.TENR, 1, 1) as int)*7
                    END,0) day_time,
            LCL_BAL,
            LCL_DBT_MVT,
            LCL_CRD_MVT,
            FCY_BAL,
            FCY_DBT_MVT,
            FCY_CRD_MVT,
            LCL_BAL_YTD,
            FCY_BAL_YTD,
            (LCL_BAL + LCL_DBT_MVT + LCL_CRD_MVT)  AS TOT_LCL_BAL,
            (FCY_BAL + FCY_DBT_MVT + FCY_CRD_MVT)  AS TOT_FCY_BAL,
            (LCL_BAL + LCL_DBT_MVT + LCL_CRD_MVT + LCL_BAL_YTD )  AS TOT_LCL_BAL_YTD,
            (FCY_BAL + FCY_DBT_MVT + FCY_CRD_MVT + FCY_BAL_YTD )  AS TOT_FCY_BAL_YTD,
            prcsng_dttm,
            PL.TEC_STS
            
            
            FROM 
            (	
            SELECT Calendar_dt
            FROM reporting_schema.calendar_base
                
            WHERE Calendar_dt  BETWEEN '${strt_dt}' AND '${end_dt}'
            
            )BASE
            
            
            INNER JOIN 
            (
            SELECT 
            *
            ,COALESCE(
                    DATE_ADD(
                        LEAD(strt_dt) OVER (PARTITION BY CONSL_KEY ORDER BY strt_dt),-1
                    ),DATE '2999-12-31'
                ) AS End_Dt
                FROM
                (
                SELECT 
                K_ENTITYID AS CONSL_KEY,
                from_unixtime(unix_timestamp(case when context_cobdate in ('','null') OR context_cobdate IS NULL then context_bankingdate else context_cobdate end ,'yyyyMMdd'),'yyyy-MM-dd') AS STRT_DT,
                CAST(CASE WHEN PLCATEGORY IN ('null','') THEN null ELSE PLCATEGORY END AS int) AS CTGY_KEY,
                CAST(CASE WHEN PLSECTOR   IN ('null','') THEN null ELSE PLSECTOR   END AS int) AS SCTR_KEY,
                CAST(CASE WHEN PLDEPARTMENT  IN ('null','') THEN null ELSE PLDEPARTMENT   END AS int) AS DEPT_KEY,
                CAST(CASE WHEN PLINDUSTRY IN ('null','') THEN null ELSE PLINDUSTRY END AS int) AS INDSTRY_KEY,
                CAST(CASE WHEN PLPRODUCT  IN ('null','') THEN null ELSE PLPRODUCT  END AS int) AS PROD_TYP_KEY,		
                CAST(CASE WHEN PLTARGET   IN ('null','') THEN null ELSE PLTARGET   END AS int) AS TRGT_KEY,	
                CAST(CASE WHEN PLSUBASSET IN ('null','') THEN null ELSE PLSUBASSET END AS int) AS SUB_ASST_KEY,
                CAST(CASE WHEN plofficer  IN ('null','') THEN null ELSE plofficer  END AS int) AS OFCR_KEY,
                CASE WHEN PLTIME  in( 'null', '') then NULL else PLTIME END TENR,
                    from_unixtime(unix_timestamp(datelastupdate, 'yyyyMMdd')) as  prcsng_dttm,
                case when context_operation ='WRITE' then 'Active' ELSE 'Deleted' end TEC_STS, 
            
                ROW_NUMBER () OVER(PARTITION BY K_ENTITYID,Case when context_cobdate in('' ,'null') OR context_cobdate is null then context_bankingdate  else context_cobdate end  ORDER BY k_processingtime DESC,insert_date desc) RNK
            
                FROM stg_t24.fodb_consolidate_prft_loss
                WHERE from_unixtime(unix_timestamp(case when context_cobdate in ('','null') OR context_cobdate IS NULL then context_bankingdate else context_cobdate end ,'yyyyMMdd'),'yyyy-MM-dd') 
                    between  '${strt_dt}'  and  '${end_dt}'  
            )A
            WHERE RNK = 1
            )PL
            ON  BASE.Calendar_dt BETWEEN PL.STRT_DT AND PL.END_DT
            
            
            LEFT JOIN 
            (
                SELECT 
                *
                ,COALESCE(
                        DATE_ADD(
                                LEAD(strt_dt) OVER (PARTITION BY CONSL_KEY,CCY_KEY ORDER BY strt_dt),-1  ),DATE '2999-12-31'
                        ) AS End_Dt
                FROM 
                (
                    SELECT
                    K_ENTITYID AS CONSL_KEY,
                    CURRENCY AS CCY_KEY,
                    CAST(CASE WHEN BALANCE IN ('','null') OR BALANCE IS NULL THEN '0.00' ELSE BALANCE END AS DECIMAL(18,2)) AS LCL_BAL,
                    CAST(CASE WHEN DEBITMOVEMENT IN ('','null') OR DEBITMOVEMENT IS NULL THEN '0.00' ELSE DEBITMOVEMENT END AS DECIMAL(18,2)) AS LCL_DBT_MVT,
                    CAST(CASE WHEN CREDITMOVEMENT IN ('','null')OR CREDITMOVEMENT IS NULL THEN '0.00' ELSE CREDITMOVEMENT END AS DECIMAL(18,2)) AS LCL_CRD_MVT,
                    CAST(CASE WHEN CCYBALANCE IN ('','null') OR CCYBALANCE IS NULL THEN '0.00' ELSE CCYBALANCE END AS DECIMAL(18,2)) AS FCY_BAL,
                    CAST(CASE WHEN CCYDEBITMVE IN ('','null') OR CCYDEBITMVE IS NULL THEN '0.00' ELSE CCYDEBITMVE END AS DECIMAL(18,2)) AS FCY_DBT_MVT,
                    CAST(CASE WHEN CCYCREDTMVE IN ('','null')OR CCYCREDTMVE IS NULL THEN '0.00' ELSE CCYCREDTMVE END AS DECIMAL(18,2)) AS FCY_CRD_MVT,
                    CAST(CASE WHEN BALANCEYTD IN ('','null') OR BALANCEYTD IS NULL THEN '0.00' ELSE BALANCEYTD END AS DECIMAL(18,2)) AS LCL_BAL_YTD,
                    CAST(CASE WHEN CCYBALANCEYTD IN ('','null')OR CCYBALANCEYTD IS NULL THEN '0.00' ELSE CCYBALANCEYTD END AS DECIMAL(18,2)) AS FCY_BAL_YTD,
                    from_unixtime(unix_timestamp(case when context_cobdate in ('','null') OR context_cobdate IS NULL then context_bankingdate else context_cobdate end ,'yyyyMMdd'),'yyyy-MM-dd') STRT_DT,
                    ROW_NUMBER() OVER(PARTITION BY K_ENTITYID,CURRENCY, CASE WHEN context_cobdate IN( 'null','') OR  context_cobdate IS NULL then context_bankingdate else context_cobdate END  ORDER BY k_processingtime DESC,insert_date desc) RNK
                    
            
                    FROM stg_t24.fodb_consolidate_prft_loss_currency 
                    WHERE from_unixtime(unix_timestamp(case when context_cobdate in ('','null') OR context_cobdate IS NULL then context_bankingdate else context_cobdate end ,'yyyyMMdd'),'yyyy-MM-dd') 
                        between  '${strt_dt}'  and  '${end_dt}'
                )PL_CCY
                WHERE RNK = 1
            )PL_BAL 
            ON PL_BAL.CONSL_KEY = PL.CONSL_KEY 
            AND BASE.Calendar_dt BETWEEN PL_BAL.STRT_DT AND PL_BAL.END_DT
            AND PL.TEC_STS = 'Active'
            
            LEFT JOIN 
            (
            SELECT 
            *
            ,COALESCE(
                        DATE_ADD(
                                LEAD(strt_dt) OVER (PARTITION BY CONSL_KEY,CCY_KEY ORDER BY strt_dt),-1  ),DATE '2999-12-31'
                        ) AS End_Dt
                FROM
                (
                SELECT 
                K_ENTITYID AS CONSL_KEY,
                CURRENCY AS CCY_KEY,
                from_unixtime(unix_timestamp(case when context_cobdate in ('','null') OR context_cobdate IS NULL then context_bankingdate else context_cobdate end ,'yyyyMMdd'),'yyyy-MM-dd') AS STRT_DT,
                ROW_NUMBER() OVER(PARTITION BY K_ENTITYID,CURRENCY, CASE WHEN context_cobdate IN( 'null','') OR  context_cobdate IS NULL then context_bankingdate else context_cobdate END  ORDER BY k_processingtime DESC,insert_date desc) RNK
                    
                FROM stg_t24.fodb_consolidate_prft_loss_currency 
                WHERE from_unixtime(unix_timestamp(case when context_cobdate in ('','null') OR context_cobdate IS NULL then context_bankingdate else context_cobdate end ,'yyyyMMdd'),'yyyy-MM-dd') 
                        between  '${strt_dt}'  and  '${end_dt}'
            )A
            WHERE RNK = 1
            )PL_DLTD
            ON PL_DLTD.CONSL_KEY = PL.CONSL_KEY 
            AND BASE.Calendar_dt BETWEEN PL_DLTD.STRT_DT AND PL_DLTD.END_DT
            AND PL.TEC_STS = 'Deleted'
        ) BUS_QRY
    ) HASH_PREP
) FINAL WHERE FK_UP <> 1
