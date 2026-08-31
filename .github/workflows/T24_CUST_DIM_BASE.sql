SELECT COUNT(*) FROM (
    SELECT hash_prep.*,
        CASE WHEN HASH_PREP.HASH_KEY = FIRST_VALUE(HASH_PREP.HASH_KEY) OVER(
            PARTITION BY HASH_PREP.Cif ORDER BY HASH_PREP.strt_dt ASC
            ROWS BETWEEN 1 PRECEDING AND 1 PRECEDING)
        THEN 1 ELSE 0 END AS FK_UP
    FROM (
        SELECT BUS_QRY.*,
            sha2(
coalesce(Cust_Name, '') ||
coalesce(calcriskclass, '') ||
coalesce(segment, '') ||
coalesce(Sector, '') ||
coalesce(Industry, '') ||
coalesce(accountofficer, '') ||
coalesce(nationality, '') ||
coalesce(residence, '') ||
coalesce(cust_status_code, '') ||
coalesce(Lang_Code, '') ||
coalesce(Comp_Code, '') ||
coalesce(Dept_Code, '') ||
coalesce(Drmncy_Sts, '')
            , 256) AS HASH_KEY
        FROM (
            
            
            SELECT
            
            CUST.k_entityid As Cif, --PK
            
            Calendar_dt AS Strt_dt,
            
            CUST_SHORTNAME.shortname As Cust_Name,
            
            CASE
            
              When trim(CUST.calcriskclass) = '' or CUST.calcriskclass = 'null' THEN Null
            
              ELSE CUST.calcriskclass
            
            End As calcriskclass,
            
            CASE
            
              WHEN trim(CUST.segment) = '' or CUST.segment = 'null' THEN Null
            
              ELSE CUST.segment
            
            End As segment,
            
            CUST.sector As Sector,
            
            CUST.industry As Industry,
            
            CUST.accountofficer,
            
            CUST.nationality ,
            
            CUST.residence ,
            
            CUST.customerstatus As cust_status_code,
            
            CUST.language As Lang_Code,
            
            CUST.cocode As Comp_Code,
            
            CUST.deptcode As Dept_Code,
            
            cast(CASE
            
            WHEN trim(customersince) = '' or customersince ='null' THEN Null
            
            ELSE from_unixtime(unix_timestamp(customersince,'yyyyMMdd'),'yyyy-MM-dd')
            
            End As date) as Opng_Dt,
            
            CASE
            
              WHEN trim(CDM_MONITOR.autodormstatus) = '' or CDM_MONITOR.autodormstatus = 'null' THEN 'ACTIVE'
            
              ELSE CDM_MONITOR.autodormstatus
            
            End AS Drmncy_Sts,
            
            cast(CASE
            
            WHEN trim(lastkycreviewdate) = '' or lastkycreviewdate ='null' THEN Null
            
            ELSE from_unixtime(unix_timestamp(lastkycreviewdate,'yyyyMMdd'),'yyyy-MM-dd')
            
            End As date) As last_kyc_review_date,
            
            cast(CASE
            
            WHEN trim(autonextkycreviewdate) = '' or autonextkycreviewdate ='null' THEN Null
            
            ELSE from_unixtime(unix_timestamp(autonextkycreviewdate,'yyyyMMdd'),'yyyy-MM-dd')
            
            End As date)As auto_next_kyc_review_date
            
            FROM
            
            (	
            
            	SELECT Calendar_dt
            
            	FROM reporting_schema.calendar_base
            
            	WHERE Calendar_dt between '${strt_dt}' and '${end_dt}'
            
            )BASE
            
            INNER JOIN
            
            (
            
                    SELECT
            
            		*,
            
            		COB_DT AS STRT_DT,
            
            		COALESCE(
            
            				   DATE_ADD(
            
            						LEAD(COB_DT) OVER (PARTITION BY k_Entityid ORDER BY COB_DT),-1
            
            					),DATE '2999-12-31'
            
            				) AS End_Dt
            
            		FROM
            
            		(
            
            			SELECT
            
            			k_entityid,
            
            		    from_unixtime(unix_timestamp(CASE When context_cobdate in ('','null') or context_cobdate is null Then context_bankingdate  ELSE context_cobdate End ,'yyyyMMdd'),'yyyy-MM-dd') COB_Dt,
            
            			calcriskclass,
            
            			segment,
            
            			sector,
            
            			industry,
            
            			accountofficer,
            
            			nationality,
            
            			residence,
            
            			customerstatus,
            
            			language,
            
            			cocode,
            
            			deptcode,
            
            			customersince,
            
            			lastkycreviewdate,
            
            			autonextkycreviewdate,
            
            			Row_Number() OVER (PARTITION BY k_entityid,Case WHEN context_cobdate in ('','null')  or context_cobdate is null THEN context_bankingdate ELSE context_cobdate END ORDER BY k_processingtime DESC) rnk
            
            			FROM stg_t24.fodb_customer
            
            		)FODB_CUST
            
            		WHERE RNK = 1
            
            )CUST
            
            ON BASE.CALENDAR_DT BETWEEN CUST.STRT_DT  AND CUST.END_DT
            
            LEFT JOIN
            
            (
            
            	SELECT
            
            	k_entityid,
            
            	COB_DT AS STRT_DT,
            
            	COALESCE(
            
            				DATE_ADD(
            
            						LEAD(COB_DT) OVER (PARTITION BY k_Entityid ORDER BY COB_DT),-1
            
            					),DATE '2999-12-31'
            
            				) AS End_Dt
            
            	,shortname
            
            	FROM
            
            	(
            
            		SELECT
            
            		k_entityid,
            
            		CASE WHEN shortname IN ('', NULL) THEN null WHEN shortname is null THEN null ELSE shortname END AS shortname ,
            
            		from_unixtime(unix_timestamp(CASE When context_cobdate in ('','null') or context_cobdate is null Then context_bankingdate ELSE context_cobdate End ,'yyyyMMdd'),'yyyy-MM-dd') COB_Dt,	
            
            	 	Row_Number() OVER (PARTITION BY k_entityid,CASE When context_cobdate in ('','null') or context_cobdate is null Then context_bankingdate ELSE context_cobdate End ORDER BY k_processingtime DESC) rnk	
            
            		FROM stg_t24.fodb_customer_shortname
            
            		Where rec_index = '0'
            
                )Cust_Name
            
            	WHERE Rnk = 1
            
            )CUST_SHORTNAME
            
            ON CUST_SHORTNAME.k_entityid = CUST.k_entityid
            
            AND BASE.CALENDAR_DT BETWEEN CUST_SHORTNAME.STRT_DT AND CUST_SHORTNAME.END_DT
            
            LEFT JOIN
            
            (
            
                SELECT
            
            	k_entityid,
            
            	COB_DT AS STRT_DT,
            
            	COALESCE(
            
            				DATE_ADD(
            
            						LEAD(COB_DT) OVER (PARTITION BY k_Entityid ORDER BY COB_DT),-1
            
            					),DATE '2999-12-31'
            
            				) AS End_Dt,
            
            	AUTODORMSTATUS
            
            	FROM
            
            	(
            
            		SELECT
            
            		k_entityid,
            
            		AUTODORMSTATUS,
            
            		from_unixtime(unix_timestamp(CASE When context_cobdate in ('','null') or context_cobdate is null Then context_bankingdate ELSE context_cobdate End ,'yyyyMMdd'),'yyyy-MM-dd') COB_Dt,	
            
            	 	Row_Number() OVER (PARTITION BY k_entityid,CASE When context_cobdate in ('','null') or context_cobdate is null Then context_bankingdate ELSE context_cobdate End ORDER BY k_processingtime DESC) rnk	
            
            		FROM stg_t24.fodb_st_cdm_monitor
            
                )CDM
            
            	WHERE Rnk = 1
            
            )CDM_MONITOR
            
            ON CDM_MONITOR.k_entityid = CUST.k_entityid
            
            AND BASE.CALENDAR_DT BETWEEN CDM_MONITOR.STRT_DT AND CDM_MONITOR.END_DT
        ) BUS_QRY
    ) HASH_PREP
) FINAL WHERE FK_UP <> 1
