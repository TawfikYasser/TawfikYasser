SELECT COUNT(*) FROM (
    SELECT hash_prep.*,
        CASE WHEN HASH_PREP.HASH_KEY = FIRST_VALUE(HASH_PREP.HASH_KEY) OVER(
            PARTITION BY HASH_PREP.srv_actn_key, HASH_PREP.srv_actn_req_key ORDER BY HASH_PREP.strt_dt ASC
            ROWS BETWEEN 1 PRECEDING AND 1 PRECEDING)
        THEN 1 ELSE 0 END AS FK_UP
    FROM (
        SELECT BUS_QRY.*,
            sha2(
coalesce(sys_srv_actn_key, '') ||
coalesce(srv_actn_nm, '') ||
coalesce(cust_key, '') ||
coalesce(cust_full_nm, '') ||
coalesce(case_key, '') ||
coalesce(srv_req_key, '') ||
coalesce(dr_acct_key, '') ||
coalesce(cr_acct_key, '') ||
coalesce(pan_display, '') ||
coalesce(crd_sts_key, '') ||
coalesce(crd_sts, '') ||
coalesce(trnsfr_amt, '') ||
coalesce(max_amt, '') ||
coalesce(lmt_typ, '') ||
coalesce(bus_unit_key, '') ||
coalesce(bus_unit_nm, '') ||
coalesce(sta_key, '') ||
coalesce(sta, '') ||
coalesce(sts_key, '') ||
coalesce(sts_descr, '') ||
coalesce(pref_chnl_key, '') ||
coalesce(pref_chnl, '') ||
coalesce(pref_lang_key, '') ||
coalesce(pref_lang, '') ||
coalesce(pref_mthod_key, '') ||
coalesce(pref_mthod, '') ||
coalesce(sgmnt_key, '') ||
coalesce(sgmnt, '') ||
coalesce(srv_actn_purpose, '') ||
coalesce(replace_rsn, '') ||
coalesce(descr, '') ||
coalesce(is_intg_flg, '') ||
coalesce(err_msg, '') ||
coalesce(own_usr_key, '') ||
coalesce(own_team_key, '') ||
coalesce(owner_nm, '') ||
coalesce(owner_typ, '') ||
coalesce(crtd_by_nm, '') ||
coalesce(crtd_on_bhlf_nm, '') ||
coalesce(modfd_by_nm, '') ||
coalesce(modfd_on_bhlf_nm, '') ||
coalesce(tec_sts, '')
            , 256) AS HASH_KEY
        FROM (
            SELECT
            Srv_actn.atos_name                                     AS srv_actn_key,  --pk
            Srv_actn.atos_customerserviceactionrequestid           AS srv_actn_req_key, --pk
            Srv_actn.atos_serviceaction                            AS sys_srv_actn_key,
            CAL.calendar_dt                                        AS Strt_dt,
            Srv_actn_Dtls.atos_name                                AS srv_actn_nm,
            Srv_actn.atos_customerid                               AS cust_key,
            Cust_Dtls.fullname                                     AS cust_full_nm,
            Srv_actn.atos_case                                     AS case_key,
            Srv_actn.atos_servicerequest                           AS srv_req_key,
            COALESCE(Dr_Acct.atos_name,'-1')                       AS dr_acct_key,
            COALESCE(Cr_Acct.atos_name,'-1')                       AS cr_acct_key,
            COALESCE(Crd.atos_name,'-1')                           AS pan_display,
            Srv_actn.atos_cardstatus                               AS crd_sts_key,
            Crd_Sts.ref_val                                        AS crd_sts,
            Atos_amounttotransfer                                  AS trnsfr_amt,
            Atos_maxvalue                                          AS max_amt,
            Lmt.ref_val                                            AS lmt_typ,
            Srv_actn.atos_effectivedate                            AS eff_dttm,
            Srv_actn.atos_turnondate                               AS turnon_dttm,
            Srv_actn.atos_expirydate                               AS exp_dttm,
            Srv_actn.owningbusinessunit                            AS bus_unit_key,
            Busns.name                                             AS bus_unit_nm,
            Srv_actn.statecode                                     AS sta_key,
            Sta.ref_val                                            AS sta,
            Srv_actn.statuscode                                    AS sts_key,
            Sts.ref_val                                            AS sts_descr,
            Srv_actn.atos_preferredchannel                         AS pref_chnl_key,
            Pref_Chnl.ref_val                                      AS pref_chnl,
            Srv_actn.atos_preferredcommunicationlanguage           AS pref_lang_key,
            Pref_Comm_Lang.ref_val                                 AS pref_lang,
            Srv_actn.atos_preferredcommunicationmethod             AS pref_mthod_key,
            Pref_Comm_Mthod.ref_val                                AS pref_mthod,
            Srv_actn.atos_segment                                  AS sgmnt_key,
            Seg.ref_val                                            AS sgmnt,
            Srv_actn.atos_purpose                                  AS srv_actn_purpose,
            Srv_actn.atos_replacereason                            AS replace_rsn,
            Srv_actn.atos_description                              AS descr,
            Srv_actn.atos_isintegrationsuccess                     AS is_intg_flg,
            Srv_actn.atos_errormessage                             AS err_msg,
            CASE WHEN Srv_Ownr.owneridtype = '8' THEN Srv_Ownr.ownerid END AS own_usr_key,
            CASE WHEN Srv_Ownr.owneridtype = '9' THEN Srv_Ownr.ownerid END AS own_team_key,
            Srv_Ownr.name                                          AS owner_nm,
            Srv_Ownr.owneridtype                                   AS owner_typ,
            Srv_actn.createdon                                     AS crtd_dttm,
            Crtd_By.fullname                                       AS crtd_by_nm,
            Crtd_Bhlf_By.fullname                                  AS crtd_on_bhlf_nm,
            Srv_actn.modifiedon                                    AS modfd_dttm,
            Modfd_By.fullname                                      AS modfd_by_nm,
            Modfd_Bhlf_By.fullname                                 AS modfd_on_bhlf_nm,
            CASE WHEN Srv_Actn.op = 'd' THEN 'Deleted' ELSE 'Active' END AS tec_sts
             
             
             
            FROM  
            (
            	SELECT *
            	FROM dwh_base.calendar_base
                WHERE calendar_dt BETWEEN '${strt_dt}' AND '${end_dt}'
            )CAL
             
             
            LEFT  JOIN
            (
            	SELECT
                *,
                COALESCE(
                    DATE_ADD(
                        LEAD(strt_dt) OVER (PARTITION BY atos_customerserviceactionrequestid ORDER BY strt_dt),-1
                    ),DATE '2999-12-31'
                ) AS End_Dt
            	FROM
            	(
                      SELECT
            		  Atos_customerserviceactionrequestid
            		,atos_name
            		,atos_customerid
            		,Atos_account
            		,atos_description
            		,atos_card
            		,atos_cardstatus
            		,atos_case	
            		,atos_servicerequest
            		,atos_accountsource		
            		,Atos_accountdestination
            		,owningbusinessunit
            		,statecode
            		,statuscode
            	    ,CAST(Atos_amounttotransfer AS DECIMAL(18,4)) AS Atos_amounttotransfer	  
            		,CAST(atos_maxvalue AS DECIMAL(18,4)) AS atos_maxvalue
            		,CAST(from_unixtime(CAST(atos_effectivedate AS BIGINT) Div 1000)AS TIMESTAMP)as atos_effectivedate
                    ,cast(from_unixtime(cast(atos_turnondate as bigint) div 1000) as TIMESTAMP)  as atos_turnondate
            		,cast(from_unixtime(cast(atos_expirydate as bigint) div 1000) as TIMESTAMP)  as atos_expirydate
            		,atos_errormessage
            		,atos_isintegrationsuccess
            		,atos_limittype
            		,atos_newvpannumber
            		,atos_oldvpannumber
            		,atos_preferredchannel
            		,atos_preferredcommunicationlanguage
            		,atos_preferredcommunicationmethod
            		,atos_purpose
            		,atos_replacereason
            		,atos_segment
            		,atos_serviceaction
            		,Ownerid
            		,createdby		
            		,modifiedby
            		,createdonbehalfby
            		,modifiedonbehalfby
            		,cast(from_unixtime(cast(modifiedon as bigint) div 1000) as TIMESTAMP) as modifiedon
            		,cast(from_unixtime(cast(createdon as bigint) div 1000) as TIMESTAMP) as createdon
                    ,CASE
                        WHEN ROW_NUMBER() OVER (PARTITION BY atos_customerserviceactionrequestid ORDER BY ts_ms ASC) = 1
                         THEN CAST(from_unixtime(CAST(CreatedOn AS BIGINT) DIV 1000) AS date)
                        ELSE CAST(from_unixtime(CAST(modifiedon AS BIGINT) DIV 1000) AS date)
                    END AS strt_dt
            		,op
            		,ROW_NUMBER() OVER ( PARTITION BY atos_customerserviceactionrequestid, CAST(from_unixtime(CAST(modifiedon AS BIGINT) DIV 1000) AS date) ORDER BY  tec_insrt_dttm DESC ,TS_MS DESC ,modifiedon DESC, CASE WHEN op='c' THEN 0 WHEN op='u' THEN 1 END DESC, versionnumber DESC  ) AS rnk
                    
            		FROM ${stg_schema}.Atos_customerserviceactionrequestbase
            	
            	    WHERE atos_customerserviceactionrequestid IS NOT NULL
             
            	)Srv
            	
            	WHERE rnk = 1
            )Srv_Actn
            ON CAL.calendar_dt BETWEEN Srv_Actn.strt_dt  AND Srv_Actn.end_dt
            	
             
            Left join
            (
            		Select
            		*,
            		Coalesce(
            			date_add(
            				lead(strt_dt) over (partition by atos_customerid order by strt_dt),-1
            			),date '2999-12-31'
            		) as end_dt
            		from
            		(
            			Select
            			atos_customerid,
            			fullname,
            			cast(from_unixtime(cast(modifiedon as bigint) div 1000) as date) as strt_dt,
            			row_number() over (partition by atos_customerid,cast(from_unixtime(cast(modifiedon as bigint) div 1000) as date) order by ts_ms desc, modifiedon desc) rnk
            		
            			From ${stg_crm_db_nm}.contactbase
            		)cntct
            		where rnk = 1
            )cust_dtls	
            on  cust_dtls.atos_customerid = Srv_Actn.atos_customerid
            And cal.calendar_dt between cust_dtls.strt_dt  and cust_dtls.end_dt
             
             
            Left join
            (
            		Select
            		*
            		from
            		(
            			Select
            			atos_financialproductid,
            			atos_name,
            			cast(from_unixtime(cast(modifiedon as bigint) div 1000) as date) as strt_dt,
            			row_number() over (partition by atos_financialproductid order by ts_ms desc, modifiedon desc) rnk
            		
            			From ${stg_crm_db_nm}.Atos_financialproductbase
            		)crd_prod
            		where rnk = 1
            )CRD	
            On  CRD.atos_financialproductid = srv_actn.atos_card
             
             
            Left join
            (
            		Select
            		*
            		from
            		(
            			Select
            			atos_financialproductid,
            			atos_name,
            			cast(from_unixtime(cast(modifiedon as bigint) div 1000) as date) as strt_dt,
            			row_number() over (partition by atos_financialproductid order by ts_ms desc, modifiedon desc) rnk
            		
            			From ${stg_crm_db_nm}.Atos_financialproductbase
            		)Acct
            		where rnk = 1
            )DR_ACCT	
            On  DR_ACCT.atos_financialproductid = srv_actn.atos_accountsource
             
            Left join
            (
            		Select
            		*
            		from
            		(
            			Select
            			atos_financialproductid,
            			atos_name,
            			cast(from_unixtime(cast(modifiedon as bigint) div 1000) as date) as strt_dt,
            			row_number() over (partition by atos_financialproductid order by ts_ms desc, modifiedon desc) rnk
            		
            			From ${stg_crm_db_nm}.Atos_financialproductbase
            		)Acct
            		where rnk = 1
            )CR_ACCT	
            On  CR_ACCT.atos_financialproductid = srv_actn.Atos_accountdestination
             
             
             
             
            Left join
            (
            		Select
            		*
            		from
            		(
            			Select
            			Atos_serviceactionsid,
            			atos_name,
            			cast(from_unixtime(cast(modifiedon as bigint) div 1000) as date) as strt_dt,
            			row_number() over (partition by Atos_serviceactionsid order by ts_ms desc, modifiedon desc) rnk
            		
            			From ${stg_crm_db_nm}.Atos_serviceactionsbase
            		)SRV
            		where rnk = 1
            )SRV_ACTN_DTLS	
            on  SRV_ACTN_DTLS.Atos_serviceactionsid = Srv_Actn.Atos_serviceaction
             
             
             
            Left join
            (
            	SELECT
                *
            	FROM
            	(
                    SELECT
                    BUSINESSUNITID,
                    NAME,
                    ROW_NUMBER() OVER ( PARTITION BY BUSINESSUNITID ORDER BY TS_MS DESC,  modifiedon DESC) AS rnk
                    
            		FROM ${stg_schema}.BUSINESSUNITBASE
            	)BUSINESSUNITBASE
            	WHERE rnk = 1
            )BUSNS
            ON  BUSNS.Businessunitid = srv_actn.Owningbusinessunit
             
             
            LEFT JOIN dwh_base.CRM_REF CRD_STS
            ON  CRD_STS.REF_CD  = Srv_Actn.atos_cardstatus
            and UPPER(CRD_STS.ENTITY_CAT)='ATOS_CUSTOMERSERVICEACTIONREQUEST'
            AND UPPER(CRD_STS.ATTRIBUTE_CAT)= 'ATOS_CARDSTATUS'
            AND CRD_STS.LANG = '1033'
            AND CRD_STS.ENDDT is null
             
             
            LEFT JOIN dwh_base.CRM_REF STA
            ON  STA.REF_CD  = Srv_Actn.STATECODE
            and UPPER(STA.ENTITY_CAT)='ATOS_CUSTOMERSERVICEACTIONREQUEST'
            AND UPPER(STA.ATTRIBUTE_CAT)= 'STATECODE'
            AND STA.LANG = '1033'
            AND STA.ENDDT is null
             
             
            LEFT JOIN dwh_base.CRM_REF STS
            ON  STS.REF_CD  = Srv_Actn.STATUSCODE
            and UPPER(STS.ENTITY_CAT)='ATOS_CUSTOMERSERVICEACTIONREQUEST'
            AND UPPER(STS.ATTRIBUTE_CAT)= 'STATUSCODE'
            AND STS.LANG = '1033'
            AND STS.ENDDT is null
             
             
            LEFT JOIN dwh_base.CRM_REF LMT
            ON  LMT.REF_CD  = Srv_Actn.atos_limittype
            and UPPER(LMT.ENTITY_CAT)='ATOS_CUSTOMERSERVICEACTIONREQUEST'
            AND UPPER(LMT.ATTRIBUTE_CAT)= 'ATOS_LIMITTYPE'
            AND LMT.LANG = '1033'
            AND LMT.ENDDT is null
             
             
            LEFT JOIN dwh_base.CRM_REF PREF_CHNL
            ON  PREF_CHNL.REF_CD  = Srv_Actn.atos_preferredchannel
            and UPPER(PREF_CHNL.ENTITY_CAT)='ATOS_CUSTOMERSERVICEACTIONREQUEST'
            AND UPPER(PREF_CHNL.ATTRIBUTE_CAT)= 'ATOS_PREFERREDCHANNEL'
            AND PREF_CHNL.LANG = '1033'
            AND PREF_CHNL.ENDDT is null
             
             
            LEFT JOIN dwh_base.CRM_REF PREF_COMM_LANG
            ON  PREF_COMM_LANG.REF_CD  = Srv_Actn.atos_preferredcommunicationlanguage
            and UPPER(PREF_COMM_LANG.ENTITY_CAT)='ATOS_CUSTOMERSERVICEACTIONREQUEST'
            AND UPPER(PREF_COMM_LANG.ATTRIBUTE_CAT)= 'ATOS_PREFERREDCOMMUNICATIONLANGUAGE'
            AND PREF_COMM_LANG.LANG = '1033'
            AND PREF_COMM_LANG.ENDDT is null
             
             
            LEFT JOIN dwh_base.CRM_REF PREF_COMM_MTHOD
            ON  PREF_COMM_MTHOD.REF_CD  = Srv_Actn.atos_preferredcommunicationmethod
            and UPPER(PREF_COMM_MTHOD.ENTITY_CAT)='ATOS_CUSTOMERSERVICEACTIONREQUEST'
            AND UPPER(PREF_COMM_MTHOD.ATTRIBUTE_CAT)= 'ATOS_PREFERREDCOMMUNICATIONMETHOD'
            AND PREF_COMM_MTHOD.LANG = '1033'
            AND PREF_COMM_MTHOD.ENDDT is null
             
             
             
            LEFT JOIN dwh_base.CRM_REF SEG
            ON  SEG.REF_CD  = Srv_Actn.ATOS_SEGMENT
            and UPPER(SEG.ENTITY_CAT)='ATOS_CUSTOMERSERVICEACTIONREQUEST'
            AND UPPER(SEG.ATTRIBUTE_CAT)= 'ATOS_SEGMENT'
            AND SEG.LANG = '1033'
            AND SEG.ENDDT is null
             
             
             
            LEFT  JOIN
            (
            	SELECT
                *,
                COALESCE(
                    DATE_ADD(
                        LEAD(strt_dt) OVER (PARTITION BY OWNERID ORDER BY strt_dt),-1
                    ),DATE '2999-12-31'
                ) AS End_Dt
            	FROM
            	(
                    SELECT
                    Ownerid,
            		owneridtype,
                    NAME,
                    CAST(from_unixtime(CAST(TS_MS AS BIGINT) DIV 1000) AS date) AS strt_dt,
                    ROW_NUMBER() OVER ( PARTITION BY OWNERID, CAST(from_unixtime(CAST(TS_MS AS BIGINT) DIV 1000) AS date) ORDER BY TS_MS DESC) AS rnk
                    
            		FROM ${stg_schema}.OWNERBASE
            	)OWNR
            	WHERE rnk = 1
            )SRV_OWNR
            ON  SRV_OWNR.OWNERID = Srv_Actn.OWNERID
            AND CAL.calendar_dt BETWEEN SRV_OWNR.strt_dt  AND SRV_OWNR.end_dt
             
             
            LEFT JOIN
            (
            		SELECT systemuserid ,
            		fullname,
            		row_number() over(PARTITION BY systemuserid   ORDER BY ts_ms DESC , ModifiedOn DESC) RNK
            		
            		FROM ${stg_schema}.SystemUserBase
            )CRTD_BY
            ON  CRTD_BY.systemuserid = SRV_ACTN.Createdby
            AND CRTD_BY.RNK = 1
             
            LEFT JOIN
            (
            		SELECT systemuserid ,
            		fullname,
            		row_number() over(PARTITION BY systemuserid   ORDER BY ts_ms DESC  , ModifiedOn DESC ) RNK
            		
            		FROM ${stg_schema}.SystemUserBase
            )CRTD_BHLF_BY
            ON  CRTD_BHLF_BY.systemuserid = SRV_ACTN.Createdonbehalfby
            AND CRTD_BHLF_BY.RNK = 1
             
            LEFT JOIN
            (
            		SELECT systemuserid ,
            		fullname,
            		row_number() over(PARTITION BY systemuserid   ORDER BY ts_ms DESC  , ModifiedOn DESC ) RNK
            		
            		FROM ${stg_schema}.SystemUserBase
            )MODFD_BY
            ON  MODFD_BY.systemuserid = SRV_ACTN.Modifiedby
            AND MODFD_BY.RNK = 1
             
            LEFT JOIN
            (
            		SELECT systemuserid ,
            		fullname,
            		row_number() over(PARTITION BY systemuserid   ORDER BY ts_ms DESC ) RNK
            		
            		FROM ${stg_schema}.SystemUserBase
            )MODFD_BHLF_BY
            ON  MODFD_BHLF_BY.systemuserid = SRV_ACTN.Modifiedonbehalfby
            AND MODFD_BHLF_BY.RNK = 1
        ) BUS_QRY
    ) HASH_PREP
) FINAL WHERE FK_UP <> 1
