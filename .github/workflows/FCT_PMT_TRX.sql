
SELECT A.*,
sha2(coalesce(rsn_desc,'') || coalesce(ordr_prty_rsdncy,'') || coalesce(evnt_dttm,'') || coalesce(trx_dt,'') 
|| coalesce(trx_book_dt,'') || coalesce(trx_type_cd,'') || coalesce(trx_type_desc,'') || coalesce(trx_sub_type_cd,'') 
|| coalesce(context_operation,'') || coalesce(context_transactiontype,'') || coalesce(trx_sts_cd,'') || coalesce(trx_sts_desc,'') 
|| coalesce(dbt_bk_cd,'') || coalesce(sts_dttm,'') || coalesce(sts_dt,'') || coalesce(sndr,'') 
|| coalesce(sndr_ref_incm,'') || coalesce(orign_src,'') || coalesce(pmt_drctn,'') || coalesce(cntrb_ind,'') 
|| coalesce(out_chnl,'') || coalesce(incm_msg_type,'') || coalesce(dbt_acct_key,'') || coalesce(dbt_mn_acct_cury_key,'') 
|| coalesce(dbt_val_dt,'') || coalesce(trx_cury_key,'') || coalesce(trx_amt,'') || coalesce(trx_amt_lcl,'') 
|| coalesce(crdt_acct_key,'') || coalesce(req_exec_dt,'') || coalesce(crdt_val_dt,'') || coalesce(crdt_mn_acct_cury_key,'') 
|| coalesce(chrg_type,'') || coalesce(crdt_amt,'') || coalesce(dbt_amt,'') || coalesce(dbt_prty_key,'') 
|| coalesce(dbt_prty_ln_1,'') || coalesce(dbt_prty_ln_2,'') || coalesce(crdt_prty_ln_1,'') || coalesce(post_amnt_dbt_lcy,'') 
|| coalesce(post_amnt_crdt_lcy,'') || coalesce(cury_er_rt,'') || coalesce(file_ref_incom,'') || coalesce(inpter_usr_id,'') 
|| coalesce(apprv_usr_id_1,'') || coalesce(apprv_usr_id_2,'') || coalesce(trx_entry_dt,'') || coalesce(trx_apprv_dt,'') 
|| coalesce(rtrn_pmt_ref,'') || coalesce(dbt_acct_cury_key,'') || coalesce(dbt_acct_type_cd,'') || coalesce(dbt_acct_sts,'') 
|| coalesce(dbt_acct_iban,'') || coalesce(dbt_acct_ctgy_cd,'') || coalesce(dbt_cust_key,'') || coalesce(dbt_cust_nm,'') 
|| coalesce(dbt_cust_addr,'') || coalesce(dbt_cust_sctr_key,'') || coalesce(dbt_idntf_cd,'') || coalesce(dbt_cust_cntry_key,'') 
|| coalesce(crdt_acct_cury_key,'') || coalesce(crdt_acct_type_cd,'') || coalesce(crdt_acct_sts,'') || coalesce(crdt_acct_iban,'') 
|| coalesce(crdt_acct_ctgy_cd,'') || coalesce(crdt_cust_key,'') || coalesce(crdt_cust_nm,'') || coalesce(crdt_cust_addr,'') 
|| coalesce(crdt_cust_sctr_key,'') || coalesce(crdt_cust_cntry_key,'') || coalesce(beneficiary_name,'') || coalesce(beneficiary_account_num,'') 
|| coalesce(beneficiary_address,'') || coalesce(beneficiary_country,'') || coalesce(beneficiary_bic,'') || coalesce(receiver_account_num,'') 
|| coalesce(sender_bic,'') || coalesce(sender_account,'') || coalesce(sender_name,'') || coalesce(sender_country,'') 
|| coalesce(broker_bic,'') || coalesce(fees_1_chrg_party,'') || coalesce(fees_1_type,'') || coalesce(fees_1_desc,'') 
|| coalesce(fees_1_amount,'') || coalesce(fees_1_currency,'') || coalesce(fees_1_amount_lccy,'') || coalesce(fees_1_pl_account,'') 
|| coalesce(fees_1_pl_currency,'') || coalesce(fees_2_chrg_party,'') || coalesce(fees_2_type,'') || coalesce(fees_2_desc,'') 
|| coalesce(fees_2_amount,'') || coalesce(fees_2_currency,'') || coalesce(fees_2_amount_lccy,'') || coalesce(fees_2_pl_account,'') 
|| coalesce(fees_2_pl_currency,'') || coalesce(additionalinfline,'') || coalesce(additionalenricheddata,'') || coalesce(reversalentryid,'') 
|| coalesce(cast(reversed as string),''),256) HashCode
  ,cast(current_timestamp as string) as tec_insrt_dttm		
	,cast(current_timestamp as string) as tec_upd_dttm		
	,null as dr_dttm		
	,null as dr_flg
