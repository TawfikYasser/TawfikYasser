SELECT COUNT(*) FROM (
    SELECT hash_prep.*,
        CASE WHEN HASH_PREP.HASH_KEY = FIRST_VALUE(HASH_PREP.HASH_KEY) OVER(
            PARTITION BY HASH_PREP.CUST_KEY ORDER BY HASH_PREP.strt_dt ASC
            ROWS BETWEEN 1 PRECEDING AND 1 PRECEDING)
        THEN 1 ELSE 0 END AS FK_UP
    FROM (
        SELECT BUS_QRY.*,
            sha2(
coalesce(PROD_KEY, '') ||
coalesce(PROD_NUM, '') ||
coalesce(PROD_CAT_KEY, '') ||
coalesce(PROD_CAT_NM, '') ||
coalesce(PROD_CAT_PRNT_KEY, '') ||
coalesce(PROD_CAT_PRNT, '') ||
coalesce(HIERARCHY_PATH, '') ||
coalesce(PROD_STS_KEY, '') ||
coalesce(PROD_STS, '') ||
coalesce(PROD_STA_KEY, '') ||
coalesce(PROD_STA, '') ||
coalesce(CRT_BY_KEY, '') ||
coalesce(CRT_BY, '') ||
coalesce(MDFYD_BY_KEY, '') ||
coalesce(MDFYD_BY, '') ||
coalesce(CRT_BEHALF_BY_KEY, '') ||
coalesce(CRT_BEHALF_BY, '') ||
coalesce(MDFYD_BEHALF_BY_KEY, '') ||
coalesce(MDFYD_BEHALF_BY, '')
            , 256) AS HASH_KEY
        FROM (
            select stg.* ,mod.hash_key as old_hash_key           	,NULL								AS	END_DTTM
                         ,CURRENT_TIMESTAMP                          AS  Tec_Insrt_Dttm
            		   ,CURRENT_TIMESTAMP                          AS  Tec_Upd_Dttm
            		   ,null                          AS  DR_Dttm
            		   ,null                          AS  DR_Flg
            ,CURRENT_TIMESTAMP					AS	STRT_DTTM
            ,CURRENT_DATE						AS	STRT_DT
            from
            ( 
            SELECT BASE.*
            ,SHA2 (  COALESCE(PROD_CAT_NM,'') || COALESCE(PROD_CAT_PRNT,'') || COALESCE(PROD_STS,'') || COALESCE(PROD_STA,'') ,256 ) HASH_KEY
            FROM 
            (
            SELECT 
             FIN_PROD.ATOS_CUSTOMERID			AS	CUST_KEY
            ,FIN_PROD.atos_financialproductId   AS  PROD_KEY
            ,FIN_PROD.ATOS_NAME					AS  PROD_NUM
            ,PROD.PRODUCTID						AS	PROD_CAT_KEY
            ,PROD.NAME							AS	PROD_CAT_NM
            ,PROD.PARENTPRODUCTID				AS	PROD_CAT_PRNT_KEY
            ,CASE WHEN PROD.PARENTPRODUCTID = PROD.PRODUCTID THEN NAME	END AS	PROD_CAT_PRNT
            ,PROD.HIERARCHYPATH					AS	HIERARCHY_PATH
            ,STS.REF_CD                         AS	PROD_STS_KEY
            ,STS.REF_VAL                        AS	PROD_STS
            ,STA.REF_CD                         AS	PROD_STA_KEY
            ,STA.REF_VAL                        AS	PROD_STA
            ,FIN_PROD.CREATEDON					AS	CRT_DTTM
            ,FIN_PROD.CREATEDBY					AS	CRT_BY_KEY
            ,CRT_BY.FULLNAME					AS	CRT_BY
            ,FIN_PROD.MODIFIEDON				AS	MDFYD_DTTM
            ,FIN_PROD.MODIFIEDBY				AS	MDFYD_BY_KEY
            ,MDFYD_BY.FULLNAME					AS	MDFYD_BY
            ,FIN_PROD.CREATEDONBEHALFBY			AS	CRT_BEHALF_BY_KEY
            ,CRT_BEHALF_BY.FULLNAME				AS	CRT_BEHALF_BY
            ,FIN_PROD.MODIFIEDONBEHALFBY		AS	MDFYD_BEHALF_BY_KEY
            ,MDFYD_BEHALF_BY.FULLNAME			AS	MDFYD_BEHALF_BY	
            
            
            	
            FROM ${stg_schema}.ATOS_FINANCIALPRODUCTBASE FIN_PROD 
            INNER JOIN ${stg_schema}.PRODUCTBASE	PROD
             ON FIN_PROD.ATOS_PRODUCT=PROD.PRODUCTID
             
            
            
            LEFT JOIN ${mod_schema}.CRM_REF STS 
                ON FIN_PROD.STATUSCODE = STS.REF_CD
            	AND STS.ENTITY_CAT = 'ATOS_FINANCIALPRODUCT'
            	AND UPPER(STS.ATTRIBUTE_CAT)=UPPER('statuscode')
            	AND STS.LANG = 1033
            
            
            LEFT JOIN  ${mod_schema}.CRM_REF STA 
            	ON FIN_PROD.STATECODE =STA.REF_CD
            	AND STA.ENTITY_CAT = 'ATOS_FINANCIALPRODUCT'
            	AND UPPER(STA.ATTRIBUTE_CAT)= UPPER('STATECODE') 
            	AND STA.LANG = 1033
            
            
            LEFT JOIN ${stg_schema}.SYSTEMUSERBASE CRT_BY 
            	ON (FIN_PROD.CREATEDBY = CRT_BY.SYSTEMUSERID)
            LEFT JOIN ${stg_schema}.SYSTEMUSERBASE CRT_BEHALF_BY 
            	ON (FIN_PROD.CREATEDONBEHALFBY = CRT_BEHALF_BY.SYSTEMUSERID)
            LEFT JOIN ${stg_schema}.SYSTEMUSERBASE MDFYD_BY 
            	ON (FIN_PROD.MODIFIEDBY = MDFYD_BY.SYSTEMUSERID)
            LEFT JOIN ${stg_schema}.SYSTEMUSERBASE MDFYD_BEHALF_BY 
            	ON (FIN_PROD.MODIFIEDONBEHALFBY = MDFYD_BEHALF_BY.SYSTEMUSERID)
            	)BASE
            ) as stg
            LEFT JOIN ${mod_schema}.${table_name}    mod
            on  stg.hash_key =mod.hash_key and stg.PROD_KEY =mod.PROD_KEY 
            AND MOD.END_DTTM is null   
            where  mod.PROD_KEY is  null
            
            union 
            select stg.* ,mod.hash_key as old_hash_key ,          	NULL								AS	END_DTTM
                       ,CURRENT_TIMESTAMP                          AS  Tec_Insrt_Dttm
            		   ,CURRENT_TIMESTAMP                          AS  Tec_Upd_Dttm
            		   ,null                          AS  DR_Dttm
            		   ,null                          AS  DR_Flg
            ,CURRENT_TIMESTAMP					AS	STRT_DTTM
            ,CURRENT_DATE						AS	STRT_DT
            from
            ( 
            SELECT BASE.*
            ,SHA2 (  COALESCE(PROD_CAT_NM,'') || COALESCE(PROD_CAT_PRNT,'') || COALESCE(PROD_STS,'') || COALESCE(PROD_STA,'') ,256 ) HASH_KEY
            FROM 
            (
            SELECT 
             FIN_PROD.ATOS_CUSTOMERID			AS	CUST_KEY
            ,FIN_PROD.atos_financialproductId   AS  PROD_KEY
            ,FIN_PROD.ATOS_NAME					AS  PROD_NUM
            ,PROD.PRODUCTID						AS	PROD_CAT_KEY
            ,PROD.NAME							AS	PROD_CAT_NM
            ,PROD.PARENTPRODUCTID				AS	PROD_CAT_PRNT_KEY
            ,CASE WHEN PROD.PARENTPRODUCTID = PROD.PRODUCTID THEN NAME	END AS	PROD_CAT_PRNT
            ,PROD.HIERARCHYPATH					AS	HIERARCHY_PATH
            ,STS.REF_CD                         AS	PROD_STS_KEY
            ,STS.REF_VAL                        AS	PROD_STS
            ,STA.REF_CD                         AS	PROD_STA_KEY
            ,STA.REF_VAL                        AS	PROD_STA
            ,FIN_PROD.CREATEDON					AS	CRT_DTTM
            ,FIN_PROD.CREATEDBY					AS	CRT_BY_KEY
            ,CRT_BY.FULLNAME					AS	CRT_BY
            ,FIN_PROD.MODIFIEDON				AS	MDFYD_DTTM
            ,FIN_PROD.MODIFIEDBY				AS	MDFYD_BY_KEY
            ,MDFYD_BY.FULLNAME					AS	MDFYD_BY
            ,FIN_PROD.CREATEDONBEHALFBY			AS	CRT_BEHALF_BY_KEY
            ,CRT_BEHALF_BY.FULLNAME				AS	CRT_BEHALF_BY
            ,FIN_PROD.MODIFIEDONBEHALFBY		AS	MDFYD_BEHALF_BY_KEY
            ,MDFYD_BEHALF_BY.FULLNAME			AS	MDFYD_BEHALF_BY	
            
            
            	
            FROM ${stg_schema}.ATOS_FINANCIALPRODUCTBASE FIN_PROD 
            INNER JOIN ${stg_schema}.PRODUCTBASE	PROD
             ON FIN_PROD.ATOS_PRODUCT=PROD.PRODUCTID
             
            
            
            LEFT JOIN ${mod_schema}.CRM_REF STS 
                ON FIN_PROD.STATUSCODE = STS.REF_CD
            	AND STS.ENTITY_CAT = 'ATOS_FINANCIALPRODUCT'
            	AND UPPER(STS.ATTRIBUTE_CAT)=UPPER('statuscode')
            	AND STS.LANG = 1033
            
            
            LEFT JOIN  ${mod_schema}.CRM_REF STA 
            	ON FIN_PROD.STATECODE =STA.REF_CD
            	AND STA.ENTITY_CAT = 'ATOS_FINANCIALPRODUCT'
            	AND UPPER(STA.ATTRIBUTE_CAT)= UPPER('STATECODE') 
            	AND STA.LANG = 1033
            
            
            LEFT JOIN ${stg_schema}.SYSTEMUSERBASE CRT_BY 
            	ON (FIN_PROD.CREATEDBY = CRT_BY.SYSTEMUSERID)
            LEFT JOIN ${stg_schema}.SYSTEMUSERBASE CRT_BEHALF_BY 
            	ON (FIN_PROD.CREATEDONBEHALFBY = CRT_BEHALF_BY.SYSTEMUSERID)
            LEFT JOIN ${stg_schema}.SYSTEMUSERBASE MDFYD_BY 
            	ON (FIN_PROD.MODIFIEDBY = MDFYD_BY.SYSTEMUSERID)
            LEFT JOIN ${stg_schema}.SYSTEMUSERBASE MDFYD_BEHALF_BY 
            	ON (FIN_PROD.MODIFIEDONBEHALFBY = MDFYD_BEHALF_BY.SYSTEMUSERID)
            	)BASE
            ) as stg
            right JOIN ${mod_schema}.${table_name}    mod
            on  stg.hash_key =mod.hash_key and stg.PROD_KEY =mod.PROD_KEY 
            AND MOD.END_DTTM is null 
            where  stg.PROD_KEY is  null
        ) BUS_QRY
    ) HASH_PREP
) FINAL WHERE FK_UP <> 1
