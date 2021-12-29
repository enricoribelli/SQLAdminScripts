EXEC sp_change_users_login 
     'REPORT';

------------------------------------------------------------------------------------------------------------------------------
-- Check collations of database if different the Latin1_General_CI_AS fix it 
------------------------------------------------------------------------------------------------------------------------------
SELECT dbs.name
     , dbs.collation_name
FROM sys.databases AS dbs
WHERE dbs.name IN(DB_NAME(DB_ID())) AND dbs.collation_name <> 'Latin1_General_CI_AS';

------------------------------------------------------------------------------------------------------------------------------
-- Check compatibility level of the database
------------------------------------------------------------------------------------------------------------------------------
SELECT dbs.name, dbs.compatibility_level , sql_version_level = 
CASE dbs.compatibility_level
    WHEN 65  THEN 'SQL Server 6.5'
    WHEN 70  THEN 'SQL Server 7.0'
    WHEN 80  THEN 'SQL Server 2000'
    WHEN 90  THEN 'SQL Server 2005'
    WHEN 100 THEN 'SQL Server 2008/R2'
    WHEN 110 THEN 'SQL Server 2012'
    WHEN 120 THEN 'SQL Server 2014'
    WHEN 130 THEN 'SQL Server 2016'
    WHEN 140 THEN 'SQL Server 2017'
    WHEN 150 THEN 'SQL Server 2019'
    ELSE 'new unknown - '+CONVERT(varchar(10),compatibility_level)
END
FROM sys.databases dbs WHERE dbs.database_id = DB_ID();
-- ALTER DATABASE AVISOR SET COMPATIBILITY_LEVEL = 120; 

------------------------------------------------------------------------------------------------------------------------------
-- Check collations different from Latin1_General_CI_AS
------------------------------------------------------------------------------------------------------------------------------
SELECT t.object_id
     , OBJECT_SCHEMA_NAME(t.object_id) AS schemaname
     , OBJECT_NAME(t.object_id) AS tablename
     , c.name AS column_name
     , c.collation_name
FROM sys.tables AS t
     INNER JOIN sys.columns AS c
          ON c.object_id = t.object_id
             AND c.collation_name <> 'Latin1_General_CI_AS' -- Table needs to have columns with "wrong" collation
     INNER JOIN sys.types AS ty
          ON ty.system_type_id = c.system_type_id
             AND ty.name <> N'sysname'
WHERE t.is_ms_shipped = 0
GROUP BY t.object_id
       , c.name
       , c.collation_name;


------------------------------------------------------------------------------------------------------------------------------
-- Get refences in the databases
------------------------------------------------------------------------------------------------------------------------------
WITH Ref_Objects AS (
SELECT OBJECT_SCHEMA_NAME(referencing_id) AS referencing_schema_name
     , OBJECT_NAME(referencing_id) AS referencing_entity_name
     , o.type_desc AS referencing_desciption
     , COALESCE(COL_NAME(referencing_id, referencing_minor_id), '(n/a)') AS referencing_minor_id
     , referencing_class_desc
     , referenced_class_desc
     , referenced_server_name
     , referenced_database_name
     , referenced_schema_name
     , referenced_entity_name
     , COALESCE(COL_NAME(referenced_id, referenced_minor_id), '(n/a)') AS referenced_column_name
     , is_caller_dependent
     , is_ambiguous
	 , sm.definition AS script
FROM sys.sql_expression_dependencies AS sed
     INNER JOIN sys.objects AS o
          ON sed.referencing_id = o.object_id
		INNER JOIN sys.sql_modules AS sm ON sm.object_id = o.object_id

)
SELECT referenced_server_name, referenced_database_name
FROM Ref_Objects
GROUP BY referenced_server_name, referenced_database_name
ORDER BY referenced_server_name, referenced_database_name