SELECT COUNT(*) FROM (
    SELECT hash_prep.*,
        CASE WHEN HASH_PREP.HASH_KEY = FIRST_VALUE(HASH_PREP.HASH_KEY) OVER(
            PARTITION BY HASH_PREP.sys_srv_req_key ORDER BY HASH_PREP.strt_dt ASC
            ROWS BETWEEN 1 PRECEDING AND 1 PRECEDING)
        THEN 1 ELSE 0 END AS FK_UP
    FROM (
        SELECT BUS_QRY.*,
            sha2(
coalesce(srv_req_key, '') ||
coalesce(prnt_srv_req_key, '') ||
coalesce(cust_key, '') ||
coalesce(acct_key, '') ||
coalesce(crd_key, '') ||
coalesce(f_nm, '') ||
coalesce(l_nm, '') ||
coalesce(Cust_nm, '') ||
coalesce(SR_Cust_nm, '') ||
coalesce(email, '') ||
coalesce(ntnlty_key, '') ||
coalesce(place_of_birth, '') ||
coalesce(city_nm, '') ||
coalesce(addr, '') ||
coalesce(area, '') ||
coalesce(flr_num, '') ||
coalesce(Apt_num, '') ||
coalesce(lst_city, '') ||
coalesce(lst_addr, '') ||
coalesce(lst_area, '') ||
coalesce(lst_flr_num, '') ||
coalesce(Lst_apt_num, '') ||
coalesce(live_outside_flg, '') ||
coalesce(hold_other_ntnlty, '') ||
coalesce(sr_typ, '') ||
coalesce(ctgy_key, '') ||
coalesce(ctgy, '') ||
coalesce(sub_ctgy_key, '') ||
coalesce(sub_ctgy, '') ||
coalesce(subjct, '') ||
coalesce(src_chnl, '') ||
coalesce(sgmnt_key, '') ||
coalesce(sgmnt, '') ||
coalesce(prio, '') ||
coalesce(pref_comm_mthd, '') ||
coalesce(pref_lang, '') ||
coalesce(sta_key, '') ||
coalesce(sta, '') ||
coalesce(sts_key, '') ||
coalesce(sts_descr, '') ||
coalesce(sla, '') ||
coalesce(rslv_sla, '') ||
coalesce(sla_invk, '') ||
coalesce(is_intg_flg, '') ||
coalesce(is_escltd_flg, '') ||
coalesce(sys, '') ||
coalesce(flr_cd, '') ||
coalesce(intg_flr_descr, '') ||
coalesce(is_doc_uploaded, '') ||
coalesce(cntct_num, '') ||
coalesce(cls_rsn, '') ||
coalesce(Ownr_key, '') ||
coalesce(ownr_usr, '') ||
coalesce(ownr_team, '') ||
coalesce(pndng_descr, '') ||
coalesce(pndng_rsn, '') ||
coalesce(aprvl_descr, '') ||
coalesce(aprvl_rsn, '') ||
coalesce(rjctn_descr, '') ||
coalesce(rjctn_rsn, '') ||
coalesce(rslv_descr, '') ||
coalesce(rslv_rsn, '') ||
coalesce(cls_flr, '') ||
coalesce(cls_flr_descr, '') ||
coalesce(on_hld_tm, '') ||
coalesce(crtd_by_key, '') ||
coalesce(crtd_by_nm, '') ||
coalesce(mdfyd_by_key, '') ||
coalesce(mdfyd_by_nm, '') ||
coalesce(crtd_bhlf_by_key, '') ||
coalesce(crtd_on_bhlf_nm, '') ||
coalesce(mdfyd_bhlf_by_key, '') ||
coalesce(mdfyd_bhlf_by, '') ||
coalesce(queue_name, '') ||
coalesce(queue_descr, '') ||
coalesce(queue_titl, '') ||
coalesce(TEC_STS, '')
            , 256) AS HASH_KEY
        FROM (
            
                                  SELECT  
                                     srv_req.atos_requestnumber                              AS srv_req_key
                                    ,srv_req.atos_servicerequestid                           AS sys_srv_req_key
                                    ,coalesce(srv_req.Atos_parentservicerequest,'-1')        AS prnt_srv_req_key
                                    ,coalesce(srv_req.atos_customerid,'-1')                  AS cust_key
                                    ,coalesce(SR_Acct.atos_name,'-1')                        AS acct_key
                                    ,coalesce(SR_CRD.atos_name,'-1')                         AS crd_key
                                    ,srv_req.strt_dt                                         AS strt_dt
                                    ,srv_req.atos_attribute_firstname                        AS f_nm
                                    ,srv_req.atos_attribute_lastname                         AS l_nm
                                    ,atos_customername                                       AS Cust_nm
                                    ,atos_attribute_customername                             AS SR_Cust_nm
                                    ,srv_req.atos_attribute_email                            AS email
                                    ,Cust_ntnlty.atos_iso2                                   AS ntnlty_key
                                    ,srv_req.atos_attribute_placeofbirth                     AS place_of_birth
                                    ,cust_city.atos_name                                     AS city_nm
                                    ,srv_req.atos_attribute_address                          AS addr
                                    ,srv_req.atos_attribute_area                             AS area
                                    ,srv_req.atos_attribute_floornumber_1                    AS flr_num
                                    ,srv_req.atos_attribute_aptnumber_1                      AS Apt_num
                                    ,CUST_LST_CITY.atos_name                                 AS lst_city
                                    ,srv_req.atos_attribute_lastaddress                      AS lst_addr
                                    ,srv_req.atos_attribute_lastarea                         AS lst_area
                                    ,srv_req.atos_attribute_lastfloornumber_1                AS lst_flr_num
                                    ,srv_req.atos_attribute_lastaptnumber_1                  AS Lst_apt_num
                                    ,srv_req.atos_attribute_iliveoutsideofegypt              AS live_outside_flg
                                    ,srv_req.atos_attribute_iholdanothernationality          AS hold_other_ntnlty
                                    ,SR_TYP.atos_name                                        AS sr_typ
                                    ,Sr_ctgy.atos_code                                       AS ctgy_key
                                    ,Sr_ctgy.atos_name                                       AS ctgy
                                    ,Sub_ctgy.atos_code                                      AS sub_ctgy_key
                                    ,Sub_ctgy.atos_name                                      AS sub_ctgy
                                    ,Subjct.atos_name                                        AS subjct
                                    ,SRC_CHNL.ref_val                                        AS src_chnl
                                    ,srv_req.atos_retailsegment                              AS sgmnt_key
                                    ,seg.ref_val                                             AS sgmnt
                                    ,pri.ref_val                                             AS prio
                                    ,Pref_comm_mthod.ref_val                                 AS pref_comm_mthd
                                    ,Pref_comm_lang.ref_val                                  AS pref_lang
                                    ,srv_req.statecode                                       AS sta_key
                                    ,Sta.ref_val                                             AS sta
                                    ,srv_req.statuscode                                       AS sts_key
                                    ,Sts.ref_val                                             AS sts_descr
                                    ,sla.name                                                AS sla
                                    ,sla_kpi.name                                            AS rslv_sla
                                    ,invk_sla.name                                           AS sla_invk
                                    ,intg.ref_val                                            AS is_intg_flg
                                    ,srv_req.atos_isslanlevelsstarted                        AS is_escltd_flg
                                    ,srv_req.atos_system                                     AS sys
                                    ,srv_req.atos_failurecode                                AS flr_cd
                                    ,srv_req.atos_integrationfailuredescription              AS intg_flr_descr
                                    ,srv_req.atos_attribute_isdocumentuploaded               AS is_doc_uploaded
                                    ,srv_req.atos_attribute_contactnumber                    AS cntct_num
                                    ,srv_req.atos_attribute_closurereason                    AS cls_rsn
                                    ,Srv_Req.Ownerid                                         AS Ownr_key
                                    ,CASE WHEN sr_ownr.owneridtype = '8' THEN sr_ownr.name ELSE NULL END AS ownr_usr
                                    ,CASE WHEN team.name IS NULL AND sr_ownr.owneridtype = '9' THEN sr_ownr.name ELSE team.name END AS ownr_team
                                    ,srv_req.atos_pendingdescription                         AS pndng_descr
                                    ,srv_req.atos_pendingreason_os                           AS pndng_rsn
                                    ,srv_req.atos_approvedescription                         AS aprvl_descr
                                    ,srv_req.atos_approvereason_os                           AS aprvl_rsn
                                    ,srv_req.atos_rejectsrdescription                        AS rjctn_descr
                                    ,srv_req.atos_rejectsrreason_os                          AS rjctn_rsn
                                    ,srv_req.atos_resolvesrdescription                       AS rslv_descr
                                    ,srv_req.atos_resolvesrreason_os                         AS rslv_rsn
                                    ,srv_req.atos_closefailure                               AS cls_flr
                                    ,srv_req.atos_closefailuredescription                    AS cls_flr_descr
                                    ,srv_req.createdon                                       AS crtd_dttm
                                    ,srv_req.modifiedon                                      AS mdfyd_dttm
                                    ,srv_req.atos_approverejectdate                          AS aprv_rjct_dt
                                    ,srv_req.lastonholdtime                                  AS lst_on_hld_dttm
                                    ,srv_req.onholdtime                                      AS on_hld_tm
                                    ,srv_req.createdby                                       AS crtd_by_key
                                    ,Crtd_by.fullname                                        AS crtd_by_nm
                                    ,srv_req.modifiedby                                      AS mdfyd_by_key
                                    ,MODFD_BY.fullname                                       AS mdfyd_by_nm
                                    ,srv_req.createdonbehalfby                               AS crtd_bhlf_by_key
                                    ,CRTD_BHLF_BY.fullname                                   AS crtd_on_bhlf_nm
                                    ,srv_req.modifiedonbehalfby                              AS mdfyd_bhlf_by_key
                                    ,MODFD_BHLF_BY.fullname                                  AS mdfyd_bhlf_by
                                    ,qbase.name                                              AS queue_name
                                    ,qbase.description                                       AS queue_descr
                                    ,qitembase.title                                         AS queue_titl
                                    ,CASE WHEN srv_req.op = 'd' THEN 'Deleted' ELSE 'Active' END AS TEC_STS
            
                                  FROM  
                                  (
                                    SELECT
                                      *
                                      ,COALESCE(
                                        DATE_ADD(LEAD(strt_dt) OVER (PARTITION BY Atos_requestnumber ORDER BY strt_dt), -1),
                                        DATE '2999-12-31'
                                      ) AS end_dt
                                    FROM 
                                    (
                                      SELECT 
                                         Atos_requestnumber
                                        ,atos_servicerequestid
                                        ,Atos_parentservicerequest
                                        ,atos_customerid
                                        ,atos_attribute_account
                                        ,atos_attribute_card
                                        ,atos_attribute_firstname
                                        ,atos_attribute_lastname
                                        ,atos_customername
                                        ,atos_attribute_customername
                                        ,atos_attribute_email
                                        ,atos_attribute_address
                                        ,atos_attribute_area
                                        ,atos_attribute_floornumber_1
                                        ,atos_attribute_aptnumber_1
                                        ,atos_attribute_lastarea
                                        ,atos_attribute_lastaddress
                                        ,atos_attribute_lastfloornumber_1
                                        ,atos_attribute_lastaptnumber_1
                                        ,atos_attribute_iliveoutsideofegypt
                                        ,atos_attribute_iholdanothernationality
                                        ,atos_attribute_placeofbirth
                                        ,statuscode
                                        ,statecode
                                        ,atos_retailsegment
                                        ,atos_processid
                                        ,atos_correlationid
                                        ,onholdtime
                                        ,CAST(from_unixtime(CAST(lastonholdtime AS BIGINT) Div 1000)AS TIMESTAMP)as lastonholdtime
                                        ,atos_integrationfailuredescription
                                        ,Atos_casetype
                                        ,slaid
                                        ,atos_resolvebysla
                                        ,slainvokedid
                                        ,atos_failurecode
                                        ,atos_system
                                        ,Atos_attribute_nationality
                                        ,atos_attribute_isdocumentuploaded
                                        ,atos_attribute_closurereason
                                        ,atos_attribute_contactnumber
                                        ,atos_pendingdescription
                                        ,atos_pendingreason_os
                                        ,atos_approvedescription
                                        ,atos_approvereason_os
                                        ,atos_rejectsrdescription
                                        ,atos_rejectsrreason_os
                                        ,atos_resolvesrdescription
                                        ,atos_resolvesrreason_os
                                        ,atos_closefailure
                                        ,atos_closefailuredescription
                                        ,CAST(from_unixtime(CAST(atos_approverejectdate AS BIGINT) Div 1000)AS TIMESTAMP)as atos_approverejectdate	
                                        ,Atos_attribute_city
                                        ,Atos_attribute_lastcity
                                        ,ATOS_SRCHANNEL
                                        ,Atos_priority
                                        ,atos_preferredcommunicationmethod
                                        ,ATOS_PREFERREDLANGUAGE
                                        ,ATOS_ISINTEGRATIONSUCCESS
                                        ,ATOS_OWNERTEAM
                                        ,Atos_casecategory
                                        ,Atos_casesubcategory
                                        ,Atos_casesubject
                                        ,atos_isslanlevelsstarted
                                        ,Ownerid
                                        ,createdby		
                                        ,modifiedby
                                        ,createdonbehalfby
                                        ,modifiedonbehalfby
                                        ,cast(from_unixtime(cast(modifiedon as bigint) div 1000) as TIMESTAMP) as modifiedon
                                        ,cast(from_unixtime(cast(createdon as bigint) div 1000) as TIMESTAMP) as createdon
                                        ,CASE 
                                          WHEN ROW_NUMBER() OVER (PARTITION BY atos_servicerequestid ORDER BY ts_ms ASC) = 1 
                                           THEN CAST(from_unixtime(CAST(CreatedOn AS BIGINT) DIV 1000) AS date)
                                          ELSE CAST(from_unixtime(CAST(modifiedon AS BIGINT) DIV 1000) AS date)
                                         END AS strt_dt
                                        ,op
                                        ,ROW_NUMBER() OVER ( PARTITION BY atos_servicerequestid, CAST(from_unixtime(CAST(modifiedon AS BIGINT) DIV 1000) AS date) ORDER BY TS_MS DESC , versionnumber DESC, tec_insrt_dttm DESC, modifiedon DESC, CASE WHEN op='c' THEN 0 WHEN op='u' THEN 1 END DESC ) AS rnk
                                          
                                      FROM ${stg_crm_db_nm}.Atos_servicerequestbase  
            
                                      WHERE atos_servicerequestid IS NOT NULL 
            
                                    )REQ
                                    
                                    WHERE rnk = 1
                                  )Srv_Req
            
                                  LEFT JOIN
                                  (
                                    select 
                                    atos_countryid
                                    ,atos_iso2
                                      ,ROW_NUMBER() OVER ( PARTITION BY atos_countryid ORDER BY modifiedon DESC , TS_MS DESC ) AS rnk
                                          
                                     from ${stg_crm_db_nm}.ATOS_COUNTRYBASE 
                                  )CUST_NTNLTY 
                                  ON CUST_NTNLTY.atos_countryid = Srv_Req.Atos_attribute_nationality 
                                  and CUST_NTNLTY.rnk = 1
            
                                  LEFT JOIN
                                  (
                                    select 
                                    Atos_cityid
                                    ,Atos_name
                                      ,ROW_NUMBER() OVER ( PARTITION BY Atos_cityid ORDER BY modifiedon DESC , TS_MS DESC ) AS rnk
                                          
                                     from ${stg_crm_db_nm}.ATOS_CITYBASE 
                                  )CUST_CITY
                                  ON CUST_CITY.Atos_cityid = Srv_Req.Atos_attribute_city 
                                  and CUST_CITY.rnk = 1
            
                                  LEFT JOIN
                                  (
                                    select 
                                    Atos_cityid
                                    ,Atos_name
                                      ,ROW_NUMBER() OVER ( PARTITION BY Atos_cityid ORDER BY modifiedon DESC , TS_MS DESC ) AS rnk
                                          
                                     from ${stg_crm_db_nm}.ATOS_CITYBASE 
                                  )CUST_LST_CITY
                                  ON CUST_LST_CITY.Atos_cityid = Srv_Req.Atos_attribute_lastcity 
                                  and CUST_LST_CITY.rnk = 1
            
                                  LEFT JOIN
                                  (
                                    SELECT
                                      *
                                      ,COALESCE(
                                        DATE_ADD(LEAD(strt_dt) OVER (PARTITION BY Teamid order by strt_dt),-1),DATE '2999-12-31'
                                      ) AS end_dt
                                    from 
                                    (
                                      select 
                                      Teamid
                                      ,name
                                      ,cast(from_unixtime(cast(modifiedon as bigint) div 1000) as TIMESTAMP) as strt_dt
                                      ,ROW_NUMBER() OVER ( PARTITION BY TEAMID ORDER BY modifiedon DESC , TS_MS DESC ) AS rnk
                                        
                                     from ${stg_crm_db_nm}.TEAMBASE 
                                    )TEAMBASE
                                    where rnk = 1
                                  )TEAM
                                  ON TEAM.Teamid = Srv_Req.Atos_ownerteam 
                                  and Srv_Req.strt_dt BETWEEN TEAM.strt_dt AND TEAM.end_dt 
            
                                  LEFT JOIN
                                  (
                                    SELECT
                                      *
                                      ,COALESCE(
                                        DATE_ADD(LEAD(strt_dt) OVER (PARTITION BY Ownerid order by strt_dt),-1),DATE '2999-12-31'
                                      ) AS end_dt
                                    from 
                                    (
                                      select 
                                      Ownerid
                                      ,owneridtype
                                      ,name
                                      ,cast(tec_insrt_dttm as date ) as strt_dt
                                      ,ROW_NUMBER() OVER ( PARTITION BY OWNERID ORDER BY TS_MS DESC) AS rnk
                                        
                                       from ${stg_crm_db_nm}.OWNERBASE 
                                    )ownrbase
                                    where rnk = 1
                                  )SR_OWNR
                                  ON SR_OWNR.Ownerid = Srv_Req.Ownerid 
                                  and Srv_Req.strt_dt BETWEEN SR_OWNR.strt_dt AND SR_OWNR.end_dt 
            
                                  LEFT JOIN
                                  (
                                    select * 
                                    ,COALESCE(
                                      DATE_ADD(LEAD(strt_dt) OVER (PARTITION BY SLAID order by strt_dt),-1),DATE '2999-12-31'
                                    ) AS end_dt
                                    from 
                                    (
                                      select 
                                      SLAID
                                      ,name
                                      ,cast(from_unixtime(cast(modifiedon as bigint) div 1000) as TIMESTAMP) as strt_dt
                                      ,ROW_NUMBER() OVER ( PARTITION BY SLAID ORDER BY modifiedon DESC , TS_MS DESC ) AS rnk
                                        
                                     from ${stg_crm_db_nm}.SLABASE 
                                   )SLABASE
                                   where rnk = 1
                                  )SLA
                                  ON SLA.SLAID = Srv_Req.Slaid 
                                  and Srv_Req.strt_dt BETWEEN SLA.strt_dt AND SLA.end_dt 
            
                                  LEFT JOIN
                                  (
                                      SELECT *
                                            ,COALESCE(
                                                  DATE_ADD(LEAD(strt_dt) OVER (PARTITION BY Slakpiinstanceid ORDER BY strt_dt),-1),
                                                  DATE '2999-12-31'
                                             ) AS end_dt
                                      FROM
                                      (
                                          SELECT
                                               Slakpiinstanceid
                                              ,name
                                              ,CAST(FROM_UNIXTIME(CAST(modifiedon AS BIGINT) DIV 1000) AS TIMESTAMP) AS strt_dt
                                              ,ROW_NUMBER() OVER (PARTITION BY Slakpiinstanceid, modifiedon ORDER BY TS_MS DESC) AS rnk
                                          FROM ${stg_crm_db_nm}.Slakpiinstancebase
                                      ) SLAKPI
                                      WHERE rnk = 1
                                  ) SLA_KPI
                                  ON SLA_KPI.Slakpiinstanceid = Srv_Req.Atos_resolvebysla
                                  AND Srv_Req.strt_dt BETWEEN SLA_KPI.strt_dt AND SLA_KPI.end_dt
            
                                  LEFT JOIN
                                  (
                                      SELECT *
                                            ,COALESCE(
                                                  DATE_ADD(LEAD(strt_dt) OVER (PARTITION BY SLAID ORDER BY strt_dt),-1),
                                                  DATE '2999-12-31'
                                             ) AS end_dt
                                      FROM
                                      (
                                          SELECT
                                               SLAID
                                              ,name
                                              ,CAST(FROM_UNIXTIME(CAST(modifiedon AS BIGINT) DIV 1000) AS TIMESTAMP) AS strt_dt
                                              ,ROW_NUMBER() OVER (PARTITION BY SLAID, modifiedon ORDER BY TS_MS DESC) AS rnk
                                          FROM ${stg_crm_db_nm}.SLABASE
                                      ) INVKSLA
                                      WHERE rnk = 1
                                  ) INVK_SLA
                                  ON INVK_SLA.SLAID = Srv_Req.SLAINVOKEDID
                                  AND Srv_Req.strt_dt BETWEEN INVK_SLA.strt_dt AND INVK_SLA.end_dt
            
                                  LEFT JOIN
                                  (
                                      SELECT *
                                            ,COALESCE(
                                                  DATE_ADD(LEAD(strt_dt) OVER (PARTITION BY ATOS_CASETYPEID ORDER BY strt_dt),-1),
                                                  DATE '2999-12-31'
                                             ) AS end_dt
                                      FROM
                                      (
                                          SELECT
                                               ATOS_CASETYPEID
                                              ,atos_name
                                              ,CAST(FROM_UNIXTIME(CAST(modifiedon AS BIGINT) DIV 1000) AS TIMESTAMP) AS strt_dt
                                              ,ROW_NUMBER() OVER (PARTITION BY ATOS_CASETYPEID, modifiedon ORDER BY TS_MS DESC) AS rnk
                                          FROM ${stg_crm_db_nm}.ATOS_CASETYPEBASE
                                      ) CASETYPE
                                      WHERE rnk = 1
                                  ) SR_TYP
                                  ON SR_TYP.ATOS_CASETYPEID = Srv_Req.ATOS_CASETYPE
                                  AND Srv_Req.strt_dt BETWEEN SR_TYP.strt_dt AND SR_TYP.end_dt
            
                                  LEFT JOIN
                                  (
                                      SELECT *
                                            ,COALESCE(
                                                  DATE_ADD(LEAD(strt_dt) OVER (PARTITION BY Atos_casecategoryid ORDER BY strt_dt),-1),
                                                  DATE '2999-12-31'
                                             ) AS end_dt
                                      FROM
                                      (
                                          SELECT
                                               Atos_casecategoryid
                                              ,atos_code
                                              ,atos_name
                                              ,CAST(FROM_UNIXTIME(CAST(modifiedon AS BIGINT) DIV 1000) AS TIMESTAMP) AS strt_dt
                                              ,ROW_NUMBER() OVER (PARTITION BY Atos_casecategoryid, modifiedon ORDER BY TS_MS DESC) AS rnk
                                          FROM ${stg_crm_db_nm}.ATOS_CASECATEGORYBASE
                                      ) CASECATEGORY
                                      WHERE rnk = 1
                                  ) SR_CTGY
                                  ON SR_CTGY.Atos_casecategoryid = Srv_Req.Atos_casecategory
                                  AND Srv_Req.strt_dt BETWEEN SR_CTGY.strt_dt AND SR_CTGY.end_dt
            
                                  LEFT JOIN
                                  (
                                      SELECT *
                                            ,COALESCE(
                                                  DATE_ADD(LEAD(strt_dt) OVER (PARTITION BY Atos_casesubcategoryid ORDER BY strt_dt),-1),
                                                  DATE '2999-12-31'
                                             ) AS end_dt
                                      FROM
                                      (
                                          SELECT
                                               Atos_casesubcategoryid
                                              ,atos_code
                                              ,atos_name
                                              ,CAST(FROM_UNIXTIME(CAST(modifiedon AS BIGINT) DIV 1000) AS TIMESTAMP) AS strt_dt
                                              ,ROW_NUMBER() OVER (PARTITION BY Atos_casesubcategoryid, modifiedon ORDER BY TS_MS DESC) AS rnk
                                          FROM ${stg_crm_db_nm}.ATOS_CASESUBCATEGORYBASE
                                      ) SUBCATEGORY
                                      WHERE rnk = 1
                                  ) SUB_CTGY
                                  ON SUB_CTGY.Atos_casesubcategoryid = Srv_Req.Atos_casesubcategory
                                  AND Srv_Req.strt_dt BETWEEN SUB_CTGY.strt_dt AND SUB_CTGY.end_dt
            
                                  LEFT JOIN
                                  (
                                      SELECT *
                                            ,COALESCE(
                                                  DATE_ADD(LEAD(strt_dt) OVER (PARTITION BY Atos_casesubjectid ORDER BY strt_dt),-1),
                                                  DATE '2999-12-31'
                                             ) AS end_dt
                                      FROM
                                      (
                                          SELECT
                                               Atos_casesubjectid
                                              ,atos_name
                                              ,CAST(FROM_UNIXTIME(CAST(modifiedon AS BIGINT) DIV 1000) AS TIMESTAMP) AS strt_dt
                                              ,ROW_NUMBER() OVER (PARTITION BY Atos_casesubjectid, modifiedon ORDER BY TS_MS DESC) AS rnk
                                          FROM ${stg_crm_db_nm}.ATOS_CASESUBJECTBASE
                                      ) SUBJECT
                                      WHERE rnk = 1
                                  ) SUBJCT
                                  ON SUBJCT.Atos_casesubjectid = Srv_Req.Atos_casesubject
                                  AND Srv_Req.strt_dt BETWEEN SUBJCT.strt_dt AND SUBJCT.end_dt
            
                                  LEFT JOIN
                                  (
                                      SELECT *
                                            ,COALESCE(
                                                  DATE_ADD(LEAD(strt_dt) OVER (PARTITION BY objectid ORDER BY strt_dt),-1),
                                                  DATE '2999-12-31'
                                             ) AS end_dt
                                      FROM
                                      (
                                          SELECT
                                               objectid
                                              ,queueid
                                              ,title
                                              ,CAST(FROM_UNIXTIME(CAST(modifiedon AS BIGINT) DIV 1000) AS TIMESTAMP) AS strt_dt
                                              ,ROW_NUMBER() OVER (PARTITION BY objectid, modifiedon ORDER BY TS_MS DESC) AS rnk
                                          FROM ${stg_crm_db_nm}.queueitembase
                                      ) QITEM
                                      WHERE rnk = 1
                                  ) QITEMBASE
                                  ON QITEMBASE.objectid = Srv_Req.atos_servicerequestid
                                  AND Srv_Req.strt_dt BETWEEN QITEMBASE.strt_dt AND QITEMBASE.end_dt
            
                                  LEFT JOIN
                                  (
                                      SELECT *
                                            ,COALESCE(
                                                  DATE_ADD(LEAD(strt_dt) OVER (PARTITION BY queueid ORDER BY strt_dt),-1),
                                                  DATE '2999-12-31'
                                             ) AS end_dt
                                      FROM
                                      (
                                          SELECT
                                               queueid
                                              ,name
                                              ,description
                                              ,CAST(FROM_UNIXTIME(CAST(modifiedon AS BIGINT) DIV 1000) AS TIMESTAMP) AS strt_dt
                                              ,ROW_NUMBER() OVER (PARTITION BY queueid, modifiedon ORDER BY TS_MS DESC) AS rnk
                                          FROM ${stg_crm_db_nm}.queuebase
                                      ) Q
                                      WHERE rnk = 1
                                  ) QBASE
                                  ON QBASE.queueid = QITEMBASE.queueid
                                  AND Srv_Req.strt_dt BETWEEN QBASE.strt_dt AND QBASE.end_dt
            
                                  LEFT JOIN
                                  (
                                      SELECT *
                                            ,COALESCE(
                                                  DATE_ADD(LEAD(strt_dt) OVER (PARTITION BY systemuserid ORDER BY strt_dt),-1),
                                                  DATE '2999-12-31'
                                             ) AS end_dt
                                      FROM
                                      (
                                          SELECT
                                               systemuserid
                                              ,fullname
                                              ,CAST(FROM_UNIXTIME(CAST(modifiedon AS BIGINT) DIV 1000) AS TIMESTAMP) AS strt_dt
                                              ,ROW_NUMBER() OVER (PARTITION BY systemuserid, modifiedon ORDER BY TS_MS DESC) AS rnk
                                          FROM ${stg_crm_db_nm}.SystemUserBase
                                      ) U
                                      WHERE rnk = 1
                                  ) CRTD_BY
                                  ON CRTD_BY.systemuserid = Srv_Req.Createdby
                                  AND Srv_Req.strt_dt BETWEEN CRTD_BY.strt_dt AND CRTD_BY.end_dt
            
                                  LEFT JOIN
                                  (
                                      SELECT *
                                            ,COALESCE(
                                                  DATE_ADD(LEAD(strt_dt) OVER (PARTITION BY systemuserid ORDER BY strt_dt),-1),
                                                  DATE '2999-12-31'
                                             ) AS end_dt
                                      FROM
                                      (
                                          SELECT
                                               systemuserid
                                              ,fullname
                                              ,CAST(FROM_UNIXTIME(CAST(modifiedon AS BIGINT) DIV 1000) AS TIMESTAMP) AS strt_dt
                                              ,ROW_NUMBER() OVER (PARTITION BY systemuserid, modifiedon ORDER BY TS_MS DESC) AS rnk
                                          FROM ${stg_crm_db_nm}.SystemUserBase
                                      ) U
                                      WHERE rnk = 1
                                  ) CRTD_BHLF_BY
                                  ON CRTD_BHLF_BY.systemuserid = Srv_Req.Createdonbehalfby
                                  AND Srv_Req.strt_dt BETWEEN CRTD_BHLF_BY.strt_dt AND CRTD_BHLF_BY.end_dt
            
                                  LEFT JOIN
                                  (
                                      SELECT *
                                            ,COALESCE(
                                                  DATE_ADD(LEAD(strt_dt) OVER (PARTITION BY systemuserid ORDER BY strt_dt),-1),
                                                  DATE '2999-12-31'
                                             ) AS end_dt
                                      FROM
                                      (
                                          SELECT
                                               systemuserid
                                              ,fullname
                                              ,CAST(FROM_UNIXTIME(CAST(modifiedon AS BIGINT) DIV 1000) AS TIMESTAMP) AS strt_dt
                                              ,ROW_NUMBER() OVER (PARTITION BY systemuserid, modifiedon ORDER BY TS_MS DESC) AS rnk
                                          FROM ${stg_crm_db_nm}.SystemUserBase
                                      ) U
                                      WHERE rnk = 1
                                  ) MODFD_BY
                                  ON MODFD_BY.systemuserid = Srv_Req.Modifiedby
                                  AND Srv_Req.strt_dt BETWEEN MODFD_BY.strt_dt AND MODFD_BY.end_dt
            
                                  LEFT JOIN
                                  (
                                      SELECT *
                                            ,COALESCE(
                                                  DATE_ADD(LEAD(strt_dt) OVER (PARTITION BY systemuserid ORDER BY strt_dt),-1),
                                                  DATE '2999-12-31'
                                             ) AS end_dt
                                      FROM
                                      (
                                          SELECT
                                               systemuserid
                                              ,fullname
                                              ,CAST(FROM_UNIXTIME(CAST(modifiedon AS BIGINT) DIV 1000) AS TIMESTAMP) AS strt_dt
                                              ,ROW_NUMBER() OVER (PARTITION BY systemuserid, modifiedon ORDER BY TS_MS DESC) AS rnk
                                          FROM ${stg_crm_db_nm}.SystemUserBase
                                      ) U
                                      WHERE rnk = 1
                                  ) MODFD_BHLF_BY
                                  ON MODFD_BHLF_BY.systemuserid = Srv_Req.Modifiedonbehalfby
                                  AND Srv_Req.strt_dt BETWEEN MODFD_BHLF_BY.strt_dt AND MODFD_BHLF_BY.end_dt
            
                                  LEFT JOIN
                                  (
                                    select 
                                    atos_financialproductid
                                    ,Atos_name
                                      ,ROW_NUMBER() OVER ( PARTITION BY atos_financialproductid ORDER BY modifiedon DESC , TS_MS DESC ) AS rnk
                                          
                                     from ${stg_crm_db_nm}.ATOS_FINANCIALPRODUCTBASE 
                                  )SR_Acct
                                  ON SR_Acct.atos_financialproductid = Srv_Req.atos_attribute_account 
                                  and SR_Acct.rnk = 1
            
                                  LEFT JOIN
                                  (
                                    select 
                                    atos_financialproductid
                                    ,Atos_name
                                      ,ROW_NUMBER() OVER ( PARTITION BY atos_financialproductid ORDER BY modifiedon DESC , TS_MS DESC ) AS rnk
                                          
                                     from ${stg_crm_db_nm}.ATOS_FINANCIALPRODUCTBASE 
                                  )SR_CRD
                                  ON SR_CRD.atos_financialproductid = Srv_Req.atos_attribute_card 
                                  and SR_CRD.rnk = 1
            
                                  LEFT JOIN dwh_base.CRM_REF SRC_CHNL 
                                  ON SRC_CHNL.REF_CD = Srv_Req.ATOS_SRCHANNEL
                                  and UPPER(SRC_CHNL.ENTITY_CAT)='ATOS_SERVICEREQUEST'
                                  AND UPPER(SRC_CHNL.ATTRIBUTE_CAT)= 'ATOS_SRCHANNEL'
                                  AND SRC_CHNL.LANG = '1033' 
                                  AND SRC_CHNL.ENDDT is null
            
                                  LEFT JOIN dwh_base.CRM_REF STA 
                                  ON STA.REF_CD = Srv_Req.STATECODE
                                  and UPPER(STA.ENTITY_CAT)='ATOS_SERVICEREQUEST'
                                  AND UPPER(STA.ATTRIBUTE_CAT)= 'STATECODE'
                                  AND STA.LANG = '1033' 
                                  AND STA.ENDDT is null
            
                                  LEFT JOIN dwh_base.CRM_REF STS 
                                  ON STS.Ref_cd = Srv_Req.Statuscode
                                  and UPPER(STS.ENTITY_CAT)='ATOS_SERVICEREQUEST'
                                  AND UPPER(STS.ATTRIBUTE_CAT)= 'STATUSCODE'
                                  AND STS.LANG = '1033' 
                                  AND STS.ENDDT is null
            
                                  LEFT JOIN DWH_BASE.CRM_REF SEG 
                                  ON SEG.Ref_cd = SRV_REQ.Atos_retailsegment 
                                  AND UPPER(SEG.ENTITY_CAT) = 'ATOS_SERVICEREQUEST' 
                                  AND UPPER (SEG.ATTRIBUTE_CAT) = UPPER('ATOS_RETAILSEGMENT')
                                  AND SEG.LANG = '1033' AND SEG.ENDDT IS NULL 
            
                                  LEFT JOIN DWH_BASE.CRM_REF PRI 
                                  ON PRI.Ref_cd = SRV_REQ.Atos_priority 
                                  AND Upper(PRI.ENTITY_CAT) = 'ATOS_SERVICEREQUEST' 
                                  AND UPPER (PRI.ATTRIBUTE_CAT) = UPPER('ATOS_PRIORITY')
                                  AND PRI.LANG = '1033' AND PRI.ENDDT IS NULL 
            
                                  LEFT JOIN dwh_base.CRM_REF PREF_COMM_MTHOD 
                                  ON PREF_COMM_MTHOD.REF_CD = SRV_REQ.atos_preferredcommunicationmethod
                                  and UPPER(PREF_COMM_MTHOD.ENTITY_CAT)='ATOS_SERVICEREQUEST'
                                  AND UPPER(PREF_COMM_MTHOD.ATTRIBUTE_CAT)= 'ATOS_PREFERREDCOMMUNICATIONMETHOD'
                                  AND PREF_COMM_MTHOD.LANG = '1033' 
                                  AND PREF_COMM_MTHOD.ENDDT is null
            
                                  LEFT JOIN dwh_base.CRM_REF PREF_COMM_LANG 
                                  ON PREF_COMM_LANG.REF_CD = SRV_REQ.ATOS_PREFERREDLANGUAGE
                                  and UPPER(PREF_COMM_LANG.ENTITY_CAT)='ATOS_SERVICEREQUEST'
                                  AND UPPER(PREF_COMM_LANG.ATTRIBUTE_CAT)= 'ATOS_PREFERREDLANGUAGE'
                                  AND PREF_COMM_LANG.LANG = '1033' 
                                  AND PREF_COMM_LANG.ENDDT is null
            
                                  LEFT JOIN dwh_base.CRM_REF INTG 
                                  ON INTG.REF_CD = SRV_REQ.ATOS_ISINTEGRATIONSUCCESS
                                  and UPPER(INTG.ENTITY_CAT) = 'ATOS_SERVICEREQUEST'
                                  AND UPPER(INTG.ATTRIBUTE_CAT) = 'ATOS_ISINTEGRATIONSUCCESS'
                                  AND INTG.LANG = '1033' 
                                  AND INTG.ENDDT is null
        ) BUS_QRY
    ) HASH_PREP
) FINAL WHERE FK_UP <> 1
