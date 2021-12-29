-- Page Life Expectancy (PLE) value for each NUMA node in current instance  (Query 46) (PLE by NUMA Node)
SELECT @@SERVERNAME AS [Server Name], RTRIM([object_name]) AS [Object Name], instance_name, cntr_value AS [Page Life Expectancy]
FROM sys.dm_os_performance_counters WITH (NOLOCK)
WHERE [object_name] LIKE N'%Buffer Node%' -- Handles named instances
AND counter_name = N'Page life expectancy' OPTION (RECOMPILE);



------
-- You want to see "Available physical memory is high" for System Memory State
-- This indicates that you are not under external memory pressure
-- Possible System Memory State values:
-- Available physical memory is high
-- Physical memory usage is steady
-- Available physical memory is low
-- Available physical memory is running low
-- Physical memory state is transitioning
-- !!! Good basic information about OS memory amounts and state  (Query 14) (System Memory)
SELECT total_physical_memory_kb/1024 AS [Physical Memory (MB)], 
       available_physical_memory_kb/1024 AS [Available Memory (MB)], 
       total_page_file_kb/1024 AS [Total Page File (MB)], 
       available_page_file_kb/1024 AS [Available Page File (MB)], 
       system_cache_kb/1024 AS [System Cache (MB)],
       system_memory_state_desc AS [System Memory State]
FROM sys.dm_os_sys_memory WITH (NOLOCK) OPTION (RECOMPILE);



------
-- Run multiple times, and run periodically if you suspect you are under memory pressure
-- Memory Grants Pending above zero for a sustained period is a very strong indicator of internal memory pressure
-- Memory Grants Pending value for current instance  (Query 47) (Memory Grants Pending)
SELECT @@SERVERNAME AS [Server Name]
     , RTRIM([object_name]) AS [Object Name]
     , cntr_value AS [Memory Grants Pending]
FROM sys.dm_os_performance_counters WITH(NOLOCK)
WHERE [object_name] LIKE N'%Memory Manager%' -- Handles named instances
      AND counter_name = N'Memory Grants Pending' OPTION(RECOMPILE);

------
-- This helps you find the most expensive cached stored procedures from a memory perspective
-- You should look at this if you see signs of memory pressure
-- Top Cached SPs By Total Logical Reads. Logical reads relate to memory pressure  (Query 62) (SP Logical Reads)
SELECT TOP (25) p.name AS [SP Name]
              , qs.total_logical_reads AS [TotalLogicalReads]
              , qs.total_logical_reads / qs.execution_count AS [AvgLogicalReads]
              , qs.execution_count
              , ISNULL(qs.execution_count / DATEDIFF(Minute, qs.cached_time, GETDATE()), 0) AS [Calls/Minute]
              , qs.total_elapsed_time
              , qs.total_elapsed_time / qs.execution_count AS [avg_elapsed_time]
              , CASE
                    WHEN CONVERT(NVARCHAR(MAX), qp.query_plan) LIKE N'%<MissingIndexes>%' THEN 1
                    ELSE 0
                END AS [Has Missing Index]
              , qs.last_execution_time AS [Last Execution Time]
              , qs.cached_time AS [Plan Cached Time]
-- ,qp.query_plan AS [Query Plan] -- Uncomment if you want the Query Plan
FROM sys.procedures AS p WITH(NOLOCK)
     INNER JOIN sys.dm_exec_procedure_stats AS qs WITH(NOLOCK)
          ON p.[object_id] = qs.[object_id]
     CROSS APPLY sys.dm_exec_query_plan(qs.plan_handle) AS qp
WHERE qs.database_id = DB_ID()
      AND DATEDIFF(Minute, qs.cached_time, GETDATE()) > 0
ORDER BY qs.total_logical_reads DESC OPTION(RECOMPILE);


------
-- This helps you find the most expensive cached stored procedures from a read I/O perspective
-- You should look at this if you see signs of I/O pressure or of memory pressure
-- Top Cached SPs By Total Physical Reads. Physical reads relate to disk read I/O pressure  (Query 63) (SP Physical Reads)
SELECT TOP(25) p.name AS [SP Name],qs.total_physical_reads AS [TotalPhysicalReads], 
qs.total_physical_reads/qs.execution_count AS [AvgPhysicalReads], qs.execution_count, 
qs.total_logical_reads,qs.total_elapsed_time, qs.total_elapsed_time/qs.execution_count AS [avg_elapsed_time],
CASE WHEN 
	CONVERT(nvarchar(max), qp.query_plan) LIKE N'%<MissingIndexes>%' THEN 1 ELSE 0 END AS [Has Missing Index],
	qs.last_execution_time AS [Last Execution Time], 
	qs.cached_time AS [Plan Cached Time]
-- ,qp.query_plan AS [Query Plan] -- Uncomment if you want the Query Plan 
FROM sys.procedures AS p WITH (NOLOCK)
INNER JOIN sys.dm_exec_procedure_stats AS qs WITH (NOLOCK)
ON p.[object_id] = qs.[object_id]
CROSS APPLY sys.dm_exec_query_plan(qs.plan_handle) AS qp
WHERE qs.database_id = DB_ID()
AND qs.total_physical_reads > 0
ORDER BY qs.total_physical_reads DESC, qs.total_logical_reads DESC OPTION (RECOMPILE);




------
-- This helps you find the most expensive cached stored procedures from a write I/O perspective
-- You should look at this if you see signs of I/O pressure or of memory pressure
-- Top Cached SPs By Total Logical Writes (Query 64) (SP Logical Writes)
-- Logical writes relate to both memory and disk I/O pressure 
SELECT TOP (25) p.name AS [SP Name]
              , qs.total_logical_writes AS [TotalLogicalWrites]
              , qs.total_logical_writes / qs.execution_count AS [AvgLogicalWrites]
              , qs.execution_count
              , ISNULL(qs.execution_count / DATEDIFF(Minute, qs.cached_time, GETDATE()), 0) AS [Calls/Minute]
              , qs.total_elapsed_time
              , qs.total_elapsed_time / qs.execution_count AS [avg_elapsed_time]
              , CASE
                    WHEN CONVERT(NVARCHAR(MAX), qp.query_plan) LIKE N'%<MissingIndexes>%' THEN 1
                    ELSE 0
                END AS [Has Missing Index]
              , qs.last_execution_time AS [Last Execution Time]
              , qs.cached_time AS [Plan Cached Time]
-- ,qp.query_plan AS [Query Plan] -- Uncomment if you want the Query Plan 
FROM sys.procedures AS p WITH(NOLOCK)
     INNER JOIN sys.dm_exec_procedure_stats AS qs WITH(NOLOCK)
          ON p.[object_id] = qs.[object_id]
     CROSS APPLY sys.dm_exec_query_plan(qs.plan_handle) AS qp
WHERE qs.database_id = DB_ID()
      AND qs.total_logical_writes > 0
      AND DATEDIFF(Minute, qs.cached_time, GETDATE()) > 0
ORDER BY qs.total_logical_writes DESC OPTION(RECOMPILE);