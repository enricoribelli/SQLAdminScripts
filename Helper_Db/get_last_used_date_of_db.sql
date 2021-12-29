DECLARE @DatabasesLastAccess TABLE
(
  DatabaseName VARCHAR(50),
  last_execution_time DATETIME,
  execution_count BIGINT
)

INSERT  INTO @DatabasesLastAccess (DatabaseName, last_execution_time, execution_count)
exec sp_MSforeachdb @command1 = 'use [?]
SELECT 
	TOP 1 
	 DB_NAME() as DatabaseName
	,last_execution_time
	,execution_count
	--,plan_generation_num
	--,total_worker_time
	--,last_worker_time
	--,min_worker_time
	--,max_worker_time
	--,total_physical_reads
	--,last_physical_reads
	--,min_physical_reads
	--,max_physical_reads
	--,total_logical_writes
	--,last_logical_writes
	--,min_logical_writes
	--,max_logical_writes
	--s1.sql_handle,
	--,(SELECT TOP 1 SUBSTRING(s2.text,statement_start_offset / 2+1 ,
	--	((CASE WHEN statement_end_offset = -1
	--			THEN (LEN(CONVERT(nvarchar(max),s2.text)) * 2)
	--			ELSE statement_end_offset END) - statement_start_offset) / 2+1)) AS sql_statement
FROM sys.dm_exec_query_stats AS s1
	CROSS APPLY sys.dm_exec_sql_text(s1.sql_handle) AS s2
WHERE s2.objectid is null
ORDER BY last_execution_time desc
		--,s1.sql_handle, s1.statement_start_offset, s1.statement_end_offset';

SELECT * FROM @DatabasesLastAccess