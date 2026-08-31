
select 
	t.tlogid			as	trx_key
	,progname			as	prog_nm
	,dbgtext			as	descr
	,current_timestamp	as	ins_dttm
	,current_date       as ins_dt,
t.tec_insrt_dttm,
t.tec_upd_dttm,
t.dr_dttm,
t.dr_flg
from (select * from (select *, row_number() over(partition by tlogid order by tec_insrt_dttm desc) r 
from ${stg_schema}.tlogerr)a where a.r=1) t
