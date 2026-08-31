SELECT COUNT(*) FROM (
    SELECT hash_prep.*,
        CASE WHEN HASH_PREP.HASH_KEY = FIRST_VALUE(HASH_PREP.HASH_KEY) OVER(
            PARTITION BY HASH_PREP.ACCT_KEY ORDER BY HASH_PREP.strt_dt ASC
            ROWS BETWEEN 1 PRECEDING AND 1 PRECEDING)
        THEN 1 ELSE 0 END AS FK_UP
    FROM (
        SELECT BUS_QRY.*,
            sha2(
coalesce(CCY_KEY, '') ||
coalesce(BLK_AMT, '') ||
coalesce(AVL_BAL, '') ||
coalesce(CLR_BAL, '') ||
coalesce(UNCLR_BAL, '') ||
coalesce(UNCLR_CR, '') ||
coalesce(CR_LMT, '') ||
coalesce(PRE_AUTH_BLK, '') ||
coalesce(PRE_AUTH_UNCLR, '') ||
coalesce(PRE_AUTH_EXP_BLK, '') ||
coalesce(PRE_AUTH_EXP_UNCLR, '') ||
coalesce(AVL_BAL_UNSNT, '') ||
coalesce(BLK_AMT_UNSNT, '') ||
coalesce(UNCLR_CR_UNSNT, '') ||
coalesce(SHDW_AUTH_OV, '') ||
coalesce(UNCLR_LOG_CR, '') ||
coalesce(TEC_STS, '')
            , 256) AS HASH_KEY
        FROM (
            SELECT 
             ACCT_KEY      				   
             ,CCY_KEY             			   
             ,BLK_AMT                			   
             ,AVL_BAL            			   
             ,CLR_BAL               			   
             ,UNCLR_BAL 
             ,UNCLR_CR 		
             ,CR_LMT 
             ,PRE_AUTH_BLK        
             ,PRE_AUTH_UNCLR     
             ,PRE_AUTH_EXP_BLK     
             ,PRE_AUTH_EXP_UNCLR 
             ,AVL_BAL_UNSNT     
             ,BLK_AMT_UNSNT        
             ,UNCLR_CR_UNSNT   
             ,SHDW_AUTH_OV  
             ,UNCLR_LOG_CR
             ,CASE WHEN op = 'd' THEN 'Deleted' ELSE 'Active' END as TEC_STS
             ,STRT_DT
            FROM 
            (	
            		SELECT 
            		 Accno              AS ACCT_KEY      				   
            		,currcode           AS CCY_KEY             			   
            		,blkamt             AS BLK_AMT                			   
            		,avlbal             AS AVL_BAL            			   
            		,clrbal             AS CLR_BAL               			   
            		,unclrbal           AS UNCLR_BAL 
            	    ,unclrcredit        AS UNCLR_CR 		
            		,credit_limit       AS CR_LMT 
            		,preauth_blk        AS PRE_AUTH_BLK        
            		,preauth_unclr      AS PRE_AUTH_UNCLR     
            		,preauth_exp_blk    AS PRE_AUTH_EXP_BLK     
            		,preauth_exp_unclr  AS PRE_AUTH_EXP_UNCLR 
            		,avlbal_unsent      AS AVL_BAL_UNSNT    
            		,blkamt_unsent      AS BLK_AMT_UNSNT       
            		,unclrcredit_unsent AS UNCLR_CR_UNSNT 
            		,shdwauthov         AS SHDW_AUTH_OV  
            		,unclrlocredit      AS UNCLR_LOG_CR  
            	        ,op
            		,CAST(from_unixtime(CAST(ts_ms AS BIGINT) DIV 1000) AS date) AS STRT_DT	
            		,row_number () over (partition by accno, CAST(from_unixtime(CAST(ts_ms AS BIGINT) DIV 1000) AS date) order by verno_ctx ) as rnk  
            		 
            		FROM  ${stg_schema}.accdet         
            )ACCT_DTL
            WHERE RNK = 1
        ) BUS_QRY
    ) HASH_PREP
) FINAL WHERE FK_UP <> 1
