SELECT 
    t.NAME AS TableName,
    s.Name AS SchemaName,
    p.rows AS RowCounts,
    SUM(a.total_pages) * 8 AS TotalSpaceKB, 
    CAST(ROUND(((SUM(a.total_pages) * 8) / 1024.00), 2) AS NUMERIC(36, 2)) AS TotalSpaceMB,
	CAST(ROUND((((SUM(a.total_pages) * 8) / 1024.00) /1024 ), 2) AS NUMERIC(36, 2)) AS TotalSpaceGB,
    
	SUM(a.used_pages) * 8 AS UsedSpaceKB, 
    CAST(ROUND(((SUM(a.used_pages) * 8) / 1024.00), 2) AS NUMERIC(36, 2)) AS UsedSpaceMB, 
	CAST(ROUND((((SUM(a.used_pages) * 8) / 1024.00)/1024), 2) AS NUMERIC(36, 2)) AS UsedSpaceGB, 

    (SUM(a.total_pages) - SUM(a.used_pages)) * 8 AS UnusedSpaceKB,
    CAST(ROUND(((SUM(a.total_pages) - SUM(a.used_pages)) * 8) / 1024.00, 2) AS NUMERIC(36, 2)) AS UnusedSpaceMB

FROM 
    sys.tables t
INNER JOIN      
    sys.indexes i ON t.OBJECT_ID = i.object_id
INNER JOIN 
    sys.partitions p ON i.object_id = p.OBJECT_ID AND i.index_id = p.index_id
INNER JOIN 
    sys.allocation_units a ON p.partition_id = a.container_id
LEFT OUTER JOIN 
    sys.schemas s ON t.schema_id = s.schema_id
WHERE 
    t.NAME NOT LIKE 'dt%' 
    AND t.is_ms_shipped = 0
    AND i.OBJECT_ID > 255 
GROUP BY 
    t.Name, s.Name, p.Rows
ORDER BY 
    TotalSpaceMB DESC, t.Name



	WITH cte AS (
SELECT t.name AS TableName
            , SUM(s.used_page_count) AS used_pages_count
            , SUM(CASE
                    WHEN(i.index_id < 2) THEN (in_row_data_page_count + lob_used_page_count + row_overflow_used_page_count)
                    ELSE lob_used_page_count + row_overflow_used_page_count
                END) AS pages
        FROM sys.dm_db_partition_stats AS s
            JOIN sys.tables AS t
                ON s.object_id = t.object_id
            JOIN sys.indexes AS i
                ON i.[object_id] = t.[object_id]
                    AND s.index_id = i.index_id
        GROUP BY t.name)
    SELECT cte.TableName
        , CAST((cte.pages * 8.) / 1024 AS DECIMAL(10, 3)) AS TableSizeInMB
        , CAST(((CASE
                    WHEN cte.used_pages_count > cte.pages THEN cte.used_pages_count - cte.pages
                    ELSE 0
                END) * 8. / 1024) AS DECIMAL(10, 3)) AS IndexSizeInMB
    FROM cte
    ORDER BY 2 DESC;