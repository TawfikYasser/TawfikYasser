set tez.task.resource.memory.mb=4096;         

set tez.am.resource.memory.mb=4096;

merge into  dwh_base.cust_address_info  as trg
    using
(select * 
,CURRENT_TIMESTAMP                       AS  Tec_Insrt_Dttm
		   ,CURRENT_TIMESTAMP             AS  Tec_Upd_Dttm
		   ,null                          AS  DR_Dttm
		   ,null                          AS  DR_Flg
from (
  SELECT 
      stg.*, 
      mod.HashCode AS old_HashCode,
  --(lead(cast(stg.modifiedon as timestamp)) OVER (PARTITION BY stg.BoardingID,stg.address_type  ORDER BY cast(stg.modifiedon as timestamp) ) - INTERVAL 1 SECOND)  AS enddt,
  (lead(stg.modifiedon) OVER (PARTITION BY stg.BoardingID,stg.address_type  ORDER BY stg.modifiedon) - INTERVAL 1 SECOND)  AS enddt,    
     CASE WHEN              
      stg.HashCode =  FIRST_VALUE(stg.HashCode ) 
  				OVER(partition by stg.BoardingID ,stg.address_type  
  					order by  stg.modifiedon asc rows  
  						between 1 preceding and 1 preceding ) 
          		THEN 1 ELSE 0 END AS FK_UP,
           --stg.modifiedon StartDT
		   stg.modifiedon StartDT,
		   cast(stg.modifiedon as date) Start_DT
from(
SELECT base.*,
sha2(coalesce(ADDRESS,'')||coalesce(COUNTRY,'')||coalesce(CITY,'')||coalesce(STREET,'')||coalesce(BUILDING,'')
||coalesce(DEPARTMENT,'')|| coalesce(DESCRIPTION,'')||coalesce(boardingid,'')||coalesce(address_type,'')||coalesce(modifiedbyid,'')
||coalesce(modifiedbyname,'')||coalesce(modifiedbytitle,'')||coalesce(modifiedon,''),256) HASHCODE
 
from(
select 
CBase.atos_customerId CIF,CBase.OriginatingLeadId ProspectID,CBase.ContactId BoardingID,
atos_nationalidaddress ADDRESS,
CNTRY.ATOS_NAME COUNTRY,
CTY.ATOS_NAME CITY,
atos_nationalidarea STREET,
NULL BUILDING,
NULL DEPARTMENT,
'National Id Address' DESCRIPTION,
'NATIONAL_ID_ADDRESS' ADDRESS_TYPE
--,CBase.ModifiedOn modifiedon
,cast(from_unixtime(CAST(CBase.modifiedon AS BIGINT) DIV 1000) as timestamp) modifiedon
,CBase.ModifiedBy modifiedbyid
,modfd.fullname modifiedbyname
,modfd.title modifiedbytitle
from stg_crm.ContactBase CBase 
left outer join  stg_crm.ATOS_CITYBASE CTY ON CBase.atos_nationalidcity =  CTY.ATOS_CITYID
left outer join  stg_crm.SystemUserBase modfd on CBase.modifiedby=modfd.systemuserid
left outer join  stg_crm.ATOS_COUNTRYBASE CNTRY ON CBase.atos_nationalidcountry =  CNTRY.ATOS_COUNTRYID
where atos_nationalidaddress is not null
 
UNION
 
select 
CBase.atos_customerId CIF,CBase.OriginatingLeadId ProspectID,CBase.ContactId BoardingID,
atos_residenceaddressdetails ADDRESS,
CNTRY.ATOS_NAME COUNTRY,
CTY.ATOS_NAME CITY,
NULL STREET,
NULL BUILDING,
NULL DEPARTMENT,
atos_residenceadditionaladdressinfo DESCRIPTION,
'RESIDENCE_ADDRESS' ADDRESS_TYPE
--,CBase.ModifiedOn modifiedon
,cast(from_unixtime(CAST(CBase.modifiedon AS BIGINT) DIV 1000) as timestamp) modifiedon
,CBase.ModifiedBy modifiedbyid
,modfd.fullname modifiedbyname
,modfd.title modifiedbytitle
from stg_crm.ContactBase CBase
left outer join  stg_crm.ATOS_COUNTRYBASE CNTRY 
ON CBase.atos_residencecountry =  CNTRY.ATOS_COUNTRYID
left outer join  stg_crm.SystemUserBase modfd on CBase.modifiedby=modfd.systemuserid
left outer join  stg_crm.ATOS_CITYBASE CTY ON CBase.atos_residencecity =  CTY.ATOS_CITYID
where atos_residenceaddressdetails is not null
 
UNION
 
select 
CBase.atos_customerId CIF,CBase.OriginatingLeadId ProspectID,CBase.ContactId BoardingID,
atos_businessaddressdetails ADDRESS,
CNTRY.ATOS_NAME COUNTRY,
CTY.ATOS_NAME CITY,
NULL STREET,
NULL BUILDING,
NULL DEPARTMENT,
NULL DESCRIPTION,
'BUSINESS_ADDRESS' ADDRESS_TYPE
--,CBase.ModifiedOn modifiedon
,cast(from_unixtime(CAST(CBase.modifiedon AS BIGINT) DIV 1000) as timestamp) modifiedon
,CBase.ModifiedBy modifiedbyid
,modfd.fullname modifiedbyname
,modfd.title modifiedbytitle
from stg_crm.ContactBase CBase
left outer join  stg_crm.ATOS_COUNTRYBASE CNTRY 
ON CBase.atos_businesscountry =  CNTRY.ATOS_COUNTRYID
left outer join  stg_crm.SystemUserBase modfd on CBase.modifiedby=modfd.systemuserid
left outer join  stg_crm.ATOS_CITYBASE CTY ON CBase.atos_businesscity =  CTY.ATOS_CITYID
where atos_businessaddressdetails is not null
 
UNION
 
select 
CBase.atos_customerId CIF,CBase.OriginatingLeadId ProspectID,CBase.ContactId BoardingID,
atos_communicationaddressdetails ADDRESS,
CNTRY.ATOS_NAME COUNTRY,
CTY.ATOS_NAME CITY,
atos_communicationarea STREET,
atos_communicationfloor BUILDING,
atos_communicationapartmentnumber DEPARTMENT,
atos_communicationadditionaladdressinfo DESCRIPTION,
'COMMUNICATION_ADDRESS' ADDRESS_TYPE
--,CBase.ModifiedOn modifiedon
,cast(from_unixtime(CAST(CBase.modifiedon AS BIGINT) DIV 1000) as timestamp) modifiedon
,CBase.ModifiedBy modifiedbyid
,modfd.fullname modifiedbyname
,modfd.title modifiedbytitle
from stg_crm.ContactBase CBase
left outer join  stg_crm.ATOS_COUNTRYBASE CNTRY ON CBase.atos_communicationcountry =  CNTRY.ATOS_COUNTRYID
left outer join  stg_crm.ATOS_CITYBASE CTY ON CBase.atos_communicationcity =  CTY.ATOS_CITYID
left outer join  stg_crm.SystemUserBase modfd on CBase.modifiedby=modfd.systemuserid
where atos_communicationaddressdetails is not null
 
UNION
 
select 
CBase.atos_customerId CIF,CBase.OriginatingLeadId ProspectID,CBase.ContactId BoardingID,
coalesce(ADDR.LINE1,'') || ' '||coalesce(ADDR.LINE2,'') || ' '||coalesce(ADDR.LINE3,'') ADDRESS,
coalesce(ADDR.COUNTRY,ADDR.COUNTY) COUNTRY,
ADDR.CITY CITY,
NULL STREET,
NULL BUILDING,
NULL DEPARTMENT,
coalesce(ADDR.NAME,'') || ' - '||coalesce(ADDR.PRIMARYCONTACTNAME,'')||' - '||coalesce(ADDR.COMPOSITE,'') DESCRIPTION,
'ADDRESS_'||cast(ADDR.ADDRESSNUMBER as String) ADDRESS_TYPE,
--ADDR.ModifiedOn modifiedon ,
cast(from_unixtime(CAST(ADDR.modifiedon AS BIGINT) DIV 1000) as timestamp) modifiedon,
ADDR.ModifiedBy ModifiedByID ,
modfd.fullname modifiedbyname,
modfd.title modifiedbytitle  
 
from stg_crm.ContactBase CBase
left outer join  stg_crm.CUSTOMERADDRESSBASE ADDR ON CBase.ContactId  = ADDR.PARENTID
left outer join  stg_crm.SystemUserBase modfd on ADDR.modifiedby=modfd.systemuserid
where coalesce(ADDR.LINE1,ADDR.LINE2,ADDR.LINE3,ADDR.COUNTRY,ADDR.COUNTY,ADDR.CITY) is not null
 
) base
) as stg

LEFT JOIN dwh_base.cust_address_info  mod
on  stg.HashCode =mod.HashCode 
and  stg.BoardingID = mod.BoardingID
and stg.address_type =mod.address_type 
 )src where  SRC.FK_UP <> 1  
)AS src
ON trg.HASHCODE = src.HashCode and trg.enddt IS NULL

