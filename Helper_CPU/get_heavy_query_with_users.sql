with users_cte as (
SELECT 
	   server_users.sid as server_login_sid
	 , server_users.principal_id as server_login_principal_id
	 , server_users.name as server_login
     , CASE
        WHEN server_users.is_disabled = 1 THEN 'Disabled'
        ELSE 'Enabled'
       END as login_status
	 , member_users.sid db_user_sid 
	 , member_users.principal_id db_user_principal_id
     , member_users.name db_user 
     , member_users.type_desc db_user_type_desc 
     , rolp.name db_role 
FROM sys.database_role_members AS mmbr
     INNER JOIN sys.database_principals AS rolp -- The DB Roles names table
          ON rolp.[principal_id] = mmbr.[role_principal_id]
     LEFT OUTER JOIN sys.database_principals AS member_users -- The DB users names table
          ON member_users.[principal_id] = mmbr.[member_principal_id]
     LEFT OUTER JOIN sys.server_principals AS server_users -- The Login accounts table
          ON member_users.[sid] = server_users.[sid]

)
SELECT TOP 5 qs.sql_handle
           , rq.user_id
           , users.db_user
           , users.db_user_type_desc
           , c.client_net_address
           , c.connect_time
           , c.local_net_address
           , qt.dbid
           , DB_NAME(qt.dbid) AS DatabaseName
           , DATEDIFF(MI, creation_time, GETDATE()) AS [Age of the Plan(Minutes)]
           , last_execution_time AS [Last Execution Time]
           , qs.execution_count AS [Total Execution Count]
           , CAST((qs.total_elapsed_time) / 1000000.0 AS DECIMAL(28, 2)) AS [Total Elapsed Time(s)]
           , CAST((qs.total_elapsed_time) / 1000000.0 / qs.execution_count AS DECIMAL(28, 2)) AS [Average Execution time(s)]
           , CAST((qs.total_worker_time) / 1000000.0 AS DECIMAL(28, 2)) AS [Total CPU time (s)]
           , CAST(qs.total_worker_time * 100.0 / qs.total_elapsed_time AS DECIMAL(28, 2)) AS [% CPU]
           , CAST((qs.total_elapsed_time - qs.total_worker_time) * 100.0 / qs.total_elapsed_time AS DECIMAL(28, 2)) AS [% Waiting]
           , CAST((qs.total_worker_time) / 1000000.0 / qs.execution_count AS DECIMAL(28, 2)) AS [CPU time average (s)]
           , CAST((qs.total_physical_reads) / qs.execution_count AS DECIMAL(28, 2)) AS [Avg Physical Read]
           , CAST((qs.total_logical_reads) / qs.execution_count AS DECIMAL(28, 2)) AS [Avg Logical Reads]
           , CAST((qs.total_logical_writes) / qs.execution_count AS DECIMAL(28, 2)) AS [Avg Logical Writes]
           , max_physical_reads
           , max_logical_reads
           , max_logical_writes
           , SUBSTRING(qt.TEXT, (qs.statement_start_offset / 2) + 1, ((CASE
                                                                           WHEN qs.statement_end_offset = -1 THEN LEN(CONVERT(NVARCHAR(MAX), qt.TEXT)) * 2
                                                                           ELSE qs.statement_end_offset
                                                                       END - qs.statement_start_offset) / 2) + 1) AS [Individual Query]
           , qt.TEXT AS [Batch Statement]
           , qp.query_plan
FROM SYS.DM_EXEC_QUERY_STATS AS qs
     CROSS APPLY SYS.DM_EXEC_SQL_TEXT(qs.sql_handle) AS qt
     CROSS APPLY SYS.DM_EXEC_QUERY_PLAN(qs.plan_handle) AS qp
     LEFT OUTER JOIN sys.dm_exec_requests AS rq
          ON rq.sql_handle = qs.sql_handle
     LEFT OUTER JOIN sys.dm_exec_connections AS c
          ON rq.session_id = c.session_id
     LEFT OUTER JOIN users_cte AS users
          ON users.db_user_principal_id = rq.[user_id]
WHERE qs.total_elapsed_time > 0
ORDER BY [Total CPU time (s)] 
         --[Avg Physical Read]
         --[Avg Logical Reads]
         --[Avg Logical Writes]
         --[Total Elapsed Time(s)]
         --[Total Execution Count]
         DESC;