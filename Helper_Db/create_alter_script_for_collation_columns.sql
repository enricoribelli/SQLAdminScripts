SELECT Row_number() 
        OVER ( 
        ORDER BY c.column_id) AS row_id, 
    Schema_name(o.schema_id)  schema_n, 
    ta.NAME                   table_name, 
    c.NAME                    column_name, 
    t.NAME                    data_type, 
    c.max_length, 
    CASE 
        WHEN c.max_length = -1 
            OR ( c.max_length > 4000 ) THEN 4000 
        ELSE c.max_length 
    END                       new_max_length, 
    c.column_id, 
    c.collation_name, 
    'Latin1_General_CI_AS'            dest_collation_name 
FROM   sys.columns c 
    INNER JOIN sys.tables ta 
            ON c.object_id = ta.object_id 
    INNER JOIN sys.objects o 
            ON c.object_id = o.object_id 
    JOIN sys.types t 
        ON c.system_type_id = t.system_type_id 
    LEFT OUTER JOIN sys.index_columns ic 
                ON ic.object_id = c.object_id 
                    AND ic.column_id = c.column_id 
    LEFT OUTER JOIN sys.indexes i 
                ON ic.object_id = i.object_id 
                    AND ic.index_id = i.index_id 
