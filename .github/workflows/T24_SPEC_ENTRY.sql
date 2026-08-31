SELECT COUNT(*) FROM (
    SELECT hash_prep.*,
        CASE WHEN HASH_PREP.HASH_KEY = FIRST_VALUE(HASH_PREP.HASH_KEY) OVER(
            PARTITION BY HASH_PREP.SPEC_key ORDER BY HASH_PREP.strt_dt ASC
            ROWS BETWEEN 1 PRECEDING AND 1 PRECEDING)
        THEN 1 ELSE 0 END AS FK_UP
    FROM (
        SELECT BUS_QRY.*,
            sha2(
coalesce(ACCT_KEY, '') ||
coalesce(CUST_KEY, '') ||
coalesce(asst_typ, '') ||
coalesce(PROD_CATEG, '') ||
coalesce(CURY_KEY, '') ||
coalesce(TRX_AMT_FCY, '') ||
coalesce(TRX_AMT_LCY, '') ||
coalesce(TRX_REF, '') ||
coalesce(TRX_CD, '') ||
coalesce(ACCT_OFFCR, '') ||
coalesce(AUTH, '') ||
coalesce(INPTR, '')
            , 256) AS HASH_KEY
        FROM (
            
            Select 
            SPEC_key,
            VAL_DT,
            ACCT_KEY,
            CUST_KEY,
            asst_typ,
            PROD_CATEG,
            CURY_KEY,
            TRX_AMT_FCY,
            TRX_AMT_LCY,
            TRX_REF,
            TRX_CD,
            ACCT_OFFCR,
            AUTH,
            INPTR,
            BOOKING_DT,
            EXPSUR_DT, 
            PRCSING_DT,
            current_timestamp As tec_insrt_dttm,
            current_timestamp AS tec_upd_dttm,
            null as dr_dttm,
            null as dr_flg,
            insert_date
            
            From
            (
            	Select * 
            	From 
            	(
            		Select 
            		k_entityid AS SPEC_key,
            		cast(regexp_replace( valuedate,'(\\d{4})(\\d{2})(\\d{2})','$1-$2-$3') AS date) AS  VAL_DT,
            		 case when dealnumber  in('','null')  then null  else dealnumber end as  ACCT_KEY,
            	        case when customerid  in('','null')  then null  else customerid end as CUST_KEY,
            		split(consolkeytype, '\\.')[size(split(consolkeytype, '\\.')) - 1] as asst_typ,
            		case when productcategory  in('','null')  then null  else productcategory end as PROD_CATEG,
            		currency CURY_KEY,
            		cast(case when amountfcy  in ('','null') then '0.00' when amountfcy  is null then '0.00' else amountfcy end as decimal(24,2)) as TRX_AMT_FCY,
            		cast(case when amountlcy  in ('','null') then '0.00' when amountlcy  is null then '0.00' else amountlcy end as decimal(24,2)) as TRX_AMT_LCY,
            		case when transreference  in('','null')  then null  else transreference end as TRX_REF,
            		case when transactioncode in('','null') then null else transactioncode end as TRX_CD,
            		case when accountofficer  in('','null')  then null  else accountofficer end as ACCT_OFFCR,
            		case when authoriser  in('','null')  then null  else authoriser end as AUTH,
            		cast(regexp_replace( bookingdate,'(\\d{4})(\\d{2})(\\d{2})','$1-$2-$3') as date) BOOKING_DT,
            		cast(regexp_replace( EXPOSUREDATE ,'(\\d{4})(\\d{2})(\\d{2})','$1-$2-$3') as date) AS EXPSUR_DT, 
            		cast(from_unixtime(cast(CAST(k_processingtime AS BIGINT) / 1000 AS int), "yyyy-MM-dd HH:mm:ss")AS timestamp) AS PRCSING_DT,
            		insert_date ,
            		row_number() over (partition by K_ENTITYID order by k_processingtime desc) rnk
            
            
            		FROM stg_t24.FODB_RE_CONSOL_SPEC_ENTRY 
            		
            		
                    Where from_unixtime(unix_timestamp(CASE When context_cobdate in ('','null') Then context_bankingdate When context_cobdate is null Then context_bankingdate ELSE context_cobdate End ,'yyyyMMdd'),'yyyy-MM-dd') between '${strt_dt}' and '${end_dt}'
            	 
            	)CONSOL_SPEC_ENTRY
            	
                WHERE RNK = 1
            )SPEC_ENTRY
            
            
            LEFT JOIN 
            (
            
                SELECT * 
            	FROM 
            	(   
            		SELECT k_entityid
            	    ,INPUTTER as INPTR
            	    ,row_number() over (partition by K_ENTITYID order by k_processingtime desc) rnk
            		
            		FROM stg_t24.FODB_RE_CONSOL_SPEC_ENTRY_INPUTTER 
            	)SPEC_INPUTTER
            	WHERE RNK = 1
            
            )ENTRY_INPTR
            ON ENTRY_INPTR.K_ENTITYID = SPEC_ENTRY.SPEC_KEY
        ) BUS_QRY
    ) HASH_PREP
) FINAL WHERE FK_UP <> 1
