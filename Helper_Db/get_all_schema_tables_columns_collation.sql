SELECT SCHEMA_NAME(o.schema_id) AS SchemaName
	 , ta.name AS TableName
     , c.name AS ColumnName
     , c.collation_name AS Collation_Name
FROM sys.columns AS c
     INNER JOIN sys.tables AS ta
          ON c.object_id = ta.object_id
     INNER JOIN sys.objects AS o
          ON c.object_id = o.object_id
     JOIN sys.types AS t
          ON c.system_type_id = t.system_type_id
     LEFT OUTER JOIN sys.index_columns AS ic
          ON ic.object_id = c.object_id
             AND ic.column_id = c.column_id
     LEFT OUTER JOIN sys.indexes AS i
          ON ic.object_id = i.object_id
             AND ic.index_id = i.index_id
WHERE c.collation_name IS NOT NULL
      AND c.collation_name <> 'Latin1_General_CI_AS'
GROUP BY SCHEMA_NAME(o.schema_id)
       , ta.name
       , c.name
       , c.collation_name;