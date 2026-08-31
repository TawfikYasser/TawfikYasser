SELECT COUNT(*) FROM (
    SELECT hash_prep.*,
        CASE WHEN HASH_PREP.HASH_KEY = FIRST_VALUE(HASH_PREP.HASH_KEY) OVER(
            PARTITION BY HASH_PREP.CTGY_KEY ORDER BY HASH_PREP.strt_dt ASC
            ROWS BETWEEN 1 PRECEDING AND 1 PRECEDING)
        THEN 1 ELSE 0 END AS FK_UP
    FROM (
        SELECT BUS_QRY.*,
            sha2(
coalesce(CTGY_DESCR, '') ||
coalesce(CTGY_SHRT_DESCR, '') ||
coalesce(SYS_CD, '') ||
coalesce(MNMONC, '') ||
coalesce(PSTN_TYP, '') ||
coalesce(CHNL_KEY, '') ||
coalesce(DEPT_KEY, '') ||
coalesce(ACCT_CNTGNT, '') ||
coalesce(AUTHRZR, '') ||
coalesce(INPTR, '')
            , 256) AS HASH_KEY
        FROM (
             SELECT
            CTGY.k_entityid          CTGY_KEY,
            Calendar_dt  	         STRT_DT,
            CTGY_DESCR.Description   CTGY_DESCR,
            CTGY_SHORTNAME.shortname CTGY_SHRT_DESCR,
            CTGY.systemind           SYS_CD,
            CTGY.mnemonic            MNMONC,
            CTGY.positiontype        PSTN_TYP,
            CTGY.cocode              CHNL_KEY,
            CTGY.deptcode            DEPT_KEY,
            CTGY.accontingent        ACCT_CNTGNT,
            CTGY.authoriser          AUTHRZR,
            CTGY_INPUTR.inputter	 INPTR
            
            
            
            FROM 
            (	
            	SELECT Calendar_dt
            	
            	FROM reporting_schema.calendar_base
            	WHERE Calendar_dt Between '${strt_dt}' and '${end_dt}'
            )BASE
            
            INNER JOIN
            (
                    SELECT 
            		*,
            		COB_DT AS STRT_DT,
            		Coalesce(date_add(First_value(COB_DT ) over(partition by  k_Entityid  order by COB_DT rows between  1 following  and 1 following),-1),'2999-12-31' ) END_DT
            		FROM 
            		(
            			
            			SELECT k_entityid ,
            			from_unixtime(unix_timestamp(CASE When context_cobdate in ('','null') or context_cobdate is Null Then context_bankingdate ELSE context_cobdate End ,'yyyyMMdd'),'yyyy-MM-dd') COB_Dt,
            			systemind,
            			case when mnemonic in ('','null') then null else mnemonic end as mnemonic,
            	                case when positiontype in ('','null') then null else positiontype end as positiontype,
            			authoriser,
            			cocode,
            			deptcode,
            			accontingent,
            			Row_Number() OVER (PARTITION BY k_entityid, CASE When context_cobdate in ('','null') or context_cobdate is Null Then context_bankingdate ELSE context_cobdate End ORDER BY k_processingtime DESC) rnk
            			
            			from ${stg_schema}.f_category
            		)FODB_CTGY
            		WHERE RNK = 1
            )CTGY
            ON BASE.CALENDAR_DT BETWEEN CTGY.STRT_DT  AND CTGY.END_DT
             
            LEFT JOIN
            (
            	SELECT 
            	*,
            	COB_DT AS STRT_DT,
            	coalesce(DATE_ADD(LEAD(COB_DT,1)  Over(PARTITION BY k_entityid ORDER BY COB_DT),-1), '2999-12-31') AS END_DT
             
            	FROM 
            	(
            		SELECT
            		k_entityid,
            		from_unixtime(unix_timestamp(CASE When context_cobdate in ('','null') OR context_cobdate Is Null Then context_bankingdate ELSE context_cobdate End ,'yyyyMMdd'),'yyyy-MM-dd') COB_Dt,	
                    description,
            		Row_Number() over (PARTITION by k_entityid,CASE When context_cobdate in ('','null') OR context_cobdate Is Null Then context_bankingdate ELSE context_cobdate End order by k_processingtime desc ) rnk
             
            		From ${stg_schema}.f_category_description
            		where rec_index = '0'
                )CTGY_DESCR
            	WHERE Rnk = 1
            )CTGY_DESCR 
            ON CTGY_DESCR.k_entityid = CTGY.k_entityid
            AND BASE.CALENDAR_DT BETWEEN CTGY_DESCR.STRT_DT AND CTGY_DESCR.END_DT
            
            LEFT JOIN
            (
            	SELECT 
            	*,
            	COB_DT AS STRT_DT,
            	coalesce(DATE_ADD(LEAD(COB_DT,1)  Over(PARTITION BY k_entityid ORDER BY COB_DT),-1), '2999-12-31') AS END_DT
             
            	FROM 
            	(
            		SELECT
            		k_entityid,
            		from_unixtime(unix_timestamp(CASE When context_cobdate in ('','null') OR context_cobdate Is Null Then context_bankingdate ELSE context_cobdate End ,'yyyyMMdd'),'yyyy-MM-dd') COB_Dt,	
                    shortname,
            		Row_Number() over (PARTITION by k_entityid,CASE When context_cobdate in ('','null') OR context_cobdate Is Null Then context_bankingdate ELSE context_cobdate End order by k_processingtime desc ) rnk
             
            		From ${stg_schema}.f_category_shortname
            		where rec_index = '0'
                )CTGY_SHORTNAME
            	WHERE Rnk = 1
            )CTGY_SHORTNAME
            ON CTGY_SHORTNAME.k_entityid = CTGY.k_entityid
            AND BASE.CALENDAR_DT BETWEEN CTGY_SHORTNAME.STRT_DT AND CTGY_SHORTNAME.END_DT
            
            
            
            LEFT JOIN
            (
            	SELECT 
            	*,
            	COB_DT AS STRT_DT,
            	coalesce(DATE_ADD(LEAD(COB_DT,1)  Over(PARTITION BY k_entityid ORDER BY COB_DT),-1), '2999-12-31') AS END_DT
             
            	FROM 
            	(
            		SELECT
            		k_entityid,
            		from_unixtime(unix_timestamp(CASE When context_cobdate in ('','null') OR context_cobdate Is Null Then context_bankingdate ELSE context_cobdate End ,'yyyyMMdd'),'yyyy-MM-dd') COB_Dt,	
                    inputter,
            		Row_Number() over (PARTITION by k_entityid,CASE When context_cobdate in ('','null') OR context_cobdate Is Null Then context_bankingdate ELSE context_cobdate End order by k_processingtime desc ) rnk
             
            		From ${stg_schema}.f_category_inputter
            		where rec_index = '0'
                )CTGY_INPUTR
            	WHERE Rnk = 1
            )CTGY_INPUTR
            ON CTGY_INPUTR.k_entityid = CTGY.k_entityid
            AND BASE.CALENDAR_DT BETWEEN CTGY_INPUTR.STRT_DT AND CTGY_INPUTR.END_DT
        ) BUS_QRY
    ) HASH_PREP
) FINAL WHERE FK_UP <> 1
