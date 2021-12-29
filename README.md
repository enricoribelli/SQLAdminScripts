<img src="microsoft-sql-server-logo.png" width="300px" align="right" />

# Table of Contents
1. [SqlHelper](#SqlHelper)

# SqlHelper
**SqlHelper** is list of scripts with SQL Server best practice, administration, development and migration commands included. Currently, other components of SQL Server such as SSIS, SSRS and SSAS are not supported, but they are part of the overall goal.

The goal is to have helper scripts to read out sql server.

# Permission

There are two types of dynamic management views and functions:
- Server-scoped dynamic management views and functions. 
  Permission needed: VIEW SERVER STATE, SELECT 
- Database-scoped dynamic management views and functions.
  Permission needed: VIEW DATABASE STATE, SELECT 
  
# General

https://docs.microsoft.com/en-us/sql/relational-databases/system-dynamic-management-views/system-dynamic-management-views?view=sql-server-ver15
  
-> sys.dm_exec_sessions (Server Scoped)
Returns one row per authenticated session on SQL Server. Shows information about all active user connections and internal tasks. 
https://docs.microsoft.com/en-us/sql/relational-databases/system-dynamic-management-views/sys-dm-exec-sessions-transact-sql?view=sql-server-ver15

-> sys.dm_exec_connections
Returns information about the connections established to this instance of SQL Server and the details of each connection.
https://docs.microsoft.com/en-us/sql/relational-databases/system-dynamic-management-views/sys-dm-exec-connections-transact-sql?view=sql-server-ver15

-> sys.dm_db_index_physical_stats (Transact-SQL)
Returns size and fragmentation information for the data and indexes of the specified table or view in SQL Server.
https://docs.microsoft.com/en-us/sql/relational-databases/system-dynamic-management-views/sys-dm-db-index-physical-stats-transact-sql?view=sql-server-ver15

-> sys.dm_db_index_usage_stats (Transact-SQL)
Returns counts of different types of index operations and the time each type of operation was last performed.
https://docs.microsoft.com/en-us/sql/relational-databases/system-dynamic-management-views/sys-dm-db-index-usage-stats-transact-sql?view=sql-server-ver15

--> sys.dm_exec_sql_text
Returns the text of the SQL batch that is identified by the specified sql_handle.
https://docs.microsoft.com/en-us/sql/relational-databases/system-dynamic-management-views/sys-dm-exec-sql-text-transact-sql?view=sql-server-ver15

--> sys.dm_exec_requests
Returns information about each request that is executing in SQL Server.
https://docs.microsoft.com/en-us/sql/relational-databases/system-dynamic-management-views/sys-dm-exec-requests-transact-sql?view=sql-server-ver15



equality_columns = "StateProvinceID", this is because this column is used in the WHERE clause with an equals operator.  So SQL Server is telling us this would be a good candidate for an index.
inequality_columns = "NULL", this column will have data if you use other operators such as not equal, but since we are using equals there are no columns that could be used here 
included_columns = this is additional columns that could be used when the index is created.  Since the query only uses City, StateProvinceID and PostalCode, the StateProvinceID will be handled in the index and the other two columns could be used as included columns when the index is created.  Take a look at this tip for more information about included columns.
