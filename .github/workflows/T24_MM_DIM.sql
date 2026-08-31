SELECT COUNT(*) FROM (
    SELECT hash_prep.*,
        CASE WHEN HASH_PREP.HASH_KEY = FIRST_VALUE(HASH_PREP.HASH_KEY) OVER(
            PARTITION BY HASH_PREP.MM_KEY ORDER BY HASH_PREP.strt_dt ASC
            ROWS BETWEEN 1 PRECEDING AND 1 PRECEDING)
        THEN 1 ELSE 0 END AS FK_UP
    FROM (
        SELECT BUS_QRY.*,
            sha2(
coalesce(DEAL_KEY, '') ||
coalesce(CUST_KEY, '') ||
coalesce(counterparty_name, '') ||
coalesce(Country_of_Origin, '') ||
coalesce(CURY_KEY, '') ||
coalesce(DEAL_AMT, '') ||
coalesce(CATEG_KEY, '') ||
coalesce(CATEG_DESCR, '') ||
coalesce(INT_RT_TYP, '') ||
coalesce(INT_BASIS, '') ||
coalesce(INT_RT, '') ||
coalesce(INT_KEY, '') ||
coalesce(INT_SPRD, '') ||
coalesce(ACCRL_PARAM, '') ||
coalesce(TOT_INT_AMT, '') ||
coalesce(LIQ_DIF_INT, '') ||
coalesce(BRKR_CD, '') ||
coalesce(BRKR_AGE, '') ||
coalesce(BRKR_CURY, '') ||
coalesce(BRKR_AMT, '') ||
coalesce(DRAW_DOWN_ACCT, '') ||
coalesce(PRIN_LIQ_ACCT, '') ||
coalesce(PRIN_BEN_BNK_1, '') ||
coalesce(PRIN_BEN_BNK_2, '') ||
coalesce(INT_LIQ_ACCT, '') ||
coalesce(INT_BEN_BNK_1, '') ||
coalesce(INT_BEN_BNK_2, '') ||
coalesce(LMT_REF, '') ||
coalesce(CUST_REF, '') ||
coalesce(FED_FUND, '') ||
coalesce(DELVRY_LNK, '') ||
coalesce(CHRG_LIQ_ACCT, '') ||
coalesce(CURY_MRKT, '') ||
coalesce(POSTION_TYP, '') ||
coalesce(NEG_REF_NUM, '') ||
coalesce(INT_REF_NUM, '') ||
coalesce(MIS_INT_KEY, '') ||
coalesce(MIS_INT_RT, '') ||
coalesce(CNTRY_RSK, '') ||
coalesce(CNTRY_EXPSURE, '') ||
coalesce(MIS_ACCT_OFFICER, '') ||
coalesce(FID_COM_RT, '') ||
coalesce(FID_TOT_COM_AMT, '') ||
coalesce(FID_DROWDOWN_ACCT, '') ||
coalesce(FID_PRN_LIQ_ACCT, '') ||
coalesce(FID_PRN_DEN_BNK_1, '') ||
coalesce(FID_PRN_DEN_BNK_2, '') ||
coalesce(PRN_INCRSE, '') ||
coalesce(ROLL_OVR_MRKER, '') ||
coalesce(ROLL_OVR_INT_RT, '') ||
coalesce(NEW_INT_RT, '') ||
coalesce(NEW_INT_SPRD, '') ||
coalesce(CONFIG_BY_CUST, '') ||
coalesce(CONFIG_BY_BRKR, '') ||
coalesce(SWFT_COM_REF, '') ||
coalesce(STS, '') ||
coalesce(TOT_INT_TAX, '') ||
coalesce(INT_CURY, '') ||
coalesce(INT_CURY_MRKT, '') ||
coalesce(AUTO_ROLL_OVR, '') ||
coalesce(AUTO_CAPTLIZE, '') ||
coalesce(AUTH, '') ||
coalesce(COMPANY_CD, '') ||
coalesce(INPTR, '') ||
coalesce(OVERRIDE, '')
            , 256) AS HASH_KEY
        FROM (
            SELECT 
            DISTINCT 
            MM_MRKT.K_entityid        AS MM_KEY
            ,contractno               AS DEAL_KEY 
            ,customerid               AS CUST_KEY
            ,shortname                AS counterparty_name
            ,RESIDENCE                AS Country_of_Origin
            ,currency                 AS CURY_KEY
            ,principal                AS DEAL_AMT 
            ,dealdate                 AS DEAL_DT
            ,valuedate                AS VAL_DT
            ,maturitydate 		      AS MAT_DT
            ,MM_MRKT.category         AS CATEG_KEY
            ,CTGY_LKP.DESCRIPTION     AS CATEG_DESCR
            ,intratetype              AS INT_RT_TYP
            ,interestbasis            AS INT_BASIS
            ,interestrate             AS INT_RT
            ,interestkey              AS INT_KEY
            ,interestspread_d_1       AS INT_SPRD
            ,accrualparam             AS ACCRL_PARAM
            ,totinterestamt           AS TOT_INT_AMT
            ,intduedate               AS INT_DUE_DT
            ,liqdeferinterest         AS LIQ_DIF_INT
            ,brokercode               AS BRKR_CD
            ,brokerage                AS BRKR_AGE
            ,brokerccy                AS BRKR_CURY
            ,brokeramount             AS BRKR_AMT
            ,drawdownaccount          AS DRAW_DOWN_ACCT
            ,prinliqacct              AS PRIN_LIQ_ACCT
            ,prinbenbank_d_1          AS PRIN_BEN_BNK_1
            ,prinbenbank_d_2          AS PRIN_BEN_BNK_2
            ,intliqacct               AS INT_LIQ_ACCT
            ,intbenbank_d_1           AS INT_BEN_BNK_1
            ,intbenbank_d_2           AS INT_BEN_BNK_2
            ,limitreference           AS LMT_REF
            ,customerref              AS CUST_REF
            ,federalfunds             AS FED_FUND
            ,deliverylink             AS DELVRY_LNK
            ,chrgliqacct              AS CHRG_LIQ_ACCT
            ,currencymarket           AS CURY_MRKT
            ,positiontype             AS POSTION_TYP
            ,negrefnumber             AS NEG_REF_NUM
            ,intrefnumber             AS INT_REF_NUM
            ,misinterestkey           AS MIS_INT_KEY
            ,misinterestrate          AS MIS_INT_RT
            ,countryrisk              AS CNTRY_RSK
            ,countryexposure          AS CNTRY_EXPSURE
            ,misacctofficer           AS MIS_ACCT_OFFICER
            ,fidcommrate              AS FID_COM_RT
            ,fidtotcommamnt           AS FID_TOT_COM_AMT
            ,fiddrawdownacct          AS FID_DROWDOWN_ACCT
            ,fidprinliqacct           AS FID_PRN_LIQ_ACCT
            ,fidprinbenbk_d_1         AS FID_PRN_DEN_BNK_1
            ,fidprinbenbk_d_2         AS FID_PRN_DEN_BNK_2
            ,prinincrease             AS PRN_INCRSE
            ,increffdate              AS INC_REF_DT
            ,rollovermarker           AS ROLL_OVR_MRKER
            ,rolloverdate             AS ROLL_OVR_DT
            ,rolloverintrate          AS ROLL_OVR_INT_RT
            ,newinterestrate          AS NEW_INT_RT
            ,newintrstspread          AS NEW_INT_SPRD
            ,confbycust               AS CONFIG_BY_CUST
            ,confbybroker             AS CONFIG_BY_BRKR
            ,swiftcommonref           AS SWFT_COM_REF
            ,status                   AS STS
            ,totinttax                AS TOT_INT_TAX
            ,intccy                   AS INT_CURY
            ,intccymkt                AS INT_CURY_MRKT
            ,chgvaluedate             AS CHG_VL_DT
            ,autorollover             AS AUTO_ROLL_OVR
            ,autocapitalise           AS AUTO_CAPTLIZE
            ,MM_MRKT.authoriser       AS AUTH
            ,MM_MRKT.cocode           AS COMPANY_CD
            ,CONCAT_WS(', ', COLLECT_LIST(MM_INPUTR.INPUTTER))  AS INPTR
            ,CONCAT_WS(', ', COLLECT_LIST(MM_OVRD.OVERRIDE))    AS OVERRIDE
            ,cob_dt AS strt_dt
             
            FROM 
            (
                SELECT * 		
            	FROM  
                (
            		SELECT 
            		K_entityid
            		,CASE WHEN TRIM(contractno) IN('','null') THEN NULL WHEN TRIM(contractno) is null THEN NULL ELSE contractno END AS contractno
            		,CASE WHEN TRIM(customerid) IN('','null') THEN NULL WHEN TRIM(customerid) is null THEN NULL ELSE customerid END AS customerid
            		,CASE WHEN TRIM(currency) IN('','null',null) THEN NULL WHEN TRIM(currency) is null THEN NULL ELSE currency END AS currency
            		,Cast(CASE WHEN TRIM(principal) IN('','null') THEN '0.00' WHEN TRIM(principal) is null THEN '0.00' ELSE principal END  AS DECIMAL(18,4)) AS principal
            		,from_unixtime(unix_timestamp(dealdate,'yyyyMMdd'),'yyyy-MM-dd')  AS dealdate
            		,from_unixtime(unix_timestamp(valuedate,'yyyyMMdd'),'yyyy-MM-dd') AS valuedate
            		,from_unixtime(unix_timestamp(maturitydate,'yyyyMMdd'),'yyyy-MM-dd') AS maturitydate
            		,CASE WHEN TRIM(category) IN('','null') THEN NULL WHEN TRIM(category) is null THEN NULL ELSE category END AS category
            		,intratetype
            		,interestbasis
            		,interestrate
            		,interestkey
            		,interestspread_d_1
            		,accrualparam  
                    ,totinterestamt   
            		,intduedate       
            		,liqdeferinterest 
            		,brokercode       
            		,brokerage        
            		,brokerccy        
            		,brokeramount     
            		,prinliqacct      
            		,prinbenbank_d_1  
            		,prinbenbank_d_2  
            		,intliqacct       
            		,intbenbank_d_1   
            		,intbenbank_d_2   
            		,limitreference   
            		,customerref      
            		,federalfunds     
            		,deliverylink     
            		,chrgliqacct      
            		,currencymarket   
            		,positiontype     
            		,negrefnumber     
            		,intrefnumber
            		,misinterestkey  
            		,misinterestrate 
            		,countryrisk     
            		,countryexposure 
            		,misacctofficer  
            		,fidcommrate     
            		,fidtotcommamnt  
            		,fiddrawdownacct 
            		,fidprinliqacct  
            		,fidprinbenbk_d_1
            		,fidprinbenbk_d_2
            		,prinincrease    
            		,increffdate     
            		,rollovermarker  
            		,rolloverdate    
            		,rolloverintrate 
            		,newinterestrate 
            		,newintrstspread 
            		,confbycust      
            		,confbybroker    
            		,swiftcommonref  
            		,status          
            		,totinttax     
            		,intccy        
            		,intccymkt     
            		,chgvaluedate  
            		,autorollover  
            		,autocapitalise
            		,authoriser    
            		,cocode        
            		,CASE WHEN TRIM(drawdownaccount) IN('','null') THEN NULL WHEN TRIM(drawdownaccount) is null THEN NULL ELSE drawdownaccount END AS drawdownaccount
            		,from_unixtime(unix_timestamp(CASE When context_cobdate in ('','null') Then context_bankingdate When context_cobdate is null Then context_bankingdate ELSE context_cobdate End ,'yyyyMMdd'),'yyyy-MM-dd') cob_dt	
            		,RANK ()OVER(PARTITION BY K_ENTITYID,CASE When context_cobdate in ('','null') Then context_bankingdate When context_cobdate is null Then context_bankingdate ELSE context_cobdate End ORDER BY k_processingtime DESC,INSERT_DATE DESC) RNK
            		
            		FROM stg_t24.FODB_MM_MONEY_MARKET 
            		WHERE CONTEXT_OPERATION = 'WRITE'   
            	)MM_MARKET
            	
            	WHERE RNK = 1
            )MM_MRKT
            
            
            LEFT JOIN DWH_BASE.T24_CATEGORY_LOOKUP CTGY_LKP
            ON  CTGY_LKP.id = MM_MRKT.category
            
            
            LEFT JOIN 
            (
            	SELECT *
            	FROM
                (
            		SELECT  
            		K_ENTITYID
            		,from_unixtime(unix_timestamp(CASE When context_cobdate in ('','null') Then context_bankingdate When context_cobdate is null Then context_bankingdate ELSE context_cobdate End ,'yyyyMMdd'),'yyyy-MM-dd') cob_dt
            		,INPUTTER
            		,RANK ()OVER(PARTITION BY K_ENTITYID,CASE When context_cobdate in ('','null') Then context_bankingdate When context_cobdate is null Then context_bankingdate ELSE context_cobdate End ORDER BY k_processingtime DESC,INSERT_DATE DESC) RNK
            
            		FROM stg_t24.FODB_MM_MONEY_MARKET_INPUTTER 
            				
            	)INPUTR
            	WHERE rnk = 1
            
            )MM_INPUTR
            ON MM_INPUTR.K_ENTITYID = MM_MRKT.K_ENTITYID 
            AND MM_INPUTR.COB_DT = MM_MRKT.COB_DT 
            
            LEFT JOIN 
            (
            	SELECT *
            	FROM
            	(
            		SELECT  
            		K_ENTITYID
            		,from_unixtime(unix_timestamp(CASE When context_cobdate in ('','null') Then context_bankingdate When context_cobdate is null Then context_bankingdate ELSE context_cobdate End ,'yyyyMMdd'),'yyyy-MM-dd') cob_dt
            		,OVERRIDE
            		,RANK ()OVER(PARTITION BY K_ENTITYID,CASE When context_cobdate in ('','null') Then context_bankingdate When context_cobdate is null Then context_bankingdate ELSE context_cobdate End ORDER BY k_processingtime DESC,INSERT_DATE DESC) RNK
            
            		FROM stg_t24.fodb_mm_money_market_override 
            		WHERE REC_INDEX = '0'
            				
            	)OVRD
            	WHERE rnk = 1
            
            )MM_OVRD
            ON MM_OVRD.K_ENTITYID = MM_MRKT.K_ENTITYID 
            AND MM_OVRD.COB_DT = MM_MRKT.COB_DT 
             
             
            LEFT JOIN 
            (
            	SELECT *
            	FROM
            	(
            		SELECT  
            		K_ENTITYID
            		,shortname
            		,RANK ()OVER(PARTITION BY K_ENTITYID ORDER BY k_processingtime DESC) RNK
            
            		FROM stg_t24.fodb_customer_shortname 
            				
            	)SHORTNAME
            	WHERE rnk = 1
            
            )CUST_SHRTNAME
            ON CUST_SHRTNAME.K_ENTITYID = MM_MRKT.customerid 
            
             
            LEFT JOIN 
            (
            	SELECT *
            	FROM
            	(
            		SELECT  
            		K_ENTITYID
            		,RESIDENCE
            		,RANK ()OVER(PARTITION BY K_ENTITYID ORDER BY k_processingtime DESC) RNK
            
            		FROM stg_t24.fodb_customer
            				
            	)FODB_CUST
            	WHERE rnk = 1
            
            )CUST
            ON CUST.K_ENTITYID = CUST_SHRTNAME.K_ENTITYID 	
            
            GROUP BY   
            MM_MRKT.K_entityid 
            ,MM_MRKT.cob_dt       
            ,contractno   
            ,customerid  
            ,shortname                       
            ,RESIDENCE
            ,currency  
            ,principal    
            ,dealdate
            ,valuedate
            ,maturitydate
            ,MM_MRKT.category                  
            ,CTGY_LKP.DESCRIPTION               
            ,intratetype                 
            ,interestbasis               
            ,interestrate                
            ,interestkey                 
            ,interestspread_d_1          
            ,accrualparam                
            ,totinterestamt              
            ,intduedate                  
            ,liqdeferinterest            
            ,brokercode                  
            ,brokerage                   
            ,brokerccy                   
            ,brokeramount                
            ,drawdownaccount             
            ,prinliqacct                 
            ,prinbenbank_d_1             
            ,prinbenbank_d_2             
            ,intliqacct                  
            ,intbenbank_d_1              
            ,intbenbank_d_2              
            ,limitreference              
            ,customerref                 
            ,federalfunds                
            ,deliverylink                
            ,chrgliqacct                 
            ,currencymarket              
            ,positiontype                
            ,negrefnumber                
            ,intrefnumber                
            ,misinterestkey              
            ,misinterestrate             
            ,countryrisk                 
            ,countryexposure             
            ,misacctofficer              
            ,fidcommrate                 
            ,fidtotcommamnt              
            ,fiddrawdownacct             
            ,fidprinliqacct              
            ,fidprinbenbk_d_1            
            ,fidprinbenbk_d_2            
            ,prinincrease                
            ,increffdate                 
            ,rollovermarker              
            ,rolloverdate                
            ,rolloverintrate             
            ,newinterestrate             
            ,newintrstspread             
            ,confbycust                  
            ,confbybroker                
            ,swiftcommonref              
            ,status                      
            ,totinttax                   
            ,intccy                      
            ,intccymkt                   
            ,chgvaluedate                
            ,autorollover                
            ,autocapitalise              
            ,MM_MRKT.authoriser                
            ,MM_MRKT.cocode
        ) BUS_QRY
    ) HASH_PREP
) FINAL WHERE FK_UP <> 1
