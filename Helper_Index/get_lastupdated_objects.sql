-- LAST UPDATED
----------------------------------------------------------------------------------------------
SELECT t.Name AS Tabelname, p.rows AS NoOfRows, MAX(us.last_user_lookup) AS LastUsed, t.create_date AS CreatedDate
FROM sys.tables t
INNER JOIN      
    sys.indexes i ON t.OBJECT_ID = i.object_id
INNER JOIN 
    sys.partitions p ON i.object_id = p.OBJECT_ID AND i.index_id = p.index_id
LEFT JOIN --A lot of the tables did not have any records in this table
    sys.dm_db_index_usage_stats as us ON t.OBJECT_ID = us.OBJECT_ID
GROUP BY t.Name, p.rows, create_date
ORDER BY MAX(us.last_user_lookup) DESC