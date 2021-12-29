https://docs.microsoft.com/en-us/sql/relational-databases/stored-procedures/view-the-dependencies-of-a-stored-procedure?view=sql-server-ver15

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
SELECT referenced_server_name, referenced_database_name, referenced_schema_name, referenced_entity_name
FROM Ref_Objects
--WHERE referenced_server_name IS NOT NULL 
	-- AND referenced_database_name IS NOT NULL 
GROUP BY referenced_server_name, referenced_database_name, referenced_schema_name, referenced_entity_name
ORDER BY referenced_server_name, referenced_database_name, referenced_schema_name, referenced_entity_name