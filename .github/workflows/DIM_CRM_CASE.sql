SELECT COUNT(*) FROM (
    SELECT hash_prep.*,
        CASE WHEN HASH_PREP.HASH_KEY = FIRST_VALUE(HASH_PREP.HASH_KEY) OVER(
            PARTITION BY HASH_PREP.case_key ORDER BY HASH_PREP.strt_dt ASC
            ROWS BETWEEN 1 PRECEDING AND 1 PRECEDING)
        THEN 1 ELSE 0 END AS FK_UP
    FROM (
        SELECT BUS_QRY.*,
            sha2(
coalesce(prnt_case_key, '') ||
coalesce(tkt_key, '') ||
coalesce(acct_key, '') ||
coalesce(crd_key, '') ||
coalesce(cust_key, '') ||
coalesce(cust_nm, '') ||
coalesce(cust_addr, '') ||
coalesce(mbl_phn, '') ||
coalesce(email, '') ||
coalesce(srvc_key, '') ||
coalesce(titl, '') ||
coalesce(case_descr, '') ||
coalesce(compstn_descr, '') ||
coalesce(err_descr, '') ||
coalesce(src_sys, '') ||
coalesce(case_typ, '') ||
coalesce(ctgy_key, '') ||
coalesce(ctgy, '') ||
coalesce(sub_ctgy_key, '') ||
coalesce(sub_ctgy, '') ||
coalesce(subjct_key, '') ||
coalesce(subjct, '') ||
coalesce(prio_key, '') ||
coalesce(prio, '') ||
coalesce(svrty, '') ||
coalesce(sts, '') ||
coalesce(sts_descr, '') ||
coalesce(sla, '') ||
coalesce(route_flg, '') ||
coalesce(is_escltd, '') ||
coalesce(rslv_flg, '') ||
coalesce(rslv_rsn, '') ||
coalesce(rslv_cncld_descr, '') ||
coalesce(Is_rspnd_flg, '') ||
coalesce(asign_flg, '') ||
coalesce(ownr_nm, '') ||
coalesce(ownr_team, '') ||
coalesce(bus_nm, '') ||
coalesce(chnl, '') ||
coalesce(pref_comm_mthd, '') ||
coalesce(pref_lang, '') ||
coalesce(fcr, '') ||
coalesce(fpoc, '') ||
coalesce(is_cncl, '') ||
coalesce(cncl_rsn, '') ||
coalesce(cncl_rsn_dtl, '') ||
coalesce(lst_falir, '') ||
coalesce(exch_rt, '') ||
coalesce(disput_amt, '') ||
coalesce(disput_rsn, '') ||
coalesce(fees_typ, '') ||
coalesce(fees_amt, '') ||
coalesce(rfund_flg, '') ||
coalesce(rfund_typ, '') ||
coalesce(rfund_rsn, '') ||
coalesce(rfund_amt, '') ||
coalesce(rfund_ccy, '') ||
coalesce(auth_cd, '') ||
coalesce(dr_acct_key, '') ||
coalesce(sndr_mbl_phn, '') ||
coalesce(sndr_bnk, '') ||
coalesce(sndr_nm, '') ||
coalesce(cr_acct_key, '') ||
coalesce(rcvr_mbl_phn, '') ||
coalesce(bnfcry_acct_key, '') ||
coalesce(bnfcry_bnk, '') ||
coalesce(bnfcry_nm, '') ||
coalesce(crtd_by_nm, '') ||
coalesce(crtd_on_bhlf_nm, '') ||
coalesce(modfd_by_nm, '') ||
coalesce(modfd_on_bhlf_nm, '') ||
coalesce(TEC_STS, '')
            , 256) AS HASH_KEY
        FROM (
            
                                
                                SELECT
            
            Crm_case.incidentid                      			as    case_key    ---pk---
            ,cal.calendar_dt                         			as    strt_dt
            ,coalesce(crm_case.parentcaseid,'-1')               as    prnt_case_key
            ,crm_case.ticketnumber                   			as    tkt_key
            ,coalesce(prod_acct.atos_name ,'-1')               	as    acct_key
            ,coalesce(prod_crd.atos_name  ,'-1')               	as    crd_key
            ,coalesce(crm_case.atos_customerid,'-1')           	as    cust_key
            ,crm_case.customeridname                 			as    cust_nm
            ,crm_case.atos_attribute_address         			as    cust_addr
            ,crm_case.atos_attribute_mobilenumber               as    mbl_phn
            ,crm_case.emailaddress                   			as    email
            ,crm_case.atos_attribute_servicerequest  			as    srvc_key
            ,split(crm_case.title,'-')[3]            			as    titl
            ,crm_case.description                    			as    case_descr
            ,crm_case.atos_compensationdescription   			as    compstn_descr
            ,crm_case.atos_attribute_errordescription			as    err_descr
            ,crm_case.atos_attribute_system                     as    src_sys
            ,case_typ.atos_name                      			as    case_typ
            ,case_ctgy.atos_code                     			as    ctgy_key
            ,case_ctgy.atos_name                     			as    ctgy
            ,case_subctgy.atos_code                  			as    sub_ctgy_key
            ,case_subctgy.atos_name                  			as    sub_ctgy
            ,case_subj.atos_code                     			as    subjct_key
            ,case_subj.atos_name                     			as    subjct
            ,crm_case.prioritycode                   			as    prio_key
            ,priorty.ref_val                         			as    prio
            ,case_svrty.ref_val                      			as    svrty
            ,sta.ref_val                             			as    sts
            ,sts.ref_val                             			as    sts_descr
            ,case_sla.name                           			as    sla
            ,crm_case.routecase                      			as    route_flg
            ,crm_case.isescalated                    			as    is_escltd
            ,crm_case.escalatedon                    			as    escltd_dttm
            ,crm_case.atos_actualresolutiondate      			as    act_resltn_dttm
            ,crm_case.atos_resolvecase               			as    rslv_flg
            ,res_rsn.ref_val                         			as    rslv_rsn
            ,crm_case.atos_resolvecanceldescription  			as    rslv_cncld_descr
            ,crm_case.atos_closedate                 			as    cls_dttm
            ,Crm_case.atos_isreopenedcase                       as    Is_rspnd_flg
            ,crm_case.atos_assigncase                			as    asign_flg
            ,crm_case.atos_assigndateteam            			as    asign_team_dttm
            ,crm_case.atos_assigndateuser            			as    asign_usr_dttm
            ,case_ownr.name                          			as    ownr_nm
            ,team.name                               			as    ownr_team
            ,unit.name                               			as    bus_nm
            ,chnl.ref_val                            			as    chnl
            ,cast(pref_comm_mthd.ref_val as string)  			as    pref_comm_mthd
            ,lang.ref_val                            			as    pref_lang
            ,crm_case.atos_fcr				             		as    fcr
            ,crm_case.atos_fpoc            					    as    fpoc
            ,crm_case.atos_iscancel                  			as    is_cncl
            ,cncl_rsn.ref_val                        			as    cncl_rsn
            ,crm_case.atos_attribute_cancellationreason		    as    cncl_rsn_dtl
            ,crm_case.atos_lastfailure               			as    lst_falir
            ,sla_kpi.failuretime                     			as    falir_dttm
            ,crm_case.exchangerate                   			as    exch_rt
            ,crm_case.atos_attribute_disputedamount  			as    disput_amt
            ,DISPUTE_RSN.REF_VAL                                AS    disput_rsn
            ,fees_typ.ref_val 								    as    fees_typ
            ,crm_case.atos_attribute_amount1         			as    fees_amt
            ,crm_case.atos_refund                    			as    rfund_flg
            ,rfnd_typ.ref_val	                	            as    rfund_typ
            ,rfnd_rsn.ref_val	                	            as    rfund_rsn
            ,crm_case.atos_amount                    			as    rfund_amt
            ,crm_case.atos_currency                  			as    rfund_ccy
            ,crm_case.atos_attribute_authorizationcode1		    as    auth_cd
            --,crm_case.atos_attribute_authorizationcode		    as    ref_trx_key
            ,crm_case.atos_attribute_senderaccountnumber 		as    dr_acct_key
            ,crm_case.atos_attribute_sendermobilenumber  	    as    sndr_mbl_phn
            ,crm_case.atos_attribute_senderbank         		as    sndr_bnk
            ,crm_case.atos_attribute_sendername         		as    sndr_nm
            ,crm_case.atos_attribute_receiveraccountnumber 	    as    cr_acct_key
            ,crm_case.atos_attribute_receivermobilenumber    	as    rcvr_mbl_phn
            ,crm_case.atos_attribute_beneficiaryaccountnumber   as    bnfcry_acct_key
            ,crm_case.atos_attribute_beneficiarybank            as    bnfcry_bnk
            ,crm_case.atos_attribute_beneficiaryname            as    bnfcry_nm
            ,crm_case.createdon                                 as    crtd_dttm
            ,crtd_by.fullname                                   as    crtd_by_nm
            ,crtd_bhlf_by.fullname                              as    crtd_on_bhlf_nm
            ,crm_case.modifiedon                                as    modfd_dttm
            ,modfd_by.fullname                                  as    modfd_by_nm
            ,modfd_bhlf_by.fullname                             as    modfd_on_bhlf_nm
            ,case when CRM_CASE.op = 'd' THEN 'Deleted' ELSE 'Active' END AS TEC_STS
            
            
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
                        LEAD(strt_dt) OVER (PARTITION BY incidentid ORDER BY strt_dt),-1
                    ),DATE '2999-12-31'
                ) AS End_Dt
            	FROM 
            	(
                  SELECT
            	
            		 incidentid
            		,ticketnumber
            		,parentcaseid
            		/* Case Details */
            		,title
            		,description
            		,atos_attribute_servicerequest
            		,atos_compensationdescription
            		,atos_pendingcustomertracker
            		,atos_attribute_errordescription
            		,atos_attribute_system
            		,statecode
            		,statuscode
            		,prioritycode
            		,severitycode
            		,routecase
            		,isescalated
            		,atos_isreopenedcase
            		,atos_iscancel
            		,ATOS_CASETYPE
            		,Atos_casecategory
            		,Atos_casesubcategory
            		,Atos_casesubject
            		,Caseorigincode
            		,Atos_fcr
            		,Atos_preferredcommunicationmethod
            		,Atos_preferredlanguage
            		,Slaid
            		,atos_attribute_accountproduct
            		,atos_attribute_cardproduct
            		,atos_customerid
            		,customeridname
            		,emailaddress
            		,atos_attribute_address
            		,atos_attribute_mobilenumber
                    ,Atos_currency
            		,CAST(CASE WHEN exchangerate IS NULL THEN '1.00' ELSE exchangerate END AS DECIMAL(6,2)) AS exchangerate
            		,CAST(CASE WHEN atos_amount IS NULL THEN '0.00' ELSE atos_amount END AS DECIMAL(18,2))  AS atos_amount
            		,CAST(CASE WHEN atos_attribute_amount1 IS NULL THEN '0.00' ELSE atos_attribute_amount1 END AS DECIMAL(18,2)) AS atos_attribute_amount1
            		,CAST(CASE WHEN atos_attribute_disputedamount IS NULL THEN '0.00'  ELSE atos_attribute_disputedamount END AS DECIMAL(18,2)) AS atos_attribute_disputedamount
            		,atos_attribute_feestype
            		,atos_attribute_refundreason
            		,Atos_attribute_authorizationcode
            		,atos_attribute_authorizationcode1
            
            		/* Sender & Receiver Information */
            		,atos_attribute_senderaccountnumber
            		,atos_attribute_sendermobilenumber
            		,atos_attribute_senderbank
            		,atos_attribute_sendername
            		,atos_attribute_receiveraccountnumber
            		,atos_attribute_receivermobilenumber
            
            		/* Beneficiary Information */
            		,atos_attribute_beneficiaryaccountnumber
            		,atos_attribute_beneficiarybank
            		,atos_attribute_beneficiaryname
            		
            		/* Resolution & Closure */
            		,atos_resolvecase
            		,atos_resolvereason
            		,atos_cancelreason
            		,Atos_attribute_disputereasontype
            		,atos_attribute_cancellationreason
            		,atos_resolvecanceldescription
            		,atos_lastfailure
            		,atos_refund
            		,atos_refundtype
            		,CAST(from_unixtime(CAST(escalatedon AS BIGINT) DIV 1000) AS TIMESTAMP) AS escalatedon
            		,CAST(from_unixtime(CAST(atos_actualresolutiondate AS BIGINT) DIV 1000) AS TIMESTAMP) AS atos_actualresolutiondate
            		,CAST(from_unixtime(CAST(atos_closedate AS BIGINT) DIV 1000) AS TIMESTAMP) AS atos_closedate
            		
            		,ownerid
            		,atos_assigncase
            		,atos_ownerteam
            		,owningbusinessunit
            		,ATOS_FPOC
            		,CAST(from_unixtime(unix_timestamp(atos_assigndateteam,'M/d/yyyy h:mm a'),  'yyyy-MM-dd HH:mm:ss.SSS') AS TIMESTAMP) AS atos_assigndateteam
                    ,CAST(from_unixtime(unix_timestamp(atos_assigndateuser,'M/d/yyyy h:mm a'), 'yyyy-MM-dd HH:mm:ss.SSS') AS TIMESTAMP) AS atos_assigndateuser
            		,Createdby
            		,Createdonbehalfby
            		,Modifiedby
            		,Modifiedonbehalfby
            		,CAST(from_unixtime(CAST(CreatedOn AS BIGINT) DIV 1000) AS TIMESTAMP) AS CreatedOn
            		,CAST(from_unixtime(CAST(modifiedon AS BIGINT) DIV 1000) AS TIMESTAMP) AS ModifiedOn
            		,CASE
            			WHEN ROW_NUMBER() OVER (
            					PARTITION BY incidentid ORDER BY TS_MS ASC ) = 1
            			THEN CAST(from_unixtime(CAST(CreatedOn AS BIGINT) DIV 1000) AS DATE)
            			ELSE CAST(from_unixtime(CAST(modifiedon AS BIGINT) DIV 1000) AS DATE)
            		 END AS strt_dt
            		,op
            		,ROW_NUMBER() OVER (
            			PARTITION BY incidentid,
            						 CAST(from_unixtime(CAST(modifiedon AS BIGINT) DIV 1000) AS DATE)
            			ORDER BY TS_MS DESC,
            					 modifiedon DESC
            		 ) AS rnk
            
            		FROM ${stg_schema}.incidentbase
                )INCDNT
            	WHERE rnk = 1
            )CRM_CASE 
            ON CAL.calendar_dt BETWEEN CRM_CASE.strt_dt  AND CRM_CASE.end_dt
            	
            
            LEFT  JOIN
            (
            	SELECT
                *,
                COALESCE(
                    DATE_ADD(
                        LEAD(strt_dt) OVER (PARTITION BY ATOS_CASECATEGORYID ORDER BY strt_dt),-1
                    ),DATE '2999-12-31'
                ) AS End_Dt
            	FROM 
            	(
                    SELECT
                    ATOS_CASECATEGORYID,
            		ATOS_CODE,
                    ATOS_NAME,
                    CAST(from_unixtime(CAST(modifiedon AS BIGINT) DIV 1000) AS date) AS strt_dt,
                    ROW_NUMBER() OVER ( PARTITION BY ATOS_CASECATEGORYID, CAST(from_unixtime(CAST(modifiedon AS BIGINT) DIV 1000) AS date) ORDER BY TS_MS DESC,  modifiedon DESC) AS rnk
                  
            		FROM ${stg_schema}.ATOS_CASECATEGORYBASE
            	)CTGY
            	WHERE rnk = 1
            )CASE_CTGY 
            ON CASE_CTGY.ATOS_CASECATEGORYID = CRM_CASE.ATOS_CASECATEGORY
            AND CAL.calendar_dt BETWEEN CASE_CTGY.strt_dt  AND CASE_CTGY.end_dt
            
            LEFT  JOIN
            (
            	SELECT
                *,
                COALESCE(
                    DATE_ADD(
                        LEAD(strt_dt) OVER (PARTITION BY ATOS_CASESUBCATEGORYID ORDER BY strt_dt),-1
                    ),DATE '2999-12-31'
                ) AS End_Dt
            	FROM 
            	(
                    SELECT
                    ATOS_CASESUBCATEGORYID,
            		ATOS_CODE,
                    ATOS_NAME,
                    CAST(from_unixtime(CAST(modifiedon AS BIGINT) DIV 1000) AS date) AS strt_dt,
                    ROW_NUMBER() OVER ( PARTITION BY ATOS_CASESUBCATEGORYID, CAST(from_unixtime(CAST(modifiedon AS BIGINT) DIV 1000) AS date) 
            		                    ORDER BY TS_MS DESC,  modifiedon DESC) AS rnk  
            		FROM ${stg_schema}.ATOS_CASESUBCATEGORYBASE
            	)CTGY
            	WHERE rnk = 1
            )CASE_SUBCTGY 
            ON CASE_SUBCTGY.ATOS_CASESUBCATEGORYID = CRM_CASE.ATOS_CASESUBCATEGORY
            AND CAL.calendar_dt BETWEEN CASE_SUBCTGY.strt_dt  AND CASE_SUBCTGY.end_dt
            
            LEFT  JOIN
            (
            	SELECT
                *,
                COALESCE(
                    DATE_ADD(
                        LEAD(strt_dt) OVER (PARTITION BY SLAID ORDER BY strt_dt),-1
                    ),DATE '2999-12-31'
                ) AS End_Dt
            	FROM 
            	(
                    SELECT
                    SLAID,
            		NAME,
                    CAST(from_unixtime(CAST(modifiedon AS BIGINT) DIV 1000) AS date) AS strt_dt,
                    ROW_NUMBER() OVER ( PARTITION BY SLAID, CAST(from_unixtime(CAST(modifiedon AS BIGINT) DIV 1000) AS date) 
            		                    ORDER BY TS_MS DESC,  modifiedon DESC) AS rnk
                    
            		FROM ${stg_schema}.SLABASE
            		WHERE STATECODE = 1
            	)SLA
            	WHERE rnk = 1
            )CASE_SLA
            ON CASE_SLA.SLAID = CRM_CASE.SLAID
            AND CAL.calendar_dt BETWEEN CASE_SLA.strt_dt  AND CASE_SLA.end_dt
            
            LEFT  JOIN
            (
            	SELECT
                *,
                COALESCE(
                    DATE_ADD(
                        LEAD(strt_dt) OVER (PARTITION BY ATOS_CASETYPEID ORDER BY strt_dt),-1
                    ),DATE '2999-12-31'
                ) AS End_Dt
            	FROM 
            	(
                    SELECT
                    ATOS_CASETYPEID,
            		ATOS_NAME,
                    CAST(from_unixtime(CAST(modifiedon AS BIGINT) DIV 1000) AS date) AS strt_dt,
                    ROW_NUMBER() OVER ( PARTITION BY ATOS_CASETYPEID, CAST(from_unixtime(CAST(modifiedon AS BIGINT) DIV 1000) AS date) 
            		                    ORDER BY TS_MS DESC, modifiedon DESC) AS rnk
                    
            		FROM ${stg_schema}.ATOS_CASETYPEBASE
            		
            	)TYP
            	WHERE rnk = 1
            )CASE_TYP
            ON CASE_TYP.ATOS_CASETYPEID = CRM_CASE.ATOS_CASETYPE
            AND CAL.calendar_dt BETWEEN CASE_TYP.strt_dt  AND CASE_TYP.end_dt
            
            
            
            lEFT  JOIN
            (
            	SELECT
                *,
                COALESCE(
                    DATE_ADD(
                        LEAD(strt_dt) OVER (PARTITION BY BUSINESSUNITID ORDER BY strt_dt),-1
                    ),DATE '2999-12-31'
                ) AS End_Dt
            	FROM 
            	(
                    SELECT
                    BUSINESSUNITID,
                    NAME,
                    CAST(from_unixtime(CAST(modifiedon AS BIGINT) DIV 1000) AS date) AS strt_dt,
                    ROW_NUMBER() OVER ( PARTITION BY BUSINESSUNITID, CAST(from_unixtime(CAST(modifiedon AS BIGINT) DIV 1000) AS date) ORDER BY TS_MS DESC,  modifiedon DESC) AS rnk
                    
            		FROM ${stg_schema}.BUSINESSUNITBASE
            	)UNIT_BASE
            	WHERE rnk = 1
            )UNIT
            ON  UNIT.BUSINESSUNITID = CRM_CASE.OWNINGBUSINESSUNIT 
            AND CAL.calendar_dt BETWEEN UNIT.strt_dt  AND UNIT.end_dt
            
            
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
                    OWNERID,
                    NAME,
                    CAST(from_unixtime(CAST(TS_MS AS BIGINT) DIV 1000) AS date) AS strt_dt,
                    ROW_NUMBER() OVER ( PARTITION BY OWNERID, CAST(from_unixtime(CAST(TS_MS AS BIGINT) DIV 1000) AS date) ORDER BY TS_MS DESC) AS rnk
                    
            		FROM ${stg_schema}.OWNERBASE
            	)OWNR
            	WHERE rnk = 1
            )CASE_OWNR
            ON  CASE_OWNR.OWNERID = CRM_CASE.OWNERID 
            AND CAL.calendar_dt BETWEEN CASE_OWNR.strt_dt  AND CASE_OWNR.end_dt
            
            
            LEFT  JOIN
            (
            	SELECT
                *,
                COALESCE(
                    DATE_ADD(
                        LEAD(strt_dt) OVER (PARTITION BY TEAMID ORDER BY strt_dt),-1
                    ),DATE '2999-12-31'
                ) AS End_Dt
            	FROM 
            	(
                    SELECT
                    TEAMID,
                    NAME,
                    CAST(from_unixtime(CAST(modifiedon AS BIGINT) DIV 1000) AS date) AS strt_dt,
                    ROW_NUMBER() OVER ( PARTITION BY TEAMID, CAST(from_unixtime(CAST(modifiedon AS BIGINT) DIV 1000) AS date) ORDER BY  TS_MS DESC,  modifiedon DESC) AS rnk
                    
            		FROM ${stg_schema}.TEAMBASE
            	)TEAM
            	WHERE rnk = 1
            )TEAM
            ON  TEAM.TEAMID = CRM_CASE.ATOS_OWNERTEAM 
            AND CAL.calendar_dt BETWEEN TEAM.strt_dt  AND TEAM.end_dt    
            
            
            LEFT  JOIN
            (
            	SELECT
                *,
                COALESCE(
                    DATE_ADD(
                        LEAD(strt_dt) OVER (PARTITION BY ATOS_CASESUBJECTID ORDER BY strt_dt),-1
                    ),DATE '2999-12-31'
                ) AS End_Dt
            	FROM 
            	(
                    SELECT
                    ATOS_CASESUBJECTID,
            		ATOS_CODE,
                    ATOS_NAME,
                    CAST(from_unixtime(CAST(modifiedon AS BIGINT) DIV 1000) AS date) AS strt_dt,
                    ROW_NUMBER() OVER ( PARTITION BY ATOS_CASESUBJECTID, CAST(from_unixtime(CAST(modifiedon AS BIGINT) DIV 1000) AS date) ORDER BY    TS_MS DESC,  modifiedon DESC) AS rnk
                    
            		FROM ${stg_schema}.ATOS_CASESUBJECTBASE
            	)SUBJ
            	WHERE rnk = 1
            )CASE_SUBJ
            ON CASE_SUBJ.ATOS_CASESUBJECTID = CRM_CASE.ATOS_CASESUBJECT
            AND CAL.calendar_dt BETWEEN CASE_SUBJ.strt_dt  AND CASE_SUBJ.end_dt
            
               
            LEFT JOIN dwh_base.CRM_REF PRIORTY
            ON  PRIORTY.REF_CD = CRM_CASE.PRIORITYCODE
            AND UPPER(PRIORTY.ENTITY_CAT)= UPPER('INCIDENT')
            AND UPPER(PRIORTY.ATTRIBUTE_CAT)= UPPER('PRIORITYCODE') 
            AND PRIORTY.LANG = '1033' 
            AND PRIORTY.ENDDT is null
            
            LEFT JOIN dwh_base.CRM_REF PREF_COMM_MTHD 
            ON CAST(PREF_COMM_MTHD.REF_CD AS INT) = CAST(CRM_CASE.ATOS_PREFERREDCOMMUNICATIONMETHOD AS INT)
            AND PREF_COMM_MTHD.LANG = '1033' 
            AND PREF_COMM_MTHD.ENDDT is null
            and UPPER(PREF_COMM_MTHD.ENTITY_CAT)='INCIDENT'
            AND UPPER(PREF_COMM_MTHD.ATTRIBUTE_CAT)= 'ATOS_PREFERREDCOMMUNICATIONMETHOD'
            
            LEFT JOIN  dwh_base.CRM_REF LANG 
            ON LANG.REF_CD  = CRM_CASE.ATOS_PREFERREDLANGUAGE
            AND LANG.LANG = '1033'
            AND LANG.ENDDT is null
            AND UPPER(LANG.ENTITY_CAT)= 'INCIDENT'
            AND UPPER(LANG.ATTRIBUTE_CAT)= 'ATOS_PREFERREDLANGUAGE'
            
            LEFT JOIN dwh_base.CRM_REF CHNL 
            ON CHNL.REF_CD = CRM_CASE.CASEORIGINCODE
            AND CHNL.LANG = '1033' 
            AND CHNL.ENDDT is null
            AND UPPER(CHNL.ENTITY_CAT) = 'INCIDENT'
            AND UPPER(CHNL.ATTRIBUTE_CAT)= 'CASEORIGINCODE'
            
            LEFT JOIN dwh_base.CRM_REF STS 
            ON STS.REF_CD = CRM_CASE.STATUSCODE
            AND STS.LANG = '1033' 
            AND STS.ENDDT is null
            AND UPPER(STS.ENTITY_CAT)= 'INCIDENT'
            AND UPPER(STS.ATTRIBUTE_CAT)= 'STATUSCODE'
            
            LEFT JOIN dwh_base.CRM_REF STA 
            ON STA.REF_CD = CRM_CASE.STATECODE 
            AND STA.LANG = '1033' 
            AND STA.ENDDT is null
            AND UPPER(STA.ENTITY_CAT)= 'INCIDENT'
            AND UPPER(STA.ATTRIBUTE_CAT)= 'STATECODE'
            
            
            LEFT JOIN dwh_base.CRM_REF CNCL_RSN 
            ON CNCL_RSN.REF_CD = CRM_CASE.ATOS_CANCELREASON
            AND CNCL_RSN.LANG = '1033' 
            AND CNCL_RSN.ENDDT is null
            AND UPPER(CNCL_RSN.ENTITY_CAT)='INCIDENT'
            AND UPPER(CNCL_RSN.ATTRIBUTE_CAT)= 'ATOS_CANCELREASON'
            
            LEFT JOIN dwh_base.CRM_REF RES_RSN 
            ON RES_RSN.REF_CD = CRM_CASE.ATOS_RESOLVEREASON 
            AND RES_RSN.LANG = '1033' 
            AND RES_RSN.ENDDT is null
            AND UPPER(RES_RSN.ENTITY_CAT)='INCIDENT'
            AND UPPER(RES_RSN.ATTRIBUTE_CAT)= 'ATOS_RESOLVEREASON'
            
            LEFT JOIN dwh_base.CRM_REF CASE_SVRTY 
            ON  CASE_SVRTY.REF_CD = CRM_CASE.SEVERITYCODE 
            AND CASE_SVRTY.LANG = '1033'
            AND CASE_SVRTY.ENDDT is null
            AND UPPER(CASE_SVRTY.ENTITY_CAT)= 'INCIDENT'
            AND UPPER(CASE_SVRTY.ATTRIBUTE_CAT)= 'SEVERITYCODE' 
            
            LEFT JOIN dwh_base.CRM_REF RFND_TYP 
            ON  RFND_TYP.REF_CD = CRM_CASE.atos_refundtype 
            AND RFND_TYP.LANG = '1033' 
            AND RFND_TYP.ENDDT is null	 
            AND UPPER(RFND_TYP.ENTITY_CAT)= 'INCIDENT'
            AND UPPER(RFND_TYP.ATTRIBUTE_CAT)= 'ATOS_REFUNDTYPE'
            
            
            LEFT JOIN dwh_base.CRM_REF rfnd_RSN
            ON  rfnd_RSN.REF_CD = CRM_CASE.atos_attribute_refundreason
            AND rfnd_RSN.LANG = '1033' 
            AND rfnd_RSN.ENDDT is null	 
            AND UPPER(rfnd_RSN.ENTITY_CAT)= 'INCIDENT'
            AND UPPER(rfnd_RSN.ATTRIBUTE_CAT)= 'atos_attribute_refundreason'
            
            
            		   
            LEFT JOIN DWH_BASE.CRM_REF FEES_TYP 
            ON  FEES_TYP.REF_CD  = CRM_CASE.atos_attribute_feestype
            AND UPPER(FEES_TYP.ENTITY_CAT)=UPPER('INCIDENT')
            AND UPPER(FEES_TYP.ATTRIBUTE_CAT)=UPPER('ATOS_ATTRIBUTE_FEESTYPE') 
            AND FEES_TYP.LANG = '1033'
            AND FEES_TYP.ENDDT is null		
            
            
            		   
            LEFT JOIN DWH_BASE.CRM_REF DISPUTE_RSN 
            ON  DISPUTE_RSN.REF_CD  = CRM_CASE.ATOS_ATTRIBUTE_DISPUTEREASONTYPE
            AND UPPER(DISPUTE_RSN.ENTITY_CAT)=UPPER('INCIDENT')
            AND UPPER(DISPUTE_RSN.ATTRIBUTE_CAT)=UPPER('ATOS_ATTRIBUTE_DISPUTEREASONTYPE') 
            AND DISPUTE_RSN.LANG = '1033'
            AND DISPUTE_RSN.ENDDT is null	
            
            
            LEFT JOIN
            (
            		SELECT systemuserid ,
            		fullname,
            		row_number() over(PARTITION BY systemuserid   ORDER BY ts_ms DESC , ModifiedOn DESC) RNK
            		
            		FROM ${stg_schema}.SystemUserBase 
            )CRTD_BY
            ON  CRTD_BY.systemuserid = CRM_CASE.Createdby
            AND CRTD_BY.RNK = 1
            
            LEFT JOIN
            (
            		SELECT systemuserid ,
            		fullname,
            		row_number() over(PARTITION BY systemuserid   ORDER BY ts_ms DESC  , ModifiedOn DESC ) RNK
            		
            		FROM ${stg_schema}.SystemUserBase 
            )CRTD_BHLF_BY
            ON  CRTD_BHLF_BY.systemuserid = CRM_CASE.Createdonbehalfby
            AND CRTD_BHLF_BY.RNK = 1
            
            LEFT JOIN
            (
            		SELECT systemuserid ,
            		fullname,
            		row_number() over(PARTITION BY systemuserid   ORDER BY ts_ms DESC  , ModifiedOn DESC ) RNK
            		
            		FROM ${stg_schema}.SystemUserBase 
            )MODFD_BY
            ON  MODFD_BY.systemuserid = CRM_CASE.Modifiedby
            AND MODFD_BY.RNK = 1
            
            LEFT JOIN
            (
            		SELECT systemuserid ,
            		fullname,
            		row_number() over(PARTITION BY systemuserid   ORDER BY ts_ms DESC ) RNK
            		
            		FROM ${stg_schema}.SystemUserBase 
            )MODFD_BHLF_BY
            ON  MODFD_BHLF_BY.systemuserid = CRM_CASE.Modifiedonbehalfby
            AND MODFD_BHLF_BY.RNK = 1
            
            	 
            LEFT  JOIN
            (
            	SELECT
                *,
                COALESCE(
                    DATE_ADD(
                        LEAD(strt_dt) OVER (PARTITION BY regarding ORDER BY strt_dt),-1
                    ),DATE '2999-12-31'
                ) AS End_Dt
            	FROM 
            	(
                    SELECT
                    regarding,
            		CAST(from_unixtime(CAST(failuretime  AS BIGINT) DIV 1000) AS TIMESTAMP) AS failuretime ,
                    CAST(from_unixtime(CAST(modifiedon AS BIGINT) DIV 1000) AS date) AS strt_dt,
                    ROW_NUMBER() OVER ( PARTITION BY regarding, CAST(from_unixtime(CAST(modifiedon AS BIGINT) DIV 1000) AS date) 
            		                    ORDER BY TS_MS DESC,  modifiedon DESC) AS rnk  
            		FROM ${stg_schema}.SLAKPIINSTANCEBASE
            	)SLA_KPI
            	WHERE rnk = 1
            )SLA_KPI 
            ON SLA_KPI.REGARDING = CRM_CASE.INCIDENTID
            AND CAL.calendar_dt BETWEEN SLA_KPI.strt_dt  AND SLA_KPI.end_dt
            
            
            
            LEFT JOIN 
            (	
                SELECT
                *
                
            	FROM 
            	(
                    SELECT
                    atos_financialproductid,
            		Atos_name,
                    ROW_NUMBER() OVER ( PARTITION BY atos_financialproductid ORDER BY TS_MS DESC,  modifiedon DESC) AS rnk  
            		
            		FROM stg_crm.ATOS_FINANCIALPRODUCTBASE 
            	)ACCT
            	WHERE rnk = 1
            )PROD_ACCT
            ON PROD_ACCT.atos_financialproductid = crm_case.atos_attribute_accountproduct
            
            
            LEFT JOIN 
            (	
                SELECT
                *
            	FROM 
            	(
                    SELECT
                    atos_financialproductid,
            		Atos_name,
            		
                    ROW_NUMBER() OVER ( PARTITION BY atos_financialproductid ORDER BY TS_MS DESC,  modifiedon DESC) AS rnk  
            		
            		FROM stg_crm.ATOS_FINANCIALPRODUCTBASE 
            	)CRD 
            	WHERE rnk = 1
            )PROD_CRD
            ON PROD_CRD.atos_financialproductid = CRM_CASE.ATOS_ATTRIBUTE_CARDPRODUCT
        ) BUS_QRY
    ) HASH_PREP
) FINAL WHERE FK_UP <> 1
