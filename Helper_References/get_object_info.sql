SELECT sm.object_id
     , sch.name
     , OBJECT_NAME(sm.object_id) AS object_name
     , o.type
     , o.type_desc
     , sm.definition
FROM sys.sql_modules AS sm
     JOIN sys.objects AS o ON sm.object_id = o.object_id
     INNER JOIN sys.schemas AS sch ON sch.schema_id = o.schema_id
WHERE  sm.definition LIKE '%new%'
ORDER BY object_name;