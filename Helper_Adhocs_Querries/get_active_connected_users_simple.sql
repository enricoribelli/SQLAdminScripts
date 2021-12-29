/*

https://docs.microsoft.com/en-us/previous-versions/sql/sql-server-2008-r2/ms175519(v=sql.105)?redirectedfrom=MSDN

Shared (S)			= Used for read operations that do not change or update data, such as a SELECT statement.
Update (U)			= Used on resources that can be updated. Prevents a common form of deadlock that occurs when multiple sessions are reading, locking, and potentially updating resources later.
Exclusive (X)		= Used for data-modification operations, such as INSERT, UPDATE, or DELETE. Ensures that multiple updates cannot be made to the same resource at the same time.
Intent				= Used to establish a lock hierarchy. The types of intent locks are: intent shared (IS), intent exclusive (IX), and shared with intent exclusive (SIX).
Schema				= Used when an operation dependent on the schema of a table is executing. The types of schema locks are: schema modification (Sch-M) and schema stability (Sch-S).
Bulk Update (BU)		= Used when bulk copying data into a table and the TABLOCK hint is specified.
Key-range			= Protects the range of rows read by a query when using the serializable transaction isolation level. Ensures that other transactions cannot insert rows that would qualify 
						  for the queries of the serializable transaction if the queries were run again.

SET TRANSACTION ISOLATION LEVEL:
- READ UNCOMMITTED		= Specifies that statements can read rows that have been modified by other transactions but not yet committed.
- READ COMMITTED		= Specifies that statements cannot read data that has been modified but not committed by other transactions. This prevents dirty reads. 
						  Data can be changed by other transactions between individual statements within the current transaction, resulting in nonrepeatable reads or phantom data.
- REPEATABLE READ		= Specifies that statements cannot read data that has been modified but not yet committed by other transactions and that no other transactions can modify data 
						  that has been read by the current transaction until the current transaction completes.
- SNAPSHOT				= Specifies that data read by any statement in a transaction will be the transactionally consistent version of the data that existed at the start of the transaction. 
						  The transaction can only recognize data modifications that were committed before the start of the transaction. Data modifications made by other transactions after 
						  the start of the current transaction are not visible to statements executing in the current transaction. The effect is as if the statements in a transaction get a 
						  snapshot of the committed data as it existed at the start of the transaction.
- SERIALIZABLE			= 1. Statements cannot read data that has been modified but not yet committed by other transactions.
						  2. No other transactions can modify data that has been read by the current transaction until the current transaction completes.
						  3. Other transactions cannot insert new rows with key values that would fall in the range of keys read by any statements in the current transaction until the current transaction completes.

*/

SELECT objtype
     , cacheobjtype
     , AVG(usecounts) AS Avg_UseCount
     , SUM(refcounts) AS AllRefObjects
     , SUM(CAST(size_in_bytes AS BIGINT)) / 1024 / 1024 AS Size_MB
FROM sys.dm_exec_cached_plans
-- WHERE objtype = 'Adhoc'  AND usecounts = 1
GROUP BY objtype
       , cacheobjtype;

SELECT cplan.usecounts
     , cplan.objtype
     , qtext.text
     , qplan.query_plan
FROM sys.dm_exec_cached_plans AS cplan
     CROSS APPLY sys.dm_exec_sql_text(plan_handle) AS qtext
     CROSS APPLY sys.dm_exec_query_plan(plan_handle) AS qplan
WHERE objtype = 'Adhoc'  AND usecounts = 1
ORDER BY cplan.usecounts DESC;