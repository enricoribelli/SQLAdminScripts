
WITH references_CTE
     AS (SELECT SCHEMA_NAME(refrencing.SCHEMA_ID) AS referencing_schema_name
              , refrencing.name AS referencing_object_name
              , refrencing.type_desc AS referencing_object_type_desc
              , referenced_schema_name
              , referenced_object_name = referenced_entity_name
              , referenced_object_type_desc = referenced.type_desc
              , referenced_server_name
              , referenced_database_name
         --,sed.* -- Uncomment for all the columns
         FROM sys.sql_expression_dependencies AS sed
              INNER JOIN sys.objects AS refrencing
                   ON sed.referencing_id = refrencing.[object_id]
              LEFT OUTER JOIN sys.objects AS referenced
                   ON sed.referenced_id = referenced.[object_id]) 
     --SELECT referenced_server_name
     --FROM references_CTE refs
     --WHERE refs.referenced_server_name is not null
     --GROUP BY referenced_server_name

     SELECT refs.referenced_database_name
          , referenced_server_name
     FROM references_CTE AS refs
     WHERE refs.referenced_database_name IS NOT NULL
           AND refs.referenced_server_name IS NOT NULL
     GROUP BY refs.referenced_database_name
            , referenced_server_name;
