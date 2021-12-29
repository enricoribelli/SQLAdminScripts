SELECT TOP 100 
	sqlText.text AS query
    , aStat.last_execution_time AS last_execution_time
    , users.name AS UserName
    , CAST(((aStat.total_elapsed_time % (1000 * 60 * 60)) % (1000 * 60)) / 1000 AS VARCHAR) AS total_elapsed_time_in_sec
    , aStat.total_rows
FROM sys.dm_exec_query_stats AS aStat
	CROSS APPLY sys.dm_exec_plan_attributes(aStat.plan_handle) AS planAttr
	CROSS APPLY sys.dm_exec_sql_text(aStat.sql_handle) AS sqlText
	INNER JOIN sys.sysusers AS users ON users.uid = planAttr.value --and b.attribute = 'USER_ID'
WHERE(((aStat.total_elapsed_time % (1000 * 60 * 60)) % (1000 * 60)) / 1000) > 10
ORDER BY aStat.total_elapsed_time DESC;