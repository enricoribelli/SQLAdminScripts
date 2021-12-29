SELECT AvgCPU, AvgDuration, AvgReads, AvgCPUPerMinute,
       TotalCPU, TotalDuration, TotalReads,
       PercentCPU, PercentDuration, PercentReads, PercentExecutions,
       ExecutionCount,
       ExecutionsPerMinute,
       PlanCreationTime, LastExecutionTime,
       SUBSTRING(st.text,
                 (StatementStartOffset / 2) + 1,
                 ((CASE StatementEndOffset
                   WHEN -1 THEN DATALENGTH(st.text)
                   ELSE StatementEndOffset
                   END - StatementStartOffset) / 2) + 1) AS QueryText,
        st.Text FullText,
        query_plan AS QueryPlan,
        PlanHandle,
        StatementStartOffset,
        StatementEndOffset,
        MinReturnedRows,
        MaxReturnedRows,
        AvgReturnedRows,
        TotalReturnedRows,
        LastReturnedRows,
        DB_NAME(DatabaseId) AS CompiledOnDatabase
FROM (SELECT TOP (200) 
             total_worker_time / execution_count AS AvgCPU,
             total_elapsed_time / execution_count AS AvgDuration,
             total_logical_reads / execution_count AS AvgReads,
             Cast(total_worker_time / age_minutes As BigInt) AS AvgCPUPerMinute,
             execution_count / age_minutes AS ExecutionsPerMinute,
             Cast(total_worker_time / age_minutes_lifetime As BigInt) AS AvgCPUPerMinuteLifetime,
             execution_count / age_minutes_lifetime AS ExecutionsPerMinuteLifetime,
             total_worker_time AS TotalCPU,
             total_elapsed_time AS TotalDuration,
             total_logical_reads AS TotalReads,
             execution_count ExecutionCount,
             CAST(ROUND(100.00 * total_worker_time / t.TotalWorker, 2) AS MONEY) AS PercentCPU,
             CAST(ROUND(100.00 * total_elapsed_time / t.TotalElapsed, 2) AS MONEY) AS PercentDuration,
             CAST(ROUND(100.00 * total_logical_reads / t.TotalReads, 2) AS MONEY) AS PercentReads,
             CAST(ROUND(100.00 * execution_count / t.TotalExecs, 2) AS MONEY) AS PercentExecutions,
             qs.creation_time AS PlanCreationTime,
             qs.last_execution_time AS LastExecutionTime,
             qs.plan_handle AS PlanHandle,
             qs.statement_start_offset AS StatementStartOffset,
             qs.statement_end_offset AS StatementEndOffset,
             qs.min_rows AS MinReturnedRows,
             qs.max_rows AS MaxReturnedRows,
             CAST(qs.total_rows as MONEY) / execution_count AS AvgReturnedRows,
             qs.total_rows AS TotalReturnedRows,
             qs.last_rows AS LastReturnedRows,
             qs.sql_handle AS SqlHandle,
             Cast(pa.value as Int) DatabaseId
        FROM (SELECT *, 
                     CAST((CASE WHEN DATEDIFF(second, creation_time, GETDATE()) > 0 And execution_count > 1
                                THEN DATEDIFF(second, creation_time, GETDATE()) / 60.0
                                ELSE Null END) as MONEY) as age_minutes, 
                     CAST((CASE WHEN DATEDIFF(second, creation_time, last_execution_time) > 0 And execution_count > 1
                                THEN DATEDIFF(second, creation_time, last_execution_time) / 60.0
                                ELSE Null END) as MONEY) as age_minutes_lifetime
                FROM sys.dm_exec_query_stats) AS qs
             CROSS JOIN(SELECT SUM(execution_count) TotalExecs,
                               SUM(total_elapsed_time) TotalElapsed,
                               SUM(total_worker_time) TotalWorker,
                               SUM(total_logical_reads) TotalReads
                          FROM sys.dm_exec_query_stats) AS t
             CROSS APPLY sys.dm_exec_plan_attributes(qs.plan_handle) AS pa
     WHERE pa.attribute = 'dbid') sq
    CROSS APPLY sys.dm_exec_sql_text(SqlHandle) AS st
    CROSS APPLY sys.dm_exec_query_plan(PlanHandle) AS qp
order by PercentCPU