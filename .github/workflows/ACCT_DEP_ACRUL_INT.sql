SELECT COUNT(*) FROM (
    SELECT hash_prep.*,
        CASE WHEN HASH_PREP.HASH_KEY = FIRST_VALUE(HASH_PREP.HASH_KEY) OVER(
            PARTITION BY HASH_PREP.Arrngmnt_key, HASH_PREP.Int_Typ ORDER BY HASH_PREP.strt_dt ASC
            ROWS BETWEEN 1 PRECEDING AND 1 PRECEDING)
        THEN 1 ELSE 0 END AS FK_UP
    FROM (
        SELECT BUS_QRY.*,
            sha2(
coalesce(Acct_key, '') ||
coalesce(Tot_Acrul_Amt, '') ||
coalesce(Tot_Posted_Acrul_Amt, '') ||
coalesce(Tot_Due_Amt, '') ||
coalesce(Tot_Susp_Amt, '') ||
coalesce(Tot_Rpy_Amt, '') ||
coalesce(Tot_Neg_Acrul_Amt, '')
            , 256) AS HASH_KEY
        FROM (
            
            select stg.*,
            SHA2(COALESCE(Acct_key,'')||COALESCE(Tot_Acrul_Amt,'')||COALESCE(Tot_Posted_Acrul_Amt,'')||COALESCE(Tot_Due_Amt,'')||COALESCE(Tot_Susp_Amt,'')||COALESCE(Tot_Rpy_Amt,'')||COALESCE(Tot_Neg_Acrul_Amt,''), 256)as hashcode
             ,cast(current_timestamp as string) as tec_insrt_dttm		
            	,cast(current_timestamp as string) as tec_upd_dttm		
            	,null as dr_dttm		
            	,null as dr_flg
            
            from(
            	--Business Query 
            	Select
            AA_ACRUL.Arrngmnt_key,
            AA_ACRUL.Int_Typ,
            AA_ACCT.Acct_key,
            AA_ACRUL.Cob_Dt,			
            AA_ACRUL.STRT_DT,
            AA_ACRUL.END_DT,
            AA_ACRUL.Tot_Acrul_Amt,
            AA_ACRUL.Tot_Posted_Acrul_Amt, 
            AA_ACRUL.Tot_Due_Amt, 
            AA_ACRUL.Tot_Susp_Amt, 	
            AA_ACRUL.Tot_Rpy_Amt, 
            AA_ACRUL.Tot_Neg_Acrul_Amt
            
            FROM
                (		
            		SELECT *
            		FROM 
            		(
            			SELECT
            			k_entityid,
            			CAST(rec_index AS INT) AS rec_index,
            			SUBSTRING(k_entityid, 1 , INSTR(k_entityid, '-') -1) Arrngmnt_key,
            			SUBSTRING(k_entityid, 14, INSTR(k_entityid, '-') + 1) Int_Typ,
            			from_unixtime(unix_timestamp(CASE When context_cobdate in ('','null',Null) Then context_bankingdate ELSE context_cobdate End ,'yyyyMMdd'),'yyyy-MM-dd') Cob_Dt,			
            			from_unixtime(unix_timestamp(periodstart,'yyyyMMdd'),'yyyy-MM-dd') AS STRT_DT,
            			from_unixtime(unix_timestamp(periodend,'yyyyMMdd'),'yyyy-MM-dd') AS END_DT ,
            			CAST(CASE WHEN totaccramt IN('','null',NULL) THEN '0.00' ELSE totaccramt END AS DECIMAL(18,3)) As Tot_Acrul_Amt,
            			CAST(CASE WHEN totdueamt  IN('','null',NULL) THEN '0.00' ELSE totdueamt END AS DECIMAL(18,3)) As Tot_Due_Amt, 
            			CAST(CASE WHEN totsuspamt IN('','null',NULL) THEN '0.00' ELSE totsuspamt END AS DECIMAL(18,3)) As Tot_Susp_Amt, 	
            			CAST(CASE WHEN totrpyamt  IN('','null',NULL) THEN '0.00' ELSE totrpyamt END AS DECIMAL(18,3)) As Tot_Rpy_Amt,
            			CAST(CASE WHEN totposaccramt IN('','null',NULL) THEN '0.00' ELSE totposaccramt END AS DECIMAL(18,3)) AS Tot_Posted_Acrul_Amt, 
            			CAST(CASE WHEN totnegaccramt IN('','null',NULL) THEN '0.00' ELSE totnegaccramt END AS DECIMAL(18,3)) Tot_Neg_Acrul_Amt,			
            			ROW_NUMBER () over (Partition by k_entityid, periodstart order by k_processingtime DESC ) AS RNK
            			FROM stg_t24.fodb_aa_interest_accruals_periodstart 
            			WHERE  SUBSTRING(k_entityid, 14, INSTR(k_entityid, '-') + 1) IN ('CRINTEREST','DRINTEREST','DEPOSITINT')
            			and from_unixtime(unix_timestamp(CASE When context_cobdate in ('','null',Null) Then context_bankingdate ELSE context_cobdate End ,'yyyyMMdd'),'yyyy-MM-dd') <= INSERT_DATE
            		)ACRUL_INT
            		WHERE RNK = 1
             
            	)AA_ACRUL
             
             
            	LEFT JOIN
            	(
            			SELECT * 
            			FROM 
            			(
            					SELECT 
            					K_entityid AS Arrngmnt_key,
            					Linkedapplid AS Acct_key,
            					ROW_NUMBER() OVER (PARTITION BY K_entityid ORDER BY K_PROCESSINGTIME Desc) AS Rnk
            					FROM stg_t24.fodb_aa_arrangement_linkedappl	
            			)AA_LNKDACCT
            			WHERE AA_LNKDACCT.Rnk = 1
             
            	)AA_ACCT
            	ON  AA_ACCT.Arrngmnt_key = AA_ACRUL.Arrngmnt_key
             
             
            ) as stg
        ) BUS_QRY
    ) HASH_PREP
) FINAL WHERE FK_UP <> 1
