SELECT COUNT(*) FROM (
    SELECT hash_prep.*,
        CASE WHEN HASH_PREP.HASH_KEY = FIRST_VALUE(HASH_PREP.HASH_KEY) OVER(
            PARTITION BY HASH_PREP.Trade_Ref ORDER BY HASH_PREP.cob_dt ASC
            ROWS BETWEEN 1 PRECEDING AND 1 PRECEDING)
        THEN 1 ELSE 0 END AS FK_UP
    FROM (
        SELECT BUS_QRY.*,
            sha2(
coalesce(Sec_CD, '') ||
coalesce(ISIN, '') ||
coalesce(Face_Val, '') ||
coalesce(Present_Val, '') ||
coalesce(Curr, '') ||
coalesce(Price_Typ, '') ||
coalesce(Depository, '') ||
coalesce(Int_Rate, '') ||
coalesce(Purchase_Yield, '') ||
coalesce(Stck_Exch, '') ||
coalesce(Mark_Typ, '') ||
coalesce(Trd_Brok_No, '') ||
coalesce(Trd_Brok_Acc_no, '') ||
coalesce(Trd_Brok_Name, '') ||
coalesce(Trd_Cust_No, '') ||
coalesce(Trd_Cust_Acc_No, '') ||
coalesce(Trd_Cust_Name, '') ||
coalesce(Portof_ID, '') ||
coalesce(Portof_Desc, '') ||
coalesce(Acc_Off, '') ||
coalesce(Auth, '') ||
coalesce(Dept_Code, '') ||
coalesce(Current_Value, '') ||
coalesce(discaccrposted, '') ||
coalesce(Days_to_Maturity, '') ||
coalesce(Current_Yield, '') ||
coalesce(Tenor, '') ||
coalesce(Elapsed, '') ||
coalesce(TENOR_WEIGHT, '') ||
coalesce(Disc_At_Start, '') ||
coalesce(PV_AT_START, '') ||
coalesce(TOTAL_INTEREST, '') ||
coalesce(INTEREST_PER_DAY, '') ||
coalesce(INT_TO_MAT, '') ||
coalesce(CURRENT_DISC, '') ||
coalesce(ACCRUED, '') ||
coalesce(PV_TDY, '') ||
coalesce(CURRENT_YLD, '') ||
coalesce(WEIGHT, '') ||
coalesce(date_id, '')
            , 256) AS HASH_KEY
        FROM (
            
            select stg.*,
            SHA2(COALESCE(Sec_CD,'')||COALESCE(ISIN,'')||COALESCE(Face_Val,'')||COALESCE(Present_Val,'')||COALESCE(Curr,'')||
            COALESCE(Price_Typ,'')||COALESCE(Depository,'')||COALESCE(Int_Rate,'')||COALESCE(Purchase_Yield,'')||COALESCE(Stck_Exch,'')||
            COALESCE(Mark_Typ,'')||COALESCE(Trd_Brok_No,'')||COALESCE(Trd_Brok_Acc_no,'')||COALESCE(Trd_Brok_Name,'')||COALESCE(Trd_Cust_No,'')||
            COALESCE(Trd_Cust_Acc_No,'')||COALESCE(Trd_Cust_Name,'')||COALESCE(Portof_ID,'')||COALESCE(Portof_Desc,'')||COALESCE(Acc_Off,'')||
            COALESCE(Auth,'')||COALESCE(Dept_Code,'')||COALESCE(Current_Value,'')||COALESCE(discaccrposted,'')||COALESCE(Trade_Dt,'')||
            COALESCE(Value_Dt,'')||COALESCE(Maturity_Dt,'')||COALESCE(Days_to_Maturity,'')||COALESCE(issue_Dt,'')||COALESCE(Lst_Pym_DT,'')||
            COALESCE(PROCESSING_DT,'')||COALESCE(Current_Yield,'')||COALESCE(Tenor,'')||COALESCE(Elapsed,'')||COALESCE(TENOR_WEIGHT,'')||
            COALESCE(Disc_At_Start,'')||COALESCE(PV_AT_START,'')||COALESCE(TOTAL_INTEREST,'')||COALESCE(INTEREST_PER_DAY,'')||COALESCE(INT_TO_MAT,'')||
            COALESCE(CURRENT_DISC,'')||COALESCE(ACCRUED,'')||COALESCE(PV_TDY,'')||COALESCE(CURRENT_YLD,'')||COALESCE(WEIGHT,'')||COALESCE(cob_dt,'')||COALESCE(date_id,''), 256)as hashcode,cast(current_timestamp as string) as tec_insrt_dttm		
            	,null as tec_upd_dttm		
            	,null as dr_dttm		
            	,null as dr_flg
            from(select
            distinct
            Trade_Ref ,
            Sec_CD ,
            ISIN,
            Face_Val ,
            Present_Val ,
            Curr ,
            Price_Typ ,
            Depository ,
            Int_Rate ,
            Purchase_Yield ,
            Stck_Exch ,
            Mark_Typ ,
            Trd_Brok_No ,
            Trd_Brok_Acc_no ,
            Trd_Brok_Name ,
            Trd_Cust_No ,
            Trd_Cust_Acc_No ,
            Trd_Cust_Name ,
            Portof_ID ,
            Portof_Desc ,
            Acc_Off ,
            Auth ,
            Dept_Code ,
            Current_Value  ,
            discaccrposted ,
            Trade_Dt ,
            Value_Dt ,
            Maturity_Dt ,
            Days_to_Maturity ,
            issue_Dt ,
            Lst_Pym_DT ,
            PROCESSING_DT ,
            Case When ((Face_Val-discaccrposted)*Days_to_Maturity) = 0 then 0 else  case when Curr = 'EGP' THEN
            ((discaccrposted  *365)/((Face_Val-discaccrposted)*Days_to_Maturity))*100
            ELSE ((discaccrposted  *360)/((Face_Val-discaccrposted)*Days_to_Maturity))*100  END end  Current_Yield,
            Tenor,
            Elapsed,
            Face_Val*Days_to_Maturity TENOR_WEIGHT,
            1/((Purchase_Yield/100*TENOR/365)+1) Disc_At_Start ,
            Face_Val* (1/((Purchase_Yield/100*TENOR/365)+1)) PV_AT_START,
            Face_Val - (Face_Val* (1/((Purchase_Yield/100*TENOR/365)+1))) TOTAL_INTEREST,
            (Face_Val - (Face_Val* (1/((Purchase_Yield/100*TENOR/365)+1))))/Tenor INTEREST_PER_DAY,
            ((Face_Val - (Face_Val* (1/((Purchase_Yield/100*TENOR/365)+1))))/Tenor) * Days_to_Maturity INT_TO_MAT,
            ((((((Face_Val - (Face_Val* (1/((Purchase_Yield/100*TENOR/365)+1))))/Tenor) *Elapsed)+(Face_Val* (1/((Purchase_Yield/100*TENOR/365)+1)) ))/Face_Val))*100  CURRENT_DISC,
            (Face_Val - (Face_Val* (1/((Purchase_Yield/100*TENOR/365)+1))) ) - (((Face_Val - (Face_Val* (1/((Purchase_Yield/100*TENOR/365)+1))))/Tenor) * Days_to_Maturity) ACCRUED,
            Face_Val* (((((((Face_Val - (Face_Val* (1/((Purchase_Yield/100*TENOR/365)+1))))/Tenor) *Elapsed)+(Face_Val* (1/((Purchase_Yield/100*TENOR/365)+1)) ))/Face_Val))*100)/100  PV_TDY ,
            ((((100- (((((((Face_Val - (Face_Val* (1/((Purchase_Yield/100*TENOR/365)+1))))/Tenor) *Elapsed)+(Face_Val* (1/((Purchase_Yield/100*TENOR/365)+1)) ))/Face_Val))*100 ))
            /(((((((Face_Val - (Face_Val* (1/((Purchase_Yield/100*TENOR/365)+1))))/Tenor) *Elapsed)+(Face_Val* (1/((Purchase_Yield/100*TENOR/365)+1)) ))/Face_Val))*100 ))/Days_to_Maturity)*365)*100  CURRENT_YLD,
            Face_Val* ((((100- (((((((Face_Val - (Face_Val* (1/((Purchase_Yield/100*TENOR/365)+1))))/Tenor) *Elapsed)+(Face_Val* (1/((Purchase_Yield/100*TENOR/365)+1)) ))/Face_Val))*100 ))
            /(((((((Face_Val - (Face_Val* (1/((Purchase_Yield/100*TENOR/365)+1))))/Tenor) *Elapsed)+(Face_Val* (1/((Purchase_Yield/100*TENOR/365)+1)) ))/Face_Val))*100 ))/Days_to_Maturity)*365) WEIGHT,
            cob_dt,
            CURRENT_DATE() date_id
            from (
            Select  
            st.k_entityid As Trade_Ref,
            st.securitycode As Sec_CD,
            Case WHen FSM.altsecurityno in ('',null,'null')   then null Else FSM.altsecurityno end As ISIN,
            STC.custtotnom  As Face_Val,
            STC.cunetamtrd As Present_Val,
            st.tradeccy As Curr,
            st.pricetype As Price_Typ,
            st.depository As Depository,
            st.interestrate As Int_Rate,
            Case When st.lticketytm ='' then '0' else st.lticketytm  end  As Purchase_Yield,
            St.stockexchange AS Stck_Exch,
            St.markettype AS Mark_Typ,
            tb.brokerno As Trd_Brok_No,
            tb.braccno As Trd_Brok_Acc_no,
            cub.cust_name As Trd_Brok_Name,
            STC.customerno As Trd_Cust_No,
            STC. custaccno AS Trd_Cust_Acc_No,
            cuc.cust_name As Trd_Cust_Name,
            STC.custsecacc As Portof_ID,
            Fsam.accountname As Portof_Desc,
            FSAM.accountofficer As Acc_Off,
            st.authoriser As Auth,
            st.deptcode As Dept_Code,
            (cast (STC.custtotnom as float) -discaccrposted) as Current_Value,
            Datediff(cast(regexp_replace( st.maturitydate,'(\\d{4})(\\d{2})(\\d{2})','$1-$2-$3') as date),cast(regexp_replace( st.tradedate,'(\\d{4})(\\d{2})(\\d{2})','$1-$2-$3') as date)) Tenor,
            Datediff(sctr.cob_dt,cast(regexp_replace( st.tradedate,'(\\d{4})(\\d{2})(\\d{2})','$1-$2-$3') as date)) Elapsed,
            discaccrposted,
            cast(regexp_replace( st.tradedate,'(\\d{4})(\\d{2})(\\d{2})','$1-$2-$3') as date) As Trade_Dt,
            cast(regexp_replace( st.valuedate,'(\\d{4})(\\d{2})(\\d{2})','$1-$2-$3') as date) As Value_Dt,
            cast(regexp_replace( st.maturitydate,'(\\d{4})(\\d{2})(\\d{2})','$1-$2-$3') as date) As Maturity_Dt,
            Datediff(cast(regexp_replace( st.maturitydate,'(\\d{4})(\\d{2})(\\d{2})','$1-$2-$3') as date),date_sub(CURRENT_DATE , 1)) Days_to_Maturity,
            cast(regexp_replace( st.issuedate,'(\\d{4})(\\d{2})(\\d{2})','$1-$2-$3') as date) As issue_Dt,
            cast(regexp_replace( st.lastpaymntdate,'(\\d{4})(\\d{2})(\\d{2})','$1-$2-$3') as date) As Lst_Pym_DT,
            cast(from_unixtime(cast(CAST(st.k_processingtime as BIGINT) / 1000 as int), "yyyy-MM-dd") AS DATE) PROCESSING_DT,
            sctr.cob_dt
             
            From (
            select * from (
            select * , ROW_NUMBER() over(PARTITION by k_entityid ORDER  by context_cobdate desc,  k_processingtime desc ) r  from  stg_t24.fodb_sec_trade)s
            where s.r=1
            ) st
            left join ( select distinct
            k_entityid,
            custtotnom,
            cunetamtrd,
            custsecacc,
            custaccno,
            customerno,
            recid
            from
            stg_t24.fodb_sec_trade_customerno  ) stc on St.k_entityid = Stc.recid
            left join ( Select DISTINCT  k_entityid,accountofficer,accountname From
            stg_t24.fodb_sec_acc_master ) fsam on stc.custsecacc=fsam.k_entityid  
            left Join stg_t24.f_security_master_altsecurityid fsm
            on fsm.k_entityid=st.securitycode and  altsecurityid ='ALTISIN'
            left join (
                            select
                            securitycode,
                            dealerbook,
                            discountaccrued,
                            ABS( cast(discaccrposted as float)) as discaccrposted,
                            currentposition,
                            from_unixtime(cast(CAST(k_processingtime as BIGINT) / 1000 as int),"yyyy-MM-dd HH:mm:ss"),
                          cast(regexp_replace( context_cobdate,'(\\d{4})(\\d{2})(\\d{2})','$1-$2-$3') as date) As cob_dt,
                          ROW_NUMBER () OVER (PARTITION BY k_entityid
                          --,cast(regexp_replace( context_cobdate,'(\\d{4})(\\d{2})(\\d{2})','$1-$2-$3') as date) 
                          ORDER BY k_processingtime desc) r
                           from stg_t24.fodb_sc_trading_position 
                           where cast(regexp_replace( context_cobdate,'(\\d{4})(\\d{2})(\\d{2})','$1-$2-$3') as date)<=CURRENT_DATE()
                         ) sctr
            on sctr.securitycode = st.securitycode  and sctr.dealerbook = stc.custsecacc  and sctr.r = 1
            LEFT join stg_t24.fodb_sec_trade_brokerno  tb on tb.k_entityid=St.k_entityid
            left Join  dwh_base.t24_cust_dim_base cuc on Stc.customerno = Cuc.Cif
            left Join  dwh_base.t24_cust_dim_base cub  on cub.cif= tb.brokerno    
             
            )a  Where Days_to_Maturity>=0 and Sec_CD!='800000-083'
            and portof_id in ('999999-4','999999-5','999999-6')) as stg
        ) BUS_QRY
    ) HASH_PREP
) FINAL WHERE FK_UP <> 1