WHEN MATCHED AND trg.enddt IS NULL THEN
  UPDATE SET enddt = cast(src.enddt as date),
  Tec_Upd_Dttm=CURRENT_TIMESTAMP

WHEN NOT MATCHED  and src.old_HashCode is null 
then
insert (
 CIF          
,ProspectID         
,BoardingID        
,ADDRESS            
,COUNTRY           
,CITY      
,STREET 
,BUILDING           
,DEPARTMENT   
,DESCRIPTION   
,ADDRESS_TYPE                
,modifiedbyid  
,modifiedbyname           
,modifiedbytitle 
,modifiedon 
,StartDT 
,Start_DT
,enddt
,HashCode
,Tec_Insrt_Dttm,Tec_Upd_Dttm,DR_Dttm,DR_Flg)

values (
 src.CIF          
,src.ProspectID         
,src.BoardingID        
,src.ADDRESS            
,src.COUNTRY           
,src.CITY      
,src.STREET 
,src.BUILDING           
,src.DEPARTMENT   
,src.DESCRIPTION   
,src.ADDRESS_TYPE                
,src.modifiedbyid    
,src.modifiedbyname           
,src.modifiedbytitle
,src.modifiedon      
,src.StartDT
,src.Start_DT
,src.enddt
,src.HashCode,
src.Tec_Insrt_Dttm,src.Tec_Upd_Dttm,src.DR_Dttm,src.DR_Flg
)
