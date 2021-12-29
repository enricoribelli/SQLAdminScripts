-- avg_fragmentation_in_percent: This is a percentage value that represents external fragmentation. For a clustered table and leaf level of index pages, this is Logical fragmentation, while for heap, this is Extent fragmentation. The lower this value, the better it is. If this value is higher than 10%, some corrective action should be taken.
-- avg_page_space_used_in_percent: This is an average percentage use of pages that represents to internal fragmentation. Higher the value, the better it is. If this value is lower than 75%, some corrective action should be taken.

SELECT 
	   --OBJECT_NAME(IDX.OBJECT_ID) AS Table_Name
	  SCHEMA_NAME(obj.schema_id) AS [schema_name]
	 , obj.name Table_Name
     , IDX.name AS Index_Name
     , IDXPS.index_type_desc AS Index_Type
     , IDXPS.page_count

	 , IDXPS.alloc_unit_type_desc 
	 , IDXPS.avg_page_space_used_in_percent
	 , IDXPS.avg_fragmentation_in_percent AS Fragmentation_Percentage, -- If this value is higher than 10%, some corrective action should be taken. (>5% <30% Index Reorganize) (>30% INDEX REBUILD)

	 'ALTER INDEX ['+IDX.name+'] ON ['+SCHEMA_NAME(obj.schema_id)+'].['+obj.name+'] REBUILD PARTITION = ALL WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 90)'

FROM sys.dm_db_index_physical_stats(DB_ID(), NULL, NULL, NULL, NULL) AS IDXPS
     INNER JOIN sys.indexes AS IDX
          ON IDX.object_id = IDXPS.object_id
             AND IDX.index_id = IDXPS.index_id
	 INNER JOIN sys.objects obj on obj.object_id = IDX.OBJECT_ID
WHERE IDXPS.avg_fragmentation_in_percent > 30
		--AND obj.name NOT LIKE '[_]%'
		AND IDXPS.alloc_unit_type_desc IN(N'IN_ROW_DATA', N'ROW_OVERFLOW_DATA')
		AND IDXPS.page_count > 1000
ORDER BY Fragmentation_Percentage DESC;


