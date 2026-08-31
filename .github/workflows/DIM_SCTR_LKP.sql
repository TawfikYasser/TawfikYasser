SELECT COUNT(*) FROM (
    SELECT hash_prep.*,
        CASE WHEN HASH_PREP.HASH_KEY = FIRST_VALUE(HASH_PREP.HASH_KEY) OVER(
            PARTITION BY HASH_PREP.SCTR_KEY ORDER BY HASH_PREP.strt_dt ASC
            ROWS BETWEEN 1 PRECEDING AND 1 PRECEDING)
        THEN 1 ELSE 0 END AS FK_UP
    FROM (
        SELECT BUS_QRY.*,
            sha2(
coalesce(SCTR_DESCR, '') ||
coalesce(SHRT_DESCR, '') ||
coalesce(RSK_EXP_TYP, '') ||
coalesce(AUTHRZR, '') ||
coalesce(INPTR, '')
            , 256) AS HASH_KEY
        FROM (
            Select 
            SCTR.k_entityid    AS SCTR_KEY
            ,DESCRIPTION       AS SCTR_DESCR
            ,shortname         AS SHRT_DESCR
            ,SCTR.riskexpotype AS RSK_EXP_TYP
            ,SCTR.authoriser   AS AUTHRZR
            ,Inputter          AS INPTR
            ,CALENDAR_DT AS STRT_DT
             
            
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
            			SELECT
            			k_entityid,
            		    from_unixtime(unix_timestamp(CASE When context_cobdate in ('','null') or context_cobdate is Null Then context_bankingdate ELSE context_cobdate End ,'yyyyMMdd'),'yyyy-MM-dd') COB_Dt,
            			riskexpotype,
            			authoriser, 
            			Row_Number() OVER (PARTITION BY k_entityid, CASE When context_cobdate in ('','null') or context_cobdate is Null Then context_bankingdate ELSE context_cobdate End ORDER BY k_processingtime DESC) rnk
            			
            			FROM ${stg_schema}.fodb_sector
            		)FODB_SCTR
            		WHERE RNK = 1
            )SCTR
            ON BASE.CALENDAR_DT BETWEEN SCTR.STRT_DT  AND SCTR.END_DT
             
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
                    description ,		
            		Row_Number() over (PARTITION by k_entityid,CASE When context_cobdate in ('','null') OR context_cobdate Is Null Then context_bankingdate ELSE context_cobdate End order by k_processingtime desc ) rnk
             
            		From ${stg_schema}.fodb_sector_description
            		where rec_index = '0'
                )SCTR_DESCR
            	WHERE Rnk = 1
            )SCTR_DESCR 
            ON SCTR_DESCR.k_entityid = SCTR.k_entityid
            AND BASE.CALENDAR_DT BETWEEN SCTR_DESCR.STRT_DT AND SCTR_DESCR.END_DT
             
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
                    shortname ,		
            		Row_Number() over (PARTITION by k_entityid,CASE When context_cobdate in ('','null') OR context_cobdate Is Null Then context_bankingdate ELSE context_cobdate End order by k_processingtime desc ) rnk
             
            		From ${stg_schema}.fodb_sector_shortname
            		Where rec_index = '0'
                )SCTR_SHRTNAME
            	WHERE Rnk = 1
            )SCTR_SHRTNAME 
            ON SCTR_SHRTNAME.k_entityid = SCTR.k_entityid
            AND BASE.CALENDAR_DT BETWEEN SCTR_SHRTNAME.STRT_DT AND SCTR_SHRTNAME.END_DT
            
            
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
                    Inputter ,		
            		Row_Number() over (PARTITION by k_entityid,CASE When context_cobdate in ('','null') OR context_cobdate Is Null Then context_bankingdate ELSE context_cobdate End order by k_processingtime desc ) rnk
             
            		From ${stg_schema}.fodb_sector_inputter
            		Where rec_index = '0'
                )SCTR_INPTR
            	WHERE Rnk = 1
            )SCTR_INPTR 
            ON SCTR_INPTR.k_entityid = SCTR.k_entityid
            AND BASE.CALENDAR_DT BETWEEN SCTR_INPTR.STRT_DT AND SCTR_INPTR.END_DT
        ) BUS_QRY
    ) HASH_PREP
) FINAL WHERE FK_UP <> 1
