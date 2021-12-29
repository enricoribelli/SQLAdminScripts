

SELECT objtype
     , cacheobjtype
     , AVG(usecounts) AS Avg_UseCount
     , SUM(refcounts) AS AllRefObjects
     , SUM(CAST(size_in_bytes AS BIGINT)) / 1024 / 1024 AS Size_MB
FROM sys.dm_exec_cached_plans

-- Prepared = A prepared query is parameterized and can be reused for a range of different inputs.
-- Adhoc = An Adhoc query is hard coded or the dynamically executed, and the cached plan can only be re-used for a near identical statement.

-- WHERE objtype = 'Adhoc'  AND usecounts = 1

GROUP BY objtype
       , cacheobjtype;

SELECT cplan.usecounts
     , cplan.objtype
     , qtext.text
	 , DB_NAME(qtext.dbid)
     , qplan.query_plan
FROM sys.dm_exec_cached_plans AS cplan
     CROSS APPLY sys.dm_exec_sql_text(plan_handle) AS qtext
     CROSS APPLY sys.dm_exec_query_plan(plan_handle) AS qplan
--WHERE objtype = 'Adhoc'  AND usecounts = 1
ORDER BY cplan.usecounts DESC;