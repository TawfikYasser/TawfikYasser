SELECT COUNT(*) FROM (
    SELECT hash_prep.*,
        CASE WHEN HASH_PREP.HASH_KEY = FIRST_VALUE(HASH_PREP.HASH_KEY) OVER(
            PARTITION BY HASH_PREP.Collateral_Number ORDER BY HASH_PREP.strt_dt ASC
            ROWS BETWEEN 1 PRECEDING AND 1 PRECEDING)
        THEN 1 ELSE 0 END AS FK_UP
    FROM (
        SELECT BUS_QRY.*,
            sha2(
coalesce(Customer_Number, '') ||
coalesce(currency, '') ||
coalesce(status, '') ||
coalesce(collateral_code, '') ||
coalesce(country_CD, '') ||
coalesce(Nominal_Value, '') ||
coalesce(Maximum_Value, '') ||
coalesce(Execution_Value, '') ||
coalesce(authoriser, '') ||
coalesce(auditdatetime, '') ||
coalesce(Collateral_Account, '') ||
coalesce(Deposit_App_ID, '')
            , 256) AS HASH_KEY
        FROM (
            select stg.* ,mod.HASH_KEY as old_hash_key,null as end_dt ,
               CURRENT_DATE   AS  START_DT
            ,CURRENT_TIMESTAMP                          AS  Tec_Insrt_Dttm
            		   ,CURRENT_TIMESTAMP                          AS  Tec_Upd_Dttm
            		   ,null                          AS  DR_Dttm
            		   ,null                          AS  DR_Flg
            		   
            
            from
            ( 
            SELECT 
            A.*
            ,sha2(coalesce(Collateral_Number,'')||coalesce(Customer_Number,'')||coalesce(status,'')
            ||coalesce(collateral_code,'')||COALESCE (country_CD,'')||COALESCE (authoriser,'')||COALESCE (Maximum_Value,'')||COALESCE (Deposit_App_ID,''), 256) HASH_KEY 
            From (SELECT 
            Collateral_Number,
            Customer_Number,
            currency,
            status,
            collateral_code,
            country AS country_CD,
            Nominal_Value,
            Maximum_Value,
            Execution_Value,
            value_date,
            Expiry_date,
            authoriser,
            auditdatetime,
            Collateral_Account,
            Deposit_App_ID
            FROM
            (
            select k_entityid  as Collateral_Number,
            customerid as Customer_Number,
            currency ,
            status ,
            collateralcode as collateral_code, 
            country ,
            cast(case when nominalvalue  IN ('','null') THEN '0.00'  else nominalvalue  end  AS DECIMAL(18,3)) Nominal_Value,
            cast(case when  maximumvalue IN ('','null') THEN '0.00'  else maximumvalue end  AS DECIMAL(18,3)) Maximum_Value,
            cast(case when  executionvalue IN ('','null') THEN '0.00'  else executionvalue end AS DECIMAL(18,3))Execution_Value,
            cast(regexp_replace(valuedate,  '(\\d{4})(\\d{2})(\\d{2})' ,  '$1-\$2\-\$3') as date)  as value_date,
            cast(regexp_replace(expirydate,  '(\\d{4})(\\d{2})(\\d{2})' ,  '$\1-\$2\-\$3') as date) as  Expiry_date,
            authoriser ,
            auditdatetime ,
            collataccount Collateral_Account,
            applicationid as Deposit_App_ID,
            cast(regexp_replace(case when  context_cobdate IN ('','null',NULL) then  context_bankingdate else context_cobdate end, '(\\d{4})(\\d{2})(\\d{2})' ,  '$1-\$2\-\$3') as date) context_cobdate,
              ROW_NUMBER() over (partition by k_entityid order by k_processingtime desc , insert_date desc ) R
            From ${stg_schema}.fodb_collateral 
            )D
            WHERE R=1
            ) A 
            ) as stg
            LEFT JOIN dwh_base.T24_COLLATERAL_BASE  mod
            on  stg.hash_key  =mod.hash_key  and stg.Collateral_Number = mod.Collateral_Number
            AND MOD.end_dt is  null  
            where  mod.Collateral_Number is  null
            
             
            
            union 
            
            
            select stg.* ,mod.HASH_KEY as old_hash_key,null as end_dt,
               CURRENT_DATE   AS  START_DT
               ,CURRENT_TIMESTAMP                          AS  Tec_Insrt_Dttm
            		   ,CURRENT_TIMESTAMP                          AS  Tec_Upd_Dttm
            		   ,null                          AS  DR_Dttm
            		   ,null                          AS  DR_Flg
            		   
            from
            ( 
            SELECT 
            A.*
            ,sha2(coalesce(Collateral_Number,'')||coalesce(Customer_Number,'')||coalesce(status,'')
            ||coalesce(collateral_code,'')||COALESCE (country_CD,'')||COALESCE (authoriser,'')||COALESCE (Maximum_Value,'')||COALESCE (Deposit_App_ID,''), 256) HASH_KEY
            from (SELECT 
            Collateral_Number,
            Customer_Number,
            currency,
            status,
            collateral_code,
            country AS country_CD,
            Nominal_Value,
            Maximum_Value,
            Execution_Value,
            value_date,
            Expiry_date,
            authoriser,
            auditdatetime,
            Collateral_Account,
            Deposit_App_ID
            FROM
            (
            select k_entityid  as Collateral_Number,
            customerid as Customer_Number,
            currency ,
            status ,
            collateralcode as collateral_code, 
            country ,
            cast(case when nominalvalue  IN ('','null') THEN '0.00'  else nominalvalue  end  AS DECIMAL(18,3)) Nominal_Value,
            cast(case when  maximumvalue IN ('','null') THEN '0.00'  else maximumvalue end  AS DECIMAL(18,3)) Maximum_Value,
            cast(case when  executionvalue IN ('','null') THEN '0.00'  else executionvalue end AS DECIMAL(18,3))Execution_Value,
            cast(regexp_replace(valuedate,   '(\\d{4})(\\d{2})(\\d{2})' ,  '$1-\$2\-\$3') as date)  as value_date,
            cast(regexp_replace(expirydate,   '(\\d{4})(\\d{2})(\\d{2})' ,  '$1-\$2\-\$3') as date) as  Expiry_date,
            authoriser ,
            auditdatetime ,
            collataccount Collateral_Account,
            applicationid as Deposit_App_ID,
            cast(regexp_replace(case when  context_cobdate IN ('','null',NULL) then  context_bankingdate else context_cobdate end, '(\\d{4})(\\d{2})(\\d{2})' ,  '$1-\$2\-\$3') as date) context_cobdate,
              ROW_NUMBER() over (partition by k_entityid order by k_processingtime desc , insert_date desc ) R
            From ${stg_schema}.fodb_collateral 
            )D
            WHERE R=1
            ) A  
            ) as stg
            right JOIN dwh_base.T24_COLLATERAL_BASE  mod
            on  stg.hash_key  =mod.hash_key  and stg.Collateral_Number = mod.Collateral_Number
            AND MOD.end_dt is  null  
            where  stg.Collateral_Number  is  null
        ) BUS_QRY
    ) HASH_PREP
) FINAL WHERE FK_UP <> 1