from (
SELECT distinct
Ftnumber  FT_KEY ,
CASE 
 WHEN reasondescription in ('','null',null) THEN 'NA' 
 ELSE reasondescription
END AS rsn_desc    ,--reasondescription,
orderingpartyresidency as ORDR_PRTY_RSDNCY,
from_unixtime(cast(CAST(k_processingtime as BIGINT) / 1000 as int),"yyyy-MM-dd HH:mm:ss") EVNT_DTTM,
from_unixtime(unix_timestamp(Case When context_cobdate in ('','null' ) OR context_cobdate IS NULL   Then context_bankingdate Else context_cobdate END ,'yyyyMMdd'),'yyyy-MM-dd') AS  TRX_DT ,  -- cob_dt,
  
from_unixtime(unix_timestamp(bookdate ,'yyyyMMdd'),'yyyy-MM-dd') AS  TRX_BOOK_DT,
CASE
	WHEN Originatingsource IN('POA', 'OE') and Paymentdirection = 'B' and Outputchannel = 'LEDGER' THEN 1
	WHEN Originatingsource IN('POA', 'OE') and Paymentdirection = 'O' and Outputchannel = 'PEG' THEN 2
	WHEN Originatingsource IN('PEG', 'POA', 'OE') and Paymentdirection = 'O'and Outputchannel = 'NOSTRO' THEN 3
	WHEN Originatingsource IN('EGACHCT', 'POA', 'OE') and Paymentdirection = 'O'and Outputchannel = 'EGACHCT' THEN 4
	WHEN Originatingsource IN('STO')and Paymentdirection = 'O'and Outputchannel = 'PEG' THEN 5
	WHEN Originatingsource IN('STO')and Paymentdirection = 'O'and Outputchannel = 'EGACHCT' THEN 6
	WHEN Originatingsource IN('EGACHCT') and Paymentdirection IN('B', 'I') THEN 7
	WHEN Originatingsource IN('PEG') and Paymentdirection = 'I' THEN 8
	WHEN Originatingsource IN('SWIFT') and Paymentdirection = 'I' THEN 9
	WHEN Originatingsource IN('STO') and Paymentdirection = 'O' and Outputchannel = 'NOSTRO' THEN 10
	WHEN Originatingsource IN('STO') and Paymentdirection = 'B' THEN 11
ELSE -1
END   trx_type_cd ,
--TRNX_TYPE_CD ,
CASE
	WHEN Originatingsource IN('POA', 'OE') and Paymentdirection = 'B' and Outputchannel = 'LEDGER' THEN 'Internal_Payment'
	WHEN Originatingsource IN('STO')and Paymentdirection = 'B' THEN 'Standing_Order_Internal_Payment'
	WHEN Originatingsource IN('PEG', 'POA', 'OE') and Paymentdirection = 'O' and Outputchannel = 'PEG' THEN 'Domestic_Swift_Payment_OUT'
	WHEN Originatingsource IN('POA', 'OE') and Paymentdirection = 'O' and Outputchannel = 'NOSTRO' THEN 'International_Swift_Payment_OUT'
	WHEN Originatingsource IN('EGACHCT', 'POA', 'OE') and Paymentdirection = 'O' and Outputchannel = 'EGACHCT' THEN 'ACH_Payment_OUT'
	WHEN Originatingsource IN('STO') and Paymentdirection = 'O' and Outputchannel = 'PEG' THEN 'Standing_Order_Domestic_SWIFT_Out'
	WHEN Originatingsource IN('STO')and Paymentdirection = 'O' and Outputchannel = 'EGACHCT' THEN 'Standing_Order_ACH'
	WHEN Originatingsource IN('STO') and Paymentdirection = 'O' and Outputchannel = 'NOSTRO' THEN 'Standing_Order_International_Swift_Payment_OUT'
	WHEN Originatingsource IN('EGACHCT') and Paymentdirection IN('B', 'I') THEN 'ACH_Payment_IN'
	WHEN Originatingsource IN('PEG') and Paymentdirection = 'I' THEN 'Domestic_Swift_Payment_IN'
	WHEN Originatingsource IN('SWIFT') and Paymentdirection = 'I' THEN 'International_Swift_Payment_IN'
	ELSE 'UnKown'
END 
trx_type_desc, -- TRNX_TYPE_DESC,
CASE
	WHEN incomingmessagetype = 'CCARDS' THEN 'Card Payment'
	WHEN incomingmessagetype in ('103', '202') THEN 'SWIFT Payment'
	WHEN incomingmessagetype = 'PLSTO' THEN 'Standing Order Suspense to PL'
	WHEN incomingmessagetype = 'PLFSD' THEN 'FSD Settlement with Customer Share (Stamp Duty)'
	WHEN incomingmessagetype = 'TRSYSTLMNT' THEN 'Treassury Payment'
	WHEN incomingmessagetype = 'BILLPAY' THEN 'Bill Payment (ERP)'
	WHEN incomingmessagetype = 'pacs.002' THEN 'Cancelation of ACH Payment'
	WHEN incomingmessagetype = 'ACTRF' THEN 'Internal Transfer between Own Accounts'
	WHEN incomingmessagetype = 'ACOTHER' THEN 'Internal Transfer between Bank Accounts'
	ELSE 'Uncategorized'
END   trx_sub_type_cd ,--TRNX_SUB_CATEGORY,
context_operation,  
context_transactiontype ,  
TRX.statuscode   TRX_STS_CD,
TXN_STATUS.StatusDescription TRX_STS_DESC,
debitbookcode  DBT_BK_CD,
from_unixtime(unix_timestamp(statusdatetime, 'yyyyMMddHHmmssSSS'), 'yyyy-MM-dd HH:mm:ss') AS STS_DTTM ,  --Dstatusdatetime,
from_unixtime(unix_timestamp(statusdate,'yyyyMMdd'),'yyyy-MM-dd') AS STS_DT , 
CASE 
  WHEN coalesce(senderaddress ,'') in('', 'null' )  OR  senderaddress IS NULL   THEN NULL  --'NA'
  ELSE senderaddress
END Sndr   ,-- Sender_Institution, 
Sendersreferenceincoming sndr_ref_incm ,--refrence_incoming_name, 
Originatingsource  orign_src,
Paymentdirection PMT_DRCTN,
Ctrbtrindicator	CNTRB_IND,
Outputchannel	OUT_CHNL,
Incomingmessagetype	incm_msg_type,
Debitmainaccount    DBT_ACCT_KEY,
Debitmainaccountcurrencycode   DBT_MN_ACCT_CURY_KEY,
from_unixtime(unix_timestamp(Debitvaluedate,'yyyyMMdd'),'yyyy-MM-dd') AS  dbt_val_dt , -- Debitvaluedate,
Transactioncurrencycode   TRX_CURY_KEY,
cast(CASE WHEN coalesce(Transactionamount, '') in ('', 'null') THEN '0.00' ELSE Transactionamount END as decimal(18, 3))  TRX_AMT ,--Transactionamount,
cast(CASE WHEN coalesce(transactionamounthome,'') in ('', 'null') THEN '0.00' ELSE transactionamounthome END as decimal(18,3)) TRX_AMT_LCL  , --transaction_amount_home,
Creditmainaccount   CRDT_ACCT_KEY ,
from_unixtime(unix_timestamp(Requestedexecutiondate,'yyyyMMdd'),'yyyy-MM-dd')   req_exec_dt  , --Requestedexecutiondate,
from_unixtime(unix_timestamp(Creditvaluedate,'yyyyMMdd'),'yyyy-MM-dd')  CRDT_VAL_DT , -- Creditvaluedate,
Creditmainaccountcurrencycode CRDT_MN_ACCT_CURY_KEY,
Detailsofcharges CHRG_TYPE,
cast(CASE WHEN coalesce(Creditmainamount,'') in ('', 'null') THEN '0.00' ELSE Creditmainamount END as decimal(18,3))    CRDT_AMT  , -- Creditmainamount,
cast(CASE WHEN coalesce(Debitmainamount, '') in ('', 'null') THEN '0.00' ELSE Debitmainamount END as decimal(18,3)) DBT_AMT ,--Debitmainamount,
Debitclientid   DBT_PRTY_KEY,
Debitpartyline1 DBT_PRTY_LN_1,
Debitpartyline2   DBT_PRTY_LN_2,
Creditpartyline1   CRDT_PRTY_LN_1,
cast(CASE WHEN coalesce(Postingmainamountdebitlcy, '') in ('', 'null') THEN '0.00' ELSE Postingmainamountdebitlcy END as decimal(18, 4))  POST_AMNT_DBT_LCY , --  Postingmainamountdebitlcy,
cast(CASE WHEN coalesce(Postingmainamountcreditlcy, '') in ('', 'null') THEN '0.00' ELSE Postingmainamountcreditlcy END as decimal(18, 4)) POST_AMNT_CRDT_LCY , --Postingmainamountcreditlcy,
Cast(CASE WHEN TRIM(Exchangerate) IN('','null') OR Exchangerate IS NULL  THEN '1.00' ELSE Exchangerate END AS DECIMAL(6,4)) CURY_ER_RT   ,--Exchangerate,
Filereferenceincoming   file_ref_incom,

entryuserid  INPTER_USR_ID,
approveruserid1   APPRV_USR_ID_1,
approveruserid2  APPRV_USR_ID_2,
from_unixtime(unix_timestamp(entrydatetime,'yyyyMMdd'),'yyyy-MM-dd') TRX_ENTRY_DT ,--entrydatetime,
from_unixtime(unix_timestamp(approveddatetime,'yyyyMMdd'),'yyyy-MM-dd') TRX_APPRV_DT ,-- approveddatetime,
returnpaymentreference  RTRN_PMT_REF,
debit_account_currency 		 DBT_ACCT_CURY_KEY,
debit_account_type			 DBT_ACCT_TYPE_CD,
debit_account_status         DBT_ACCT_STS,
debit_account_iban  		 DBT_ACCT_IBAN,
debit_account_category_cd    DBT_ACCT_CTGY_CD,
debit_cif   				 DBT_CUST_KEY ,
debit_customer_name  		 DBT_CUST_NM,
debit_customer_address   	 DBT_CUST_ADDR,
debit_customer_sector		 DBT_CUST_SCTR_KEY,
debit_Identifiercode  		 DBT_IDNTF_CD, -- new
debit_CountryCD    			 DBT_CUST_CNTRY_KEY  , --new
credit_account_currency  	 CRDT_ACCT_CURY_KEY,
credit_account_type     	 CRDT_ACCT_TYPE_CD,
credit_account_status 		 CRDT_ACCT_STS,
credit_account_iban 		 CRDT_ACCT_IBAN,
credit_account_category_cd   CRDT_ACCT_CTGY_CD,
credit_cif   				 CRDT_CUST_KEY,
credit_customer_name   		 CRDT_CUST_NM,
credit_customer_address   	 CRDT_CUST_ADDR,
credit_customer_sector    	 CRDT_CUST_SCTR_KEY,
credit_countryCD    		 CRDT_CUST_CNTRY_KEY, ---new
CASE
	WHEN Beneficiary.partytype = 'CREDIT' and Originatingsource != 'PEG' THEN Beneficiary.partyfreeline
END Beneficiary_Name,
CASE
	WHEN Beneficiary.partytype = 'CREDIT' and Originatingsource != 'PEG' THEN Beneficiary.partyaccountline
END Beneficiary_Account_Num,
CASE
	WHEN Beneficiary.partytype = 'CREDIT'and Originatingsource != 'PEG' THEN credit_customer_address
END Beneficiary_Address,
CASE
	WHEN Beneficiary.partytype = 'CREDIT' and Originatingsource != 'PEG' THEN COALESCE (Beneficiary.country,credit_countryCD)
END Beneficiary_Country,
CASE
	WHEN Beneficiary.partytype = 'CREDIT' and Originatingsource != 'PEG' THEN Beneficiary.partyidentifiercode
END Beneficiary_BIC,
CASE
	WHEN Beneficiary.partytype = 'CREDIT' and Originatingsource = 'PEG' THEN Beneficiary.partyaccountline
END Receiver_Account_Num,

CASE
	WHEN Sender_BANK.partytype = 'DEBIT' THEN Sender_BANK.partyidentifiercode
END SENDER_BIC,
CASE
	WHEN Sender_BANK.partytype = 'DEBIT' THEN Sender_BANK.partyaccountline
END SENDER_ACCOUNT,
CASE
	WHEN Sender_BANK.partytype = 'DEBIT' THEN Sender_BANK.name
END SENDER_NAME,
CASE
	WHEN Sender_BANK.partytype = 'DEBIT' THEN Sender_BANK.country
END SENDER_country,
BROKER_BANK.partyidentifiercode Broker_BIC,
FEES_1_CHRG_PARTY,
FEES_1_TYPE,
FEES_1_DESC,
cast(CASE WHEN coalesce(FEES_1_AMOUNT,'') in ('', 'null') THEN '0.00'ELSE FEES_1_AMOUNT END as decimal(18,3)) FEES_1_AMOUNT,
FEES_1_CURRENCY,
cast(CASE WHEN coalesce(FEES_1_AMOUNT_LCCY, '') in ('', 'null') THEN '0.00' ELSE FEES_1_AMOUNT_LCCY END as decimal(18, 3)) FEES_1_AMOUNT_LCCY,
FEES_1_PL_ACCOUNT,
FEES_1_PL_CURRENCY,
FEES_2_CHRG_PARTY,
FEES_2_TYPE,
FEES_2_DESC,
cast(CASE WHEN coalesce(FEES_2_AMOUNT, '') in ('', 'null') THEN '0.00' ELSE FEES_2_AMOUNT END as decimal(18,3)) FEES_2_AMOUNT,
FEES_2_CURRENCY,
cast(CASE WHEN coalesce(FEES_2_AMOUNT_LCCY,'') in ('', 'null') THEN '0.00' ELSE FEES_2_AMOUNT_LCCY END as decimal(18,3)) FEES_2_AMOUNT_LCCY,
FEES_2_PL_ACCOUNT,
FEES_2_PL_CURRENCY,
Narrative.additionalinfline,
Narrative.additionalenricheddata,
SUPLMNTRY_RVRSL.reversalentryids reversalentryid,
CASE WHEN SUPLMNTRY_RVRSL.reversalentryids is not null THEN true ELSE false END reversed

 
FROM
	------------------------------------------------------ 
	------------------------------------------------------ POR Transaction Table
   (
	    SELECT * 
	    FROM 
        (
		    SELECT
            Ftnumber,
			K_ENTITYID,
         	K_processingtime,
			Context_bankingdate,
            Context_cobdate,
            Context_operation,
			Context_transactiontype,
			reasondescription,
			Statuscode,
			Debitbookcode,
			Statusdatetime, 
            Statusdate ,
			senderaddress,
            Sendersreferenceincoming,
            Originatingsource,
            Paymentdirection,
            Ctrbtrindicator,
            Outputchannel,
            Incomingmessagetype,
            Debitmainaccount,
            Debitmainaccountcurrencycode,
            Debitvaluedate,
            Transactioncurrencycode,
			Transactionamount,
			Transactionamounthome,
			Creditmainaccount,
		    Requestedexecutiondate,
		    Creditvaluedate,
		    Creditmainaccountcurrencycode,
		    Detailsofcharges,
			Creditmainamount,
			Debitmainamount,
			Debitclientid,
		    Debitpartyline1,
		    Debitpartyline2,
		    Creditpartyline1,
			Postingmainamountdebitlcy,
			Postingmainamountcreditlcy,
			Exchangerate,
	        Filereferenceincoming,
	        entryuserid,
	        entrydatetime,
	        approveruserid1,
	        approveruserid2,
	        approveddatetime,
	        bookdate,
			orderingpartyresidency,
			rank() over(partition by k_entityid order by k_processingtime desc) RNK 

			FROM ${stg_schema}.F_POR_TRANSACTION
		        WHERE CASE WHEN context_cobdate in('','null') or context_cobdate is null then context_bankingdate  else context_cobdate END between '${strt_dt}'  and '${end_dt}')POR_TRX
		WHERE RNK = 1
	)TRX
	------------------------------------------------------ 
	------------------------------------------------------ Lookup Table
    
	LEFT JOIN ${mod_schema}.t24_payment_status_lkp TXN_STATUS 
	ON TXN_STATUS.StatusCode = TRX.StatusCode
	
	------------------------------------------------------ 
	------------------------------------------------------ supplementary_info
    LEFT JOIN 
	(
		SELECT
		POR_SUPLMNTRY.returnpaymentreference,
		POR_SUPLMNTRY.K_ENTITYID,
		------------------------------------ debit
		SUPLMNTRY_DBT.recid,
		SUPLMNTRY_DBT.accountcurrency debit_account_currency,
		SUPLMNTRY_DBT.accounttype debit_account_type,
		SUPLMNTRY_DBT.accountstatus debit_account_status,
		SUPLMNTRY_DBT.relatediban debit_account_iban,
		SUPLMNTRY_DBT.categorycode debit_account_category_cd,
		SUPLMNTRY_DBT.customerid debit_cif,
		SUPLMNTRY_DBT.customername debit_customer_name,
		SUPLMNTRY_DBT.customeraddress debit_customer_address,
		SUPLMNTRY_DBT.sectorcode debit_customer_sector,
		SUPLMNTRY_DBT.identifiercode Debit_Identifiercode,	--------- new
		SUPLMNTRY_DBT.customerresidency Debit_CountryCD,------ new
		
		---------------------------------------- credit
		SUPLMNTRY_CRDT.accountcurrency credit_account_currency,
		SUPLMNTRY_CRDT.accounttype credit_account_type,
		SUPLMNTRY_CRDT.accountstatus credit_account_status,
		SUPLMNTRY_CRDT.relatediban credit_account_iban,
		SUPLMNTRY_CRDT.categorycode credit_account_category_cd,
		SUPLMNTRY_CRDT.customerid credit_cif,
		SUPLMNTRY_CRDT.customername credit_customer_name,
		SUPLMNTRY_CRDT.customeraddress credit_customer_address,
		SUPLMNTRY_CRDT.sectorcode credit_customer_sector,
		SUPLMNTRY_CRDT.customerresidency credit_countryCD---- new
		
		FROM
		(
			SELECT *
			FROM
			(
					SELECT
					k_entityid,
					returnpaymentreference,
					row_number() over(partition by k_entityid order by k_processingtime desc) rnk
					
					FROM ${stg_schema}.F_POR_SUPPLEMENTARY_INFO 
			)SUPLMNTRY
			WHERE rnk = 1
		)POR_SUPLMNTRY
	
	
	    INNER JOIN 
	    (
		    SELECT *
			FROM
			(
					SELECT
					K_ENTITYID,
					RECID,
					accountcurrency,
					accounttype,
					accountstatus,
					relatediban,
					categorycode,
					customerid,
					customername,
					customeraddress,
					sectorcode,
					identifiercode,	--------- new
					customerresidency, ------ new
					
					row_number() over(partition by k_entityid order by k_processingtime desc) rnk
					
					FROM ${stg_schema}.F_POR_SUPPLEMENTARY_INFO_MAINORCHARGEACCOUNTTYPE
					WHERE mainorchargeaccounttype = 'D'
			)base
			WHERE rnk = 1
		)SUPLMNTRY_DBT
		ON SUPLMNTRY_DBT.K_ENTITYID = POR_SUPLMNTRY.K_ENTITYID
		
		INNER JOIN 
		(
			SELECT *
			FROM
			(
					SELECT
					K_ENTITYID,
					accountcurrency,
					accounttype,
					accountstatus,
					relatediban,
					categorycode,
					customerid,
					customername,
					customeraddress,
					sectorcode,
					customerresidency,------ new
					
					row_number() over(partition by k_entityid order by k_processingtime desc) rnk
					
					FROM ${stg_schema}.f_por_supplementary_info_mainorchargeaccounttype
					WHERE mainorchargeaccounttype = 'C'
			)base
			WHERE rnk = 1
        )SUPLMNTRY_CRDT
       ON  SUPLMNTRY_CRDT.K_ENTITYID = POR_SUPLMNTRY.K_ENTITYID
       
	)SUPLMNTRY
	ON SUPLMNTRY.K_ENTITYID = TRX.K_ENTITYID
	

	------------------------------------------------------ 
	------------------------------------------------------ Beneficiary
    
	LEFT JOIN
	(
	    SELECT
		SUPLMNTRY_INFO.k_entityid,
		SUPLMNTRY_INFO.partytype,
		CASE 
		  WHEN coalesce(SUPLMNTRY_INFO.partyidentifiercode,'') in('', 'null') THEN NULL 
		  ELSE SUPLMNTRY_INFO.partyidentifiercode 
		END partyidentifiercode,
		CASE 
		  WHEN coalesce(SUPLMNTRY_INFO.partyaccountline ,'') in('', 'null') THEN NULL 
		  ELSE SUPLMNTRY_INFO.partyaccountline
		END partyaccountline,
		CASE 
		  WHEN coalesce(SUPLMNTRY_INFO.partycustomerid ,'') in('', 'null') THEN NULL
		  ELSE SUPLMNTRY_INFO.partycustomerid  
		END partycustomerid,
		CASE 
		  WHEN coalesce(SUPLMNTRY_INFO.name ,'') in('', 'null') THEN NULL
		  ELSE SUPLMNTRY_INFO.name 
		END name,
		CASE
		  WHEN coalesce(SUPLMNTRY_INFO.country ,'') in('', 'null') THEN NULL
		  ELSE SUPLMNTRY_INFO.country
		END country ,
		CASE
			WHEN coalesce(SUPLMNTRY_PARTYFREELINE.partyfreeline ,'') in('', 'null') THEN NULL
			ELSE SUPLMNTRY_PARTYFREELINE.partyfreeline
		END partyfreeline
	    
		FROM
		(
		   SELECT *
		   FROM
		   (
				SELECT
				k_entityid,
				rec_index,
				partytype,
				partyidentifiercode,
				partyaccountline,
				partycustomerid,
				name,
				country,
				row_number() over(partition by k_entityid order by k_processingtime desc) rnk
				
				FROM ${stg_schema}.F_POR_SUPPLEMENTARY_INFO_PARTYTYPE
				WHERE partyrole IN('ACWINS', 'BENFCY', 'BENINS', 'RECVER')
			    AND roleindicator = 'R'
			)SUPLMNTRY_PARTYTYPE
		    WHERE RNK = 1
			
        )SUPLMNTRY_INFO
	
	    LEFT JOIN 
        (
			SELECT *
			FROM
			(
				SELECT
				k_entityid,
				rec_index,
				partyfreeline,
				row_number() over(partition by k_entityid order by k_processingtime desc) rnk
				
				FROM ${stg_schema}.F_POR_SUPPLEMENTARY_INFO_PARTYTYPE_PARTYFREELINE x
				WHERE substr( rec_index,3,1) = '0'
			)SUPLMNTRY_FREELINE
		    WHERE RNK = 1 
        )SUPLMNTRY_PARTYFREELINE
		ON SUPLMNTRY_PARTYFREELINE.K_ENTITYID = SUPLMNTRY_INFO.K_ENTITYID
		AND CAST(REGEXP_EXTRACT(SUPLMNTRY_PARTYFREELINE.rec_index ,'([0-9]+)',1) AS INT) = CAST(SUPLMNTRY_INFO.rec_index AS INT)
	
	) Beneficiary 
	ON Beneficiary.k_entityid = TRX.k_entityid


	LEFT  JOIN
	(
		   SELECT
			K_ENTITYID,
			CASE
				WHEN coalesce(partyidentifiercode,'') in('', 'null') THEN NULL
				ELSE partyidentifiercode
			END partyidentifiercode
		
			FROM
			(
				SELECT
				K_ENTITYID,
				partyidentifiercode,
				row_number() over(partition by k_entityid order by k_processingtime desc) rnk
				
				FROM ${stg_schema}.F_POR_SUPPLEMENTARY_INFO_PARTYTYPE x
				WHERE partyrole IN ('RECVER')
				and roleindicator = 'G'
			)BROKER
			WHERE RNK = 1
		
	)BROKER_BANK 
	ON BROKER_BANK.K_ENTITYID = TRX.K_ENTITYID
    
	------------------------------------------------------ 
	------------------------------------------------------ Sender_BANK
	
	LEFT JOIN
	(
	    SELECT
		SUPLMNTRY_INFO.k_entityid,
		SUPLMNTRY_INFO.partytype,
		CASE 
		  WHEN coalesce(SUPLMNTRY_INFO.partyidentifiercode,'') in('', 'null') THEN NULL 
		  ELSE SUPLMNTRY_INFO.partyidentifiercode 
		END partyidentifiercode,
		CASE 
		  WHEN coalesce(SUPLMNTRY_INFO.partyaccountline ,'') in('', 'null') THEN NULL 
		  ELSE SUPLMNTRY_INFO.partyaccountline
		END partyaccountline,
		CASE 
		  WHEN coalesce(SUPLMNTRY_INFO.name ,'') in('', 'null') THEN NULL
		  ELSE SUPLMNTRY_INFO.name 
		END name,
		CASE
		  WHEN coalesce(SUPLMNTRY_INFO.country ,'') in('', 'null') THEN NULL
		  ELSE SUPLMNTRY_INFO.country
		END country
	    
		FROM
		(
		  
				SELECT
				k_entityid,
				rec_index,
				partytype,
				partyidentifiercode,
				partyaccountline,
				name,
				country,
				row_number() over(partition by k_entityid order by k_processingtime desc) rnk
				
				FROM ${stg_schema}.F_POR_SUPPLEMENTARY_INFO_PARTYTYPE
				WHERE partyrole IN ('SNDINS', 'ASVINS', 'ORDINS', 'ORDPTY')
				and roleindicator = 'R'
		)SUPLMNTRY_INFO
		
		WHERE RNK = 1
		
	)Sender_BANK 
    ON Sender_BANK.K_ENTITYID = TRX.K_ENTITYID
	
	---------------------------------------------
	-------------------------------------------------- FEES AND CHARGES
	------------------------------------------------
    LEFT JOIN
    (
	    SELECT
		FEES_1.k_entityid,
		FEES_1.chargepartyindicator FEES_1_CHRG_PARTY,
		FEES_1.feetype FEES_1_TYPE,
		FEES_1.feedescription FEES_1_DESC,
		FEES_1.chargeamount FEES_1_AMOUNT,
		FEES_1.chargeamountcurrency FEES_1_CURRENCY,
		FEES_1.chargeamountlocalccy FEES_1_AMOUNT_LCCY,
		FEES_1.placcountnumber FEES_1_PL_ACCOUNT,
		FEES_1.placcountcurrency FEES_1_PL_CURRENCY,
		FEES_2.chargepartyindicator FEES_2_CHRG_PARTY,
		FEES_2.feetype FEES_2_TYPE,
		FEES_2.feedescription FEES_2_DESC,
		FEES_2.chargeamount FEES_2_AMOUNT,
		FEES_2.chargeamountcurrency FEES_2_CURRENCY,
		FEES_2.chargeamountlocalccy FEES_2_AMOUNT_LCCY,
		FEES_2.placcountnumber FEES_2_PL_ACCOUNT,
		FEES_2.placcountcurrency FEES_2_PL_CURRENCY
	    FROM
		( 
		SELECT *
			FROM
			(
			    SELECT
				k_entityid,
				chargepartyindicator,
				feetype,
				chargesign,
				typeofcharge,
				feedescription,
				chargeamount,
				chargeamountcurrency,
				chargeamountlocalccy,
				localccycode,
				chargeamountfeecurrency,
				feecurrencycode,
				placcountcompany,
				placcountnumber,
				placcountcurrency,
				rank() over(PARTITION by k_entityid  order by k_processingtime desc) rnk
			    
				FROM ${stg_schema}.F_POR_POSTING_AND_CONFIRMATION_CHARGEPARTYINDICATOR
				WHERE rec_index = '0'
				
			)A
		    WHERE RNK = 1
        )FEES_1
	
		LEFT JOIN 
		(
			SELECT *
			FROM
			(
				SELECT
				k_entityid,
				chargepartyindicator,
				feetype,
				chargesign,
				typeofcharge,
				feedescription,
				chargeamount,
				chargeamountcurrency,
				chargeamountlocalccy,
				localccycode,
				chargeamountfeecurrency,
				feecurrencycode,
				placcountcompany,
				placcountnumber,
				placcountcurrency,
				rank() over(PARTITION by k_entityid order by k_processingtime desc) rnk
			
				FROM ${stg_schema}.f_por_posting_and_confirmation_chargepartyindicator
				WHERE rec_index = '1'
			)A
			WHERE	RNK = 1
		)FEES_2 
		ON FEES_1.k_entityid = FEES_2.k_entityid
	)FEES 
	ON FEES.k_entityid = TRX.K_ENTITYID
	

	LEFT JOIN
	(
		SELECT
		K_ENTITYID,
		CASE 
			  WHEN coalesce(additionalinfline,'') in('', 'null', NULL) THEN 'NA' 
			  ELSE additionalinfline
		END additionalinfline,
		CASE 
			  WHEN coalesce(additionalenricheddata,'') in('', 'null', NULL) THEN 'NA' 
			  ELSE additionalenricheddata
		END additionalenricheddata
		
		FROM
		(
				SELECT
				K_ENTITYID,
				additionalinfline ,
				additionalenricheddata,
				
				row_number() over(partition by k_entityid order by k_processingtime desc) rnk
				FROM ${stg_schema}.F_POR_SUPPLEMENTARY_INFO_ADDITIONALINFORMATIONCODE_ADDINFTYPELINESEQ
		) a
		WHERE rnk = 1
	)Narrative 
	ON Narrative.K_ENTITYID = TRX.K_ENTITYID


	LEFT JOIN
	(
		SELECT *
		FROM
		(
			SELECT
			K_ENTITYID,
			reversalentryids,
			row_number() over(partition by k_entityid order by k_processingtime desc) rnk
			
			FROM ${stg_schema}.F_POR_SUPPLEMENTARY_INFO_REVERSALENTRYIDS x
			WHERE rec_index = '0' 
		)RVRSL
		WHERE rnk = 1
	)SUPLMNTRY_RVRSL 
	ON sUPLMNTRY_RVRSL.K_ENTITYID = TRX.K_ENTITYID	) A 
