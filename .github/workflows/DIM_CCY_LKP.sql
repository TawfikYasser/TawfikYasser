SELECT COUNT(*) FROM (
    SELECT hash_prep.*,
        CASE WHEN HASH_PREP.HASH_KEY = FIRST_VALUE(HASH_PREP.HASH_KEY) OVER(
            PARTITION BY HASH_PREP.CCY_KEY, HASH_PREP.CCY_MRKT_KEY ORDER BY HASH_PREP.strt_dt ASC
            ROWS BETWEEN 1 PRECEDING AND 1 PRECEDING)
        THEN 1 ELSE 0 END AS FK_UP
    FROM (
        SELECT BUS_QRY.*,
            sha2(
coalesce(CCY_CD, '') ||
coalesce(CCY_NM, '') ||
coalesce(CTRY, '') ||
coalesce(CCY_MRKT_DESCR, '') ||
coalesce(MID_REVL_RT, '') ||
coalesce(REVL_RT, '') ||
coalesce(DFLT_SPRD, '') ||
coalesce(BUY_RT, '') ||
coalesce(SELL_RT, '') ||
coalesce(INPTR, '') ||
coalesce(AUTHRZR, '')
            , 256) AS HASH_KEY
        FROM (
             SELECT
             CCY.numericccycode       CCY_KEY
            ,Calendar_dt              STRT_DT
            ,CCY.k_entityid           CCY_CD
            ,CCY_NAME.ccyname         CCY_NM
            ,CCY.countrycode          CTRY
            ,CCY_MRKT.currencymarket  CCY_MRKT_KEY
            ,CASE
              WHEN CCY_MRKT.currencymarket = '1'  THEN 'Currency Market'
              WHEN CCY_MRKT.currencymarket = '10' THEN 'Cash'
              WHEN CCY_MRKT.currencymarket = '11' THEN 'Transfer'
              WHEN CCY_MRKT.currencymarket = '12' THEN 'Staff'
            END                      CCY_MRKT_DESCR
            ,CCY_MRKT.midrevalrate   MID_REVL_RT
            ,CCY_MRKT.revalrate      REVL_RT
            ,CCY_MRKT.defaultspread  DFLT_SPRD
            ,CCY_MRKT.buyrate        BUY_RT
            ,CCY_MRKT.sellrate       SELL_RT
            ,CCY_INPTR.inputter      INPTR
            ,CCY.authoriser          AUTHRZR
            
            
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
            			numericccycode,
                        countrycode,
            			authoriser,
            			Row_Number() OVER (PARTITION BY k_entityid, CASE When context_cobdate in ('','null') or context_cobdate is Null Then context_bankingdate ELSE context_cobdate End ORDER BY k_processingtime DESC) rnk
            			
            			FROM ${stg_schema}.fodb_currency 
            		)FODB_CURRENCY
            		WHERE RNK = 1
            )CCY
            ON BASE.CALENDAR_DT BETWEEN CCY.STRT_DT  AND CCY.END_DT
             
            LEFT JOIN
            (
            	SELECT 
            	*,
            	COB_DT AS STRT_DT,
            	coalesce(DATE_ADD(LEAD(COB_DT,1)  Over(PARTITION BY k_entityid,currencymarket ORDER BY COB_DT),-1), '2999-12-31') AS END_DT
             
            	FROM 
            	(
            		SELECT
            		k_entityid,
            		from_unixtime(unix_timestamp(CASE When context_cobdate in ('','null') OR context_cobdate Is Null Then context_bankingdate ELSE context_cobdate End ,'yyyyMMdd'),'yyyy-MM-dd') COB_Dt,	
            	 	currencymarket,
            		Cast(CASE WHEN TRIM(midrevalrate) IN('','null') OR midrevalrate IS NULL THEN '1.00' ELSE midrevalrate END  AS DECIMAL(8,4)) AS midrevalrate,
            		Cast(CASE WHEN TRIM(revalrate) IN('','null')  OR revalrate IS NULL THEN '1.00' ELSE revalrate END AS DECIMAL(8,4)) AS revalrate,
            		CASE WHEN defaultspread IN('','null') OR defaultspread IS NULL THEN '1.00' ELSE cast(defaultspread AS DECIMAL(8,4)) END defaultspread,
            		Cast(CASE WHEN TRIM(buyrate) IN('','null') OR buyrate IS NULL THEN '1.00' ELSE buyrate END  AS DECIMAL(8,4)) AS buyrate,
            		Cast(CASE WHEN TRIM(sellrate) IN('','null') OR sellrate IS NULL THEN '1.00' ELSE sellrate END  AS DECIMAL(8,4)) AS sellrate,
            		Row_Number() over (PARTITION by k_entityid,currencymarket,CASE When context_cobdate in ('','null') OR context_cobdate Is Null Then context_bankingdate ELSE context_cobdate End order by k_processingtime desc ) rnk
             
            		From ${stg_schema}.fodb_currency_currencymarket
                )Currency_Market
            	WHERE Rnk = 1
            )CCY_MRKT 
            ON CCY_MRKT.k_entityid = CCY.k_entityid
            AND BASE.CALENDAR_DT BETWEEN CCY_MRKT.STRT_DT AND CCY_MRKT.END_DT
             
             
            LEFT JOIN
            (
                SELECT 
            	k_entityid,
            	COB_DT AS STRT_DT,
            	coalesce(DATE_ADD(LEAD(COB_DT,1)  Over(PARTITION BY k_entityid ORDER BY COB_DT),-1), '2999-12-31') AS END_DT,
            	ccyname
            	FROM 
            	(
            		SELECT
            		k_entityid,
            		ccyname, 
            		from_unixtime(unix_timestamp(CASE When context_cobdate in ('','null') OR context_cobdate Is Null Then context_bankingdate ELSE context_cobdate End ,'yyyyMMdd'),'yyyy-MM-dd') COB_Dt,	
            	 	Row_Number() OVER (PARTITION BY k_entityid,CASE When context_cobdate in ('','null') OR context_cobdate Is Null Then context_bankingdate ELSE context_cobdate End ORDER BY k_processingtime DESC) rnk	 
            		from ${stg_schema}.fodb_currency_ccyname 
                	WHERE REC_INDEX = '0'
             
                )currency_ccyname 
            	WHERE Rnk = 1
             
            )CCY_NAME
            ON CCY_NAME.k_entityid = CCY.k_entityid
            AND BASE.CALENDAR_DT BETWEEN CCY_NAME.STRT_DT AND CCY_NAME.END_DT
            
            LEFT JOIN
            (
                SELECT 
            	k_entityid,
            	COB_DT AS STRT_DT,
            	coalesce(DATE_ADD(LEAD(COB_DT,1)  Over(PARTITION BY k_entityid ORDER BY COB_DT),-1), '2999-12-31') AS END_DT,
            	inputter
            	FROM 
            	(
            		SELECT
            		k_entityid,
            		inputter, 
            		from_unixtime(unix_timestamp(CASE When context_cobdate in ('','null') OR context_cobdate Is Null Then context_bankingdate ELSE context_cobdate End ,'yyyyMMdd'),'yyyy-MM-dd') COB_Dt,	
            	 	Row_Number() OVER (PARTITION BY k_entityid,CASE When context_cobdate in ('','null') OR context_cobdate Is Null Then context_bankingdate ELSE context_cobdate End ORDER BY k_processingtime DESC) rnk	 
            		
            		From ${stg_schema}.fodb_currency_inputter 
            		WHERE rec_index  = '0'
             
                )currency_inputter 
            	WHERE Rnk = 1
             
            )CCY_INPTR 
            ON  CCY_INPTR.k_entityid = CCY.k_entityid 
            AND BASE.CALENDAR_DT BETWEEN CCY_INPTR.STRT_DT AND CCY_INPTR.END_DT
        ) BUS_QRY
    ) HASH_PREP
) FINAL WHERE FK_UP <> 1
