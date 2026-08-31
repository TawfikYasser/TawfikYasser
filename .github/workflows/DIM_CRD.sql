SELECT COUNT(*) FROM (
    SELECT hash_prep.*,
        CASE WHEN HASH_PREP.HASH_KEY = FIRST_VALUE(HASH_PREP.HASH_KEY) OVER(
            PARTITION BY HASH_PREP.CRD_KEY ORDER BY HASH_PREP.strt_dt ASC
            ROWS BETWEEN 1 PRECEDING AND 1 PRECEDING)
        THEN 1 ELSE 0 END AS FK_UP
    FROM (
        SELECT BUS_QRY.*,
            sha2(
coalesce(Prnt_Crd_key, '') ||
coalesce(CUST_KEY, '') ||
coalesce(PRI_ACCT_KEY, '') ||
coalesce(ACCT_NO, '') ||
coalesce(CRD_STS_KEY, '') ||
coalesce(CRD_STS, '') ||
coalesce(MOD_USR, '') ||
coalesce(MOD_RSN, '') ||
coalesce(CRD_ACCT_STS, '') ||
coalesce(CRD_SEQ_KEY, '') ||
coalesce(PHY_FLG, '') ||
coalesce(CRD_PHY_DESCR, '') ||
coalesce(LST_DLVRY_STS, '') ||
coalesce(PRI_FLG, '') ||
coalesce(PAN, '') ||
coalesce(PAN_DISPLAY, '') ||
coalesce(VPAN, '') ||
coalesce(SCHEME_KEY, '') ||
coalesce(SVC_CD, '') ||
coalesce(CRD_TYP, '') ||
coalesce(AUTH_RULE, '') ||
coalesce(PIN_VAL_METH, '') ||
coalesce(ACCT_CLS, '') ||
coalesce(CRD_PRD_KEY, '') ||
coalesce(CRD_PRD_CD, '') ||
coalesce(CRD_PRD_DESCR, '') ||
coalesce(BIN, '') ||
coalesce(CRD_CLS, '') ||
coalesce(TTL, '') ||
coalesce(FST_NM, '') ||
coalesce(LST_NM, '') ||
coalesce(FULL_NM, '') ||
coalesce(RLTN_WZ_PRI, '') ||
coalesce(EMBOSS_NM, '') ||
coalesce(CORR_ADDR, '') ||
coalesce(DLV_METHOD, '') ||
coalesce(NOTIFY_OPTIONS, '') ||
coalesce(CHNL_KEY, '') ||
coalesce(LANG_CD, '') ||
coalesce(PRIO, '') ||
coalesce(TEC_STS, '')
            , 256) AS HASH_KEY
        FROM (
            
            
            SELECT
                CRD.ID					AS	CRD_KEY			-- PK
            ,CASE WHEN Crd_supp.add_crddet_id IS NOT NULL THEN Crd_supp.crddet_id   ELSE NULL  END  Prnt_Crd_key
            ,COALESCE(Cust_dtls.Custcode,CRD.Cust_id_num,'-1')		AS	CUST_KEY
            ,ACCT.ID                AS  PRI_ACCT_KEY
            ,ACCT.ACCNO				AS	ACCT_NO
            ,coalesce(CRD_STS.STATCODE,CRD.STATCODE) AS	CRD_STS_KEY
            ,CRD_DESCR.DESCR		AS	CRD_STS
            ,CRD_STS.MOD_USR
            ,CRD_STS.MOD_RSN
            ,CRD_STS.MOD_DTTM
            ,ACCTSTS.DESCR			AS	CRD_ACCT_STS			
            ,SEQNO					AS	CRD_SEQ_KEY			
            ,CRDAUTH_PARAMS         AS	PHY_FLG	
            ,crd_phy.DESCR          AS  CRD_PHY_DESCR		
            ,'Y'					AS	LST_DLVRY_STS					
            ,CASE WHEN Crd_supp.add_crddet_id IS NOT NULL THEN  'S' ELSE 'P'  END   AS	PRI_FLG
            ,CRD.DATE_CREATED       AS   ISSUE_DT
            ,cast(Case
                When XX.DATE_ACTIVATION = '2263-08-31' Then Null
                Else XX.DATE_ACTIVATION 
                End  as date )AS ACTV_DT
            ,null as DLVRY_DT	
            ,CRD.PAN
            ,CRD.PAN_DISPLAY
            ,CRD.ISS_HOST_CRDREF	AS	VPAN
            ,cast(
                Case
                When CRD.EXPDATE = '2263-08-31' Then null
                else CRD.EXPDATE	
                End as date) AS EXP_DT
            ,cast(Case
                When CRD.OLD_EXPDATE = '2263-08-31' Then null
                else CRD.OLD_EXPDATE 
                End as date) AS PREV_EXP_DT
            ,cast(Case
                When CRD.EFFDATE  = '2263-08-31' Then null
                Else CRD.EFFDATE   
                End as date ) AS EFF_DT
            ,FF.SCHEME				AS	SCHEME_KEY	
            ,CRD.SVCCODE			AS	SVC_CD		
            ,CRD_TYP.DESCR			AS	CRD_TYP
            ,CRD_AUTH.DESCR			AS	AUTH_RULE
            ,CRD_PIN.DESCR			AS	PIN_VAL_METH
            ,CRD.CLASSID			AS	ACCT_CLS
            ,CRD.CRDPRODUCT_ID		AS	CRD_PRD_KEY
            ,PRD.CRDPRODUCT			AS	CRD_PRD_CD
            ,PRD.PROD_DSCR			AS	CRD_PRD_DESCR
            ,FF.IID					AS	BIN			
            ,CASE 
                WHEN PRD.PROD_DSCR LIKE 'PP%' THEN 'PP'
                WHEN PRD.PROD_DSCR LIKE 'DB%' THEN 'DB'
                ELSE 'CC' 
                END AS CRD_CLS	
            ,CRD.TITLE				AS	TTL
            ,CRD.FIRSTNAME			AS	FST_NM
            ,CRD.LASTNAME			AS	LST_NM
            ,CRD.FIRSTNAME|| ' ' ||CRD.LASTNAME AS FULL_NM	
            ,CRD.KINSHIP			AS	RLTN_WZ_PRI
            ,CRD.DATE_BIRTH     	AS	DOB
            ,CRD.EMBOSSNAME			AS	EMBOSS_NM
            ,CASE 
                WHEN CRD.ADDRIND ='0' THEN 'HOME' 
                WHEN CRD.ADDRIND ='1' THEN 'Over-ride'
                WHEN CRD.ADDRIND ='2' THEN 'Work'
                WHEN CRD.ADDRIND ='3' THEN 'P.O. Box' ELSE	CRD.ADDRIND END	AS	CORR_ADDR
            ,CRD.DLV_METHOD
            ,CRD.NOTIFY_OPTIONS
            ,CRD.BRANCH_ID			AS	CHNL_KEY
            ,CRD.LANG				AS	LANG_CD	
            ,CAST(CRD.DATE_STATCHG  AS DATE)   AS LST_CHG_STS_DT
            ,(CAST(regexp_replace(CRD.LAST_ACTIVITY,'(\\d{4})(\\d{2})(\\d{2})(\\d{2})(\\d{2})(\\d{2})(\\d{3})','$1-$2-$3 $4:$5:$6.$7') as date))  AS LST_ACT_DT 
            ,CRD_ACCT.priority      AS  PRIO
            ,Lst_Prntd_Dt
            ,CASE WHEN CRD.op = 'd' THEN 'Deleted' ELSE 'Active' END as TEC_STS
            ,Calendar_dt            AS  STRT_Dt
            ,NULL 					AS  END_DT
                
            FROM
                
            (
                SELECT *
                FROM Dwh_base.calendar_base
                WHERE  calendar_dt BETWEEN '${strt_dt}' AND '${end_dt}'
            )A
            
            LEFT OUTER JOIN
            (
            
                SELECT 
                    branch_id,crdproduct_id,classid,pan,seqno,expdate,old_expdate,effdate,cyclen,cycbegin,amtauth,amtrem,blkamt
                ,batch,crdsmade,pinsmade,cvv,pvki,pvv,lang,title,firstname,lastname,discret,usrdata, svccode ,
                aci,offauth,cust_id_num,kinship,date_statchg,old_cvv,renew,corp,date_birth,offlim,cvc,oldcvc,embossname,additionalno,
                date_created,applno,atc,old_atc,fallbackcnt,old_fallbackcnt,addrind ,scriptstat,oldscrstat,dlv_method,cscs,oldcscs,
                crdprogram_id,crddesign_id,deliv_brncode,old_crdproduct_id,old_statcode,crdauth_params,preauth_blk,
                preauth_blk_old,preauth_unclr,preauth_unclr_old,preauth_blk_lim,preauth_tot_lim,id,pan_display,iss_host_code,
                iss_host_crdref,l10n_title,l10n_firstname,l10n_lastname,cat_params,accdet_id,custdet_id,cat_issrisk_id,
                cat_isscomm_id,notify_options,last_activity,ctta,ctta_old,csta,csta_old,cttaul,cttaul_old,preauth_amtcrpt,
                preauth_amtcrpt_old,preauth_tlogid,preauth_tlogid_old,preauth_txnflags,preauth_txnflags_old,ext_custnum,
                crdactstat,old_crdactstat,pinstatus_id,pinstatus_old_id,bin_flags,emvcrdseqno,emvcrdseqno_old,additionaltype,Statcode,op
                ,CASE
                    WHEN  rn = 1 THEN 
                    CASE WHEN  cast(date_created AS date) < strt_dt THEN   cast(date_created AS date)   ELSE  strt_dt  END 
                    ELSE  strt_dt 
                    END  strt_dt
                ,end_dt
                
                FROM  
                (
                SELECT
                branch_id,crdproduct_id,classid,pan,seqno,expdate,old_expdate,effdate,cyclen,cycbegin,amtauth,amtrem,blkamt,batch,crdsmade,pinsmade,cvv,pvki,pvv,lang,title,firstname,lastname,discret,usrdata,  svccode1 AS svccode ,
                aci,offauth,cust_id_num,kinship,date_statchg,old_cvv,renew,corp,date_birth,offlim,cvc,oldcvc,embossname,additionalno,
                date_created,applno,atc,old_atc,fallbackcnt,old_fallbackcnt,addrind1 AS addrind ,scriptstat,oldscrstat,dlv_method,cscs,oldcscs,
                crdprogram_id,crddesign_id,deliv_brncode,old_crdproduct_id,old_statcode,crdauth_params,preauth_blk,
                preauth_blk_old,preauth_unclr,preauth_unclr_old,preauth_blk_lim,preauth_tot_lim,id,pan_display,iss_host_code,
                iss_host_crdref,l10n_title,l10n_firstname,l10n_lastname,cat_params,accdet_id,custdet_id,cat_issrisk_id,
                cat_isscomm_id,notify_options,last_activity,ctta,ctta_old,csta,csta_old,cttaul,cttaul_old,preauth_amtcrpt,preauth_amtcrpt_old,preauth_tlogid,
                preauth_tlogid_old,preauth_txnflags,preauth_txnflags_old,ext_custnum,crdactstat,old_crdactstat,pinstatus_id,pinstatus_old_id,bin_flags,emvcrdseqno,
                emvcrdseqno_old,additionaltype,Statcode, op, strt_dt
                ,COALESCE(
                        DATE_ADD(
                            LEAD(strt_dt) OVER (PARTITION BY id ORDER BY strt_dt),-1
                        ),DATE '2999-12-31'
                        ) AS End_Dt
                ,row_number() over(PARTITION BY id  ORDER BY  strt_dt ASC )  rn
                FROM  
                
                (
                    SELECT
                    verno_ctx,branch_id,crdproduct_id,classid,pan,seqno,cyclen,cycbegin,amtauth,amtrem,blkamt,batch,crdsmade,pinsmade,
                    cvv,pvki,pvv,lang,title,firstname,lastname,discret,usrdata, CAST(svccode AS string  ) svccode1,aci,offauth,cust_id_num,kinship,
                    old_cvv,renew,corp,offlim,cvc,oldcvc,embossname,additionalno,applno,atc,old_atc,fallbackcnt,old_fallbackcnt,
                    CAST (addrind  AS string ) AS addrind1,scriptstat,oldscrstat,dlv_method,
                    cscs,oldcscs,crdprogram_id,crddesign_id,deliv_brncode,old_crdproduct_id,old_statcode,SUBSTR(CRDAUTH_PARAMS,3,1) as CRDAUTH_PARAMS ,preauth_blk,preauth_blk_old,
                    preauth_unclr,preauth_unclr_old,preauth_blk_lim,preauth_tot_lim,id,pan_display,iss_host_code,iss_host_crdref,l10n_title,l10n_firstname,l10n_lastname,cat_params,
                    accdet_id,custdet_id,cat_issrisk_id,cat_isscomm_id,notify_options,ctta,ctta_old,csta,csta_old,cttaul,cttaul_old,preauth_amtcrpt,preauth_amtcrpt_old,
                    preauth_tlogid,preauth_tlogid_old,preauth_txnflags,preauth_txnflags_old,ext_custnum,crdactstat,old_crdactstat,pinstatus_id,pinstatus_old_id,bin_flags,
                    emvcrdseqno,emvcrdseqno_old,additionaltype,Statcode,op
                    ,CAST(from_unixtime(CAST(date_statchg AS BIGINT) DIV 1000) AS date) as date_statchg
                    ,CAST(from_unixtime(CAST(date_birth AS BIGINT) DIV 1000) AS date) as date_birth
                    ,CAST(from_unixtime(CAST(effdate AS BIGINT) DIV 1000) AS date) as effdate
                    ,CAST(from_unixtime(CAST(old_expdate AS BIGINT) DIV 1000) AS date) as old_expdate
                    ,CAST(from_unixtime(CAST(Expdate AS BIGINT) DIV 1000) AS date) as Expdate
                    ,CAST(from_unixtime(CAST(date_created AS BIGINT) DIV 1000) AS date) as date_created
                    ,from_unixtime(unix_timestamp(SUBSTRING(last_activity, 1, 8), 'yyyyMMdd'), 'yyyy-MM-dd') as last_activity
                    ,CAST(from_unixtime(CAST(ts_ms AS BIGINT) DIV 1000) AS date) strt_dt
                    ,row_number() over(PARTITION BY id , CAST(from_unixtime(CAST(ts_ms AS BIGINT) DIV 1000) AS date) ORDER BY  ts_ms desc )  rnk
            
                    FROM ${stg_schema}.CRDDET
                
                )crd_0
                WHERE rnk =1
                
                ) crd_00
                
            )crd
            ON a.calendar_dt BETWEEN crd.strt_dt  AND crd.end_dt
            
            
            LEFT JOIN 
            (
                SELECT * 
                FROM ${stg_schema}.additionals 
                    
                -- Some row_numbr  and Qualify may  need to be added  in case of additional cards changes have been applied in the future 
            
            )Crd_supp  
            ON Crd_supp.add_crddet_id = CRD.id 
            
            LEFT JOIN
            (
                SELECT 
                id,netchgexp,netchgkill,netchgkdate,crddet_id,design_ref,usrdata1,usrdata2,usrdata3,usrdata4,usrdata5,cat_issfee_id,cat_isscycfee_id,date_cycfee_moved,cycbegin_cntrl,
                date_activation,Lst_Prntd_Dt,cat_crdiss_id,memo,crdplstctyp_id
                ,CASE
                    WHEN  rn = 1 THEN 
                    CASE WHEN  cast(date_activation AS date) < strt_dt THEN  cast(date_activation AS date)  ELSE  strt_dt  END 
                    ELSE  strt_dt 
                    END  strt_dt
                ,end_dt
                
                FROM  
                (
                    SELECT
                    id,netchgexp,netchgkill,netchgkdate,crddet_id,design_ref,usrdata1,usrdata2,usrdata3,usrdata4,usrdata5,cat_issfee_id,cat_isscycfee_id,date_cycfee_moved,cycbegin_cntrl,
                    date_activation,Lst_Prntd_Dt,cat_crdiss_id,memo,crdplstctyp_id,strt_dt
                    ,COALESCE(
                        DATE_ADD(
                            LEAD(strt_dt) OVER (PARTITION BY id ORDER BY strt_dt),-1
                        ),DATE '2999-12-31'
                        ) AS End_Dt
                    ,row_number() over(PARTITION BY id   ORDER BY  strt_dt ASC )  rn
                        
                    FROM
                    (
                        SELECT
                        verno_ctx,id,netchgexp,netchgkill,netchgkdate,crddet_id,design_ref,
                        usrdata1,usrdata2,usrdata3,usrdata4,usrdata5,cat_issfee_id,cat_isscycfee_id,
                        date_cycfee_moved,cycbegin_cntrl,cast(from_unixtime(cast( DATELSTISSUED as bigint) div 1000) as TIMESTAMP) as Lst_Prntd_Dt,cat_crdiss_id,memo,crdplstctyp_id
                        ,CAST(from_unixtime(CAST(DATE_ACTIVATION AS BIGINT) DIV 1000) AS date) as DATE_ACTIVATION
                        ,CAST(from_unixtime(CAST(ts_ms AS BIGINT) DIV 1000) AS date) strt_dt
                        ,ROW_NUMBER ()over(PARTITION BY id , cast(from_unixtime(cast(CAST(ts_ms as BIGINT) / 1000 as int), "yyyy-MM-dd") AS DATE)  ORDER BY ts_ms DESC  ) rnk
                        
                        FROM ${stg_schema}.CRDDET_X
                        
                        
                    )XX_0
                    WHERE rnk=1
                )CRDDET_X
            )XX
            ON CRD.ID = XX.CRDDET_ID
            AND
            a.calendar_dt BETWEEN XX.strt_dt  AND XX.end_dt   -- updated BY walied
            
                
            INNER JOIN
            (
                
                SELECT Prod_cd 
                ,ID
                ,PROD_DSCR
                ,crdformat_id 
                ,CRDPRODUCT
                FROM
                (
                    SELECT crdproduct  Prod_cd  ,CRDPRODUCT , ID , descr PROD_DSCR ,crdformat_id 
                    , row_number() over(PARTITION BY ID ORDER BY ts_ms desc ) rn
                    FROM ${stg_schema}.CRDPRODUCT  
                ) prod_0
                    WHERE  rn=1
            )PRD
            ON CRD.CRDPRODUCT_ID = PRD.ID
                
            LEFT JOIN
            (	
                SELECT 
                id,accno,currcode,branch_id,typecode,classid,statcode,vipflag,blkamt,avlbal,clrbal,
                unclrbal,credit_limit,preauth_blk,
                preauth_unclr,preauth_exp_blk,preauth_exp_unclr,cat_params,custdet_id,
                avlbal_unsent,blkamt_unsent,unclrcredit,unclrcredit_unsent,shdwauthov,
                unclrlocredit,dival,diref,diverno,cycle_begindate,cycle_enddate,
                lastloaddate,
                CASE
                    WHEN r = 1 THEN 
                    CASE WHEN  CRD_DT_CRTED < STRT_DT  THEN CRD_DT_CRTED  ELSE  STRT_DT END   
                    ELSE STRT_DT  
                END STRT_DT ,
                end_dt
                    
                FROM 
                ( 
                    SELECT
                    accno,currcode,branch_id,typecode,classid,statcode,vipflag,blkamt,avlbal,clrbal,unclrbal,credit_limit,preauth_blk,
                    preauth_unclr,preauth_exp_blk,preauth_exp_unclr,cat_params,id,custdet_id,avlbal_unsent,blkamt_unsent,unclrcredit,unclrcredit_unsent,shdwauthov,
                    unclrlocredit,dival,diref,diverno,cycle_begindate,cycle_enddate,lastloaddate, strt_dt
                    ,COALESCE(
                        DATE_ADD(
                            LEAD(strt_dt) OVER (PARTITION BY id ORDER BY strt_dt),-1
                        ),DATE '2999-12-31'
                        ) AS End_Dt
                    ,row_number() over(PARTITION BY id   ORDER BY  strt_dt ASC ) r
                    ,CRD_DT_CRTED
                    FROM
                    (
                        SELECT
                        accno,currcode,branch_id,typecode,classid,statcode,vipflag,blkamt,avlbal,clrbal,
                        unclrbal,credit_limit,preauth_blk,preauth_unclr,preauth_exp_blk,preauth_exp_unclr,
                        cat_params,id,custdet_id,avlbal_unsent,blkamt_unsent,unclrcredit,unclrcredit_unsent,shdwauthov,
                        unclrlocredit,dival,diref,diverno,cycle_begindate,cycle_enddate,lastloaddate ,CRD_DT_CRTED,
                        cast(from_unixtime(cast(CAST(ts_ms as BIGINT) / 1000 as int), "yyyy-MM-dd") AS DATE) as strt_dt,
                        ROW_NUMBER() OVER(PARTITION BY  id , cast(from_unixtime(cast(CAST(ts_ms as BIGINT) / 1000 as int), "yyyy-MM-dd") AS DATE)  ORDER BY ts_ms desc) RN 
                        
                        
                        FROM ${stg_schema}.ACCDET 
                        
                        LEFT OUTER JOIN  
                        (
                                SELECT
                                accdet_id,
                                MIN(CAST(from_unixtime(CAST(date_created AS BIGINT) DIV 1000) AS date))  CRD_DT_CRTED
                            
                                FROM ${stg_schema}.CRDDET
                                GROUP BY accdet_id
                        )B 
                        ON B.accdet_id = ACCDET.ID 
                    
                    ) ACCT_0
                    WHERE RN=1
                ) acct_oo1		  
            )ACCT
            ON CRD.ACCDET_ID = ACCT.ID
            AND a.calendar_dt BETWEEN ACCT.strt_dt  AND ACCT.end_dt
            
                
            LEFT JOIN
            (
                SELECT * , ROW_NUMBER() OVER(PARTITION BY STATCODE  ORDER BY  ts_ms DESC  ) RN
                FROM  ${stg_schema}.ACCSTATUS
            )ACCTSTS
            ON ACCT.STATCODE = ACCTSTS.STATCODE
            AND ACCTSTS.RN=1
                
            
            LEFT JOIN
            (
                SELECT *  , row_number()over(PARTITION BY  id ORDER BY ts_ms DESC ) rn
                FROM ${stg_schema}.CRDFORMAT
            ) FF
            ON PRD.CRDFORMAT_ID = FF.ID
            AND ff.rn=1
                
            LEFT JOIN 
            (
                select * 
                ,COALESCE(date_add(last_value(strt_dt) over(PARTITION BY CRDDET_ID ORDER BY MOD_DTTM ASC ROWS BETWEEN 1 FOLLOWING AND 1 following ) ,-1)  , date '2999-12-31') end_dt
                from 
                (
                    
                    select 
                    CRDDET_ID
                    ,new_statcode AS statcode
                    ,DATE_FORMAT(
                        CAST(
                        CONCAT(CAST(from_unixtime(CAST(date_set AS BIGINT) DIV 1000) AS date) ,' ',SUBSTR(time_set, 1, 2), ':',SUBSTR(time_set, 3, 2), ':',SUBSTR(time_set, 5, 2)) AS TIMESTAMP
                        ),'yyyy-MM-dd HH:mm:ss') AS  mod_dttm
                    ,who_set  AS MOD_USR
                    ,why_set  AS MOD_RSN
                    ,CAST(from_unixtime(CAST(date_set AS BIGINT) DIV 1000) AS date) as strt_dt
                    ,row_number() over(PARTITION BY CRDDET_ID, CAST(from_unixtime(CAST(date_set AS BIGINT) DIV 1000) AS date) ORDER BY time_set DESC ) RN
            
                    
                    FROM stg_cor.CDSTHST
                )HIST
                where RN =1
                    
            )CRD_STS
            on CRD_STS.CRDDET_ID = CRD.ID
            AND a.calendar_dt BETWEEN CRD_STS.strt_dt AND CRD_STS.end_dt
            
            LEFT JOIN
                
            (
                    SELECT
                    STATCODE,		
                    DESCR,
                    row_number() over(PARTITION BY statcode, CAST(from_unixtime(CAST(ts_ms AS BIGINT) DIV 1000) AS date)  ORDER BY ts_ms DESC ) RN
                    FROM ${stg_schema}.CRDSTATUS
            )CRD_DESCR
            ON CRD_DESCR.STATCODE = coalesce(CRD_STS.STATCODE,crd.Statcode)
            AND CRD_DESCR.RN = 1
                
            LEFT JOIN ${stg_schema}.NUMDESCR CRD_TYP
            ON SUBSTR(CRD.SVCCODE,1,1)= CAST(CRD_TYP.ID AS string)
            AND CRD_TYP.DESCRTYPE='scpos1'
                
            LEFT JOIN ${stg_schema}.NUMDESCR CRD_AUTH
            ON SUBSTR(CRD.SVCCODE,2,1)= CAST(CRD_AUTH.ID AS string)
            AND CRD_AUTH.DESCRTYPE='scpos2'
                
            LEFT JOIN ${stg_schema}.NUMDESCR CRD_PIN
            ON SUBSTR(CRD.SVCCODE,2,1)= CAST(CRD_PIN.ID AS string)
            AND CRD_PIN.DESCRTYPE='scpos3'
            
            
            LEFT JOIN 
            (
                select * 
                from 
                (
                    
                    select 
                    accdet_id
                    ,priority
                    ,row_number() over(PARTITION BY accdet_id, CAST(from_unixtime(CAST(ts_ms AS BIGINT) DIV 1000) AS date) ORDER BY ts_ms DESC ) RNk
                    
                    FROM stg_cor.crdacc
                )CRD_ACCT
                where RNk =1
                    
            )CRD_ACCT
            on CRD_ACCT.accdet_id = CRD.accdet_id
            
            
            
            LEFT JOIN 
            (
                select * 
            
                from 
                (
                    
                    select 
                    tag
                    ,descr
                    ,insert_date as strt_dt
                    ,row_number() over(PARTITION By tag ORDER BY tec_insrt_dttm DESC ) RNk
            
                    
                    FROM stg_cor.strdescr
                    where descrtype = 'cdap3'
                )crd_typ
                where RNk =1
                    
            )crd_phy
            on crd_phy.tag = crd.Crdauth_params
            
            
            
            
            LEFT JOIN 
            (
                select * 
                ,COALESCE(
                        DATE_ADD(
                            LEAD(strt_dt) OVER (PARTITION BY id ORDER BY strt_dt),-1
                        ),DATE '2999-12-31'
                        ) AS End_Dt
                from 
                (
                    
                    select 
                    ID
                    ,custcode
                    ,CAST(from_unixtime(CAST(ts_ms AS BIGINT) DIV 1000) AS date) strt_dt
                    ,row_number() over(PARTITION BY id , CAST(from_unixtime(CAST(ts_ms AS BIGINT) DIV 1000) AS date) ORDER BY  ts_ms desc )  rnk
            
                    
                    FROM stg_cor.custdet
                )HIST
                where RNK =1
                    
            )CUST_DTLS
            on CUST_DTLS.ID = CRD.CUSTDET_ID
            AND A.calendar_dt BETWEEN CUST_DTLS.strt_dt AND CUST_DTLS.end_dt
        ) BUS_QRY
    ) HASH_PREP
) FINAL WHERE FK_UP <> 1
