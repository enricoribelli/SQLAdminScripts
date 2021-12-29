SELECT top 100 * FROM sys.dm_db_index_physical_stats(DB_ID(), NULL, NULL, NULL, 'SAMPLED') 

--maintains only the indexes that have average fragmentation percentage equal or higher from the given value
DECLARE @fragmentationThreshold VARCHAR(10);
SET @fragmentationThreshold = 15;

--fill factor - the percentage of the data page to be filled up with index data
DECLARE @indexFillFactor VARCHAR(5);
SET @indexFillFactor = 90;

--sets the scanning mode for index statistics 
--available values: 'DEFAULT', NULL, 'LIMITED', 'SAMPLED', or 'DETAILED'
DECLARE @indexStatisticsScanningMode VARCHAR(20);
SET @indexStatisticsScanningMode = 'SAMPLED';
DECLARE @sortInTempdb VARCHAR(3);
--if set to ON: sorts intermediate index results in TempDB 
--if set to OFF: sorts intermediate index results in user database's log file
SET @sortInTempdb = 'ON';

SELECT 
	   TOP(10000)
	   DB_NAME() AS [dbName]

     , tbl.name AS [tableName]
	 , pst.page_count
	 
	 , SCHEMA_NAME(tbl.schema_id) AS schemaName
     , idx.Name AS [indexName]
     , pst.database_id AS [databaseID]
     , pst.object_id AS [objectID]
     , pst.index_id AS [indexID]
     , pst.avg_fragmentation_in_percent AS [AvgFragmentationPercentage]
     , CASE
           WHEN pst.avg_fragmentation_in_percent > 30 THEN 'ALTER INDEX [' + idx.Name + '] ON [' + DB_NAME() + '].[' + SCHEMA_NAME(tbl.schema_id) + '].[' + tbl.name + '] REBUILD WITH (FILLFACTOR = ' + @indexFillFactor + ', SORT_IN_TEMPDB = ' + @sortInTempdb + ', STATISTICS_NORECOMPUTE = OFF);'
           WHEN pst.avg_fragmentation_in_percent > 5
                AND pst.avg_fragmentation_in_percent <= 30 THEN 'ALTER INDEX [' + idx.Name + '] ON [' + DB_NAME() + '].[' + SCHEMA_NAME(tbl.schema_id) + '].[' + tbl.name + '] REORGANIZE;'
           ELSE NULL
       END alter_script
FROM sys.dm_db_index_physical_stats(DB_ID(), NULL, NULL, NULL, '' + @indexStatisticsScanningMode + '') AS pst
     INNER JOIN sys.tables AS tbl
          ON pst.object_id = tbl.object_id
     INNER JOIN sys.indexes AS idx
          ON pst.object_id = idx.object_id
             AND pst.index_id = idx.index_id
WHERE pst.index_id != 0
      AND pst.alloc_unit_type_desc IN(N'IN_ROW_DATA', N'ROW_OVERFLOW_DATA')
	  --AND pst.avg_fragmentation_in_percent >= @fragmentationThreshold
	  AND pst.page_count>1000
--ORDER BY pst.page_count DESC