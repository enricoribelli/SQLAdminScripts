-- Sometime you may need to find out who ran some script or who is accessing the database 
-- or who made some modification or deleted some data or updated some data. Even you will 
-- get the host name from where the query was executed and what time the query was started to execute.

-- You don’t have anything database auditing setup or trace flag enables. In that case, you can make use of
-- the default trace running on the SQL instance.

-- get trace path
select * from ::fn_trace_getinfo(default)
-- copy path above of result 
-- should be like 'C:\Program Files\Microsoft SQL Server\MSSQL14.MSSQLSERVER\MSSQL\Log\log_88.trc'

-- update path below and group users
select LoginName
from fn_trace_gettable('C:\Program Files\Microsoft SQL Server\MSSQL13.MSSQLSERVER\MSSQL\Log\log_254.trc',default) -- example of the filename taken from the above query
group by LoginName

-- get user details
select LoginName, * 
from fn_trace_gettable('C:\Program Files\Microsoft SQL Server\MSSQL13.MSSQLSERVER\MSSQL\Log\log_254.trc',default) -- example of the filename taken from the above query
where LoginName like '%RDLC\C46716%'   --user name to be searched