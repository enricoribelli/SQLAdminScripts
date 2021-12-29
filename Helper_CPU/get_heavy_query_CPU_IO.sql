SELECT TOP 20 DB_NAME(qt.dbid) AS DatabaseName
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
WHERE qs.total_elapsed_time > 0
ORDER BY [Total CPU time (s)] 
         --[Avg Physical Read]
         --[Avg Logical Reads]
         --[Avg Logical Writes]
         --[Total Elapsed Time(s)]
         --[Total Execution Count]
DESC;