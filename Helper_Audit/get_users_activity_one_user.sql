select 
	s.session_id,
	s.host_name,
	s.program_name,
	s.client_interface_name,
	s.login_name,
	s.nt_domain,
	s.nt_user_name,
	c.client_net_address,
	c.local_net_address,
	c.connection_id,
	c.parent_connection_id,
	c.most_recent_sql_handle,
	(select text from master.sys.dm_exec_sql_text(c.most_recent_sql_handle )) as sqlscript,
	(select db_name(dbid) from master.sys.dm_exec_sql_text(c.most_recent_sql_handle )) as databasename,
	(select object_id(objectid) from master.sys.dm_exec_sql_text(c.most_recent_sql_handle )) as objectname
from sys.dm_exec_sessions s
	inner join sys.dm_exec_connections c
		on c.session_id=s.session_id

where s.login_name='RDLC\C46716' -- *** change to user name