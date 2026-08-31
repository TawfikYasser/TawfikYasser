SELECT DISTINCT
      A.ID AS TRX_KEY
    , A.TLOGID AS TLOG_ID
    , A.CRDDET_ID AS CRD_KEY
    , A.RRN
    , A.PAN
    , A.TRN
    , A.ACCNO AS ACCT_KEY
    , A.TXNCODE AS TRX_TYP_KEY
    , TYP.DESCR AS TRX_TYP
    , A.SUB_TXNCODE AS TRX_SUB_TYP_KEY

    , CASE 
          WHEN A.TXNCODE='00' AND A.SUB_TXNCODE='00' THEN 'Default logic'
          WHEN A.TXNCODE='00' AND A.SUB_TXNCODE='01' THEN 'Transit, Debt Recovery'
          WHEN A.TXNCODE='00' AND A.SUB_TXNCODE='02' THEN 'Incremental Authorisation'
          WHEN A.TXNCODE='00' AND A.SUB_TXNCODE='03' THEN 'Transit, Unknown'
          WHEN A.TXNCODE='00' AND A.SUB_TXNCODE='04' THEN 'Transit, Prefunded'
          WHEN A.TXNCODE='00' AND A.SUB_TXNCODE='05' THEN 'Transit, Real-Time Authorised'
          WHEN A.TXNCODE='00' AND A.SUB_TXNCODE='06' THEN 'Transit, Post-Authorised Aggregated'
          WHEN A.TXNCODE='00' AND A.SUB_TXNCODE='07' THEN 'Transit, Authorised Agg Split Clear'
          WHEN A.TXNCODE='00' AND A.SUB_TXNCODE='08' THEN 'Transit, Other'
          WHEN A.TXNCODE='00' AND A.SUB_TXNCODE='09' THEN 'Transit, Post-Authorised Agg Maestro PayPass'
          WHEN A.TXNCODE='00' AND A.SUB_TXNCODE='10' THEN 'Network Installment'
          WHEN A.TXNCODE='10' AND A.SUB_TXNCODE='00' THEN 'Default logic'
          WHEN A.TXNCODE='10' AND A.SUB_TXNCODE='01' THEN 'VMT Account Funding txn'
          WHEN A.TXNCODE='26' AND A.SUB_TXNCODE='00' THEN 'Default logic'
          WHEN A.TXNCODE='26' AND A.SUB_TXNCODE='01' THEN 'VMT OCT/Fast Funds'
          WHEN A.TXNCODE='93' AND A.SUB_TXNCODE='00' THEN 'Default logic'
          WHEN A.TXNCODE='93' AND A.SUB_TXNCODE='01' THEN 'Purchase Account Status Inquiry'
          WHEN A.TXNCODE='93' AND A.SUB_TXNCODE='02' THEN 'Payment Account Status Inquiry'
          WHEN A.TXNCODE='93' AND A.SUB_TXNCODE='03' THEN 'MoneySend Payment Account Status Inquiry'
          WHEN A.TXNCODE='99' AND A.SUB_TXNCODE='00' THEN 'Purchase Account Status Inquiry'
          WHEN A.TXNCODE='99' AND A.SUB_TXNCODE='01' THEN 'Activation request'
          WHEN A.TXNCODE='99' AND A.SUB_TXNCODE='02' THEN 'Activation code notification'
          WHEN A.TXNCODE='109' AND A.SUB_TXNCODE='01' THEN 'ATC Update'
      END AS TRX_SUB_TYP

    , A.CODE AS APPVL_AUTH_CD
    ,CAST(from_unixtime(CAST(ALLOCDATE AS BIGINT) DIV 1000) AS date) AS APPVL_DT
    ,CAST(
          SUBSTR(CAST(CAST((A.ALLOCTIME +1000000) AS INTEGER) AS VARCHAR(10)),2,2)
          || ':' ||
          SUBSTR(CAST(CAST((A.ALLOCTIME +1000000) AS INTEGER) AS VARCHAR(10)),4,2)
          || ':' ||
          SUBSTR(CAST(CAST((A.ALLOCTIME +1000000) AS INTEGER) AS VARCHAR(10)),6,2)
          AS VARCHAR(8)
      ) AS APPVL_TM

    , A.AMTBILL AS BILL_AMT
    , A.AMTTXN AS AUTH_AMT
    , A.AMTBLK AS BLK_AMT
    , A.ORIGAMTBLK AS ORG_BLK_AMT
    , A.CURBILL AS CURY_KEY

    , CASE
          WHEN A.ACTIONCODE=0 THEN 'Aauthorisation approved'
          WHEN A.ACTIONCODE=1 THEN 'Authorisation denied'
          WHEN A.ACTIONCODE=2 THEN 'Authorisation denied, pickup'
          WHEN A.ACTIONCODE=3 THEN 'File actions'
          WHEN A.ACTIONCODE=4 THEN 'Reversal/chargeback actions'
          WHEN A.ACTIONCODE=5 THEN 'Reconciliation'
          WHEN A.ACTIONCODE=6 THEN 'Administrative'
          WHEN A.ACTIONCODE=7 THEN 'Fee collection'
          WHEN A.ACTIONCODE=8 THEN 'Network management'
          WHEN A.ACTIONCODE=9 THEN 'Error response action'
          ELSE A.ACTIONCODE
      END AS APPVL_DEC_ACTN

    , A.RSPCODE AS RSP_CD_KEY
    , RSP_CD.DESCR AS RSP_CD
    , A.USR AS AUTH_USR
    , A.MRCHCODE AS CRD_ACPT_KEY
    , A.SOURCE AS AUTH_SRC_KEY
    , RSP.DESCR AS AUTH_SRC

    , A.CTXDISPOSE AS AUTH_CD

    , CASE
          WHEN A.CTXDISPOSE=0 THEN 'Authorisation matched'
          WHEN A.CTXDISPOSE=1 THEN 'Authorisation expired'
          WHEN A.CTXDISPOSE=2 THEN 'Authorisation manually deleted'
          WHEN A.CTXDISPOSE=3 THEN 'Authorisation reversed'
          WHEN A.CTXDISPOSE=4 THEN 'Authorisation was partially reversed'
          WHEN A.CTXDISPOSE=5 THEN 'Authorisation was sent'
          WHEN A.CTXDISPOSE=6 THEN 'Authorisation was partially matched'
          ELSE A.CTXDISPOSE
      END AS AUTH_STS

    ,CURRENT_TIMESTAMP AS INS_DTTM
    ,CAST(from_unixtime(CAST(DISPDATE AS BIGINT) DIV 1000) AS date) AS DIS_DT

    , CAST(CURRENT_TIMESTAMP AS STRING) AS TEC_INSRT_DTTM
    , CAST(CURRENT_TIMESTAMP AS STRING) AS TEC_UPD_DTTM
    , NULL AS DR_DTTM
    , NULL AS DR_FLG

FROM ${stg_schema}.APRVLHIST A

LEFT JOIN
(
    SELECT 
        RSP_CD.*,
        SUBSTR(RSP_CD.descrtype,2,1) AS ACTIONCODE
    FROM ${stg_schema}.NUMDESCR RSP_CD
    WHERE RSP_CD.descrtype IN ('r0','r1','r2','r9')
      AND LANG='EN'
) RSP_CD
    ON A.RSPCODE = RSP_CD.ID
   AND A.ACTIONCODE = RSP_CD.ACTIONCODE

LEFT JOIN ${stg_schema}.STRDESCR RSP
    ON TRIM(A.SOURCE)=TRIM(RSP.TAG)
   AND RSP.DESCRTYPE='rspsrc'

LEFT JOIN ${stg_schema}.NUMDESCR TYP
    ON A.TXNCODE=TYP.ID
   AND TYP.DESCRTYPE='tx'

qualify row_number() over (partition by A.ID order by ALLOCDATE desc, a.TEC_INSRT_DTTM desc) = 1
