-- [BIS_NAV2009_P] 
-- Data+Log		Drive -> T: 
-- TEMP_DB		Drive -> L:
-- MSDB			Drive -> S:
-- MASTER		Drive -> S:


/*
-- Volume info for all LUNS that have database files on the current instance (Query 1)
-- Shows you the total and free space on the LUNs where you have database files
	- Free space is good for performance 
*/
SELECT DISTINCT 
       vs.volume_mount_point
     , vs.file_system_type
     , vs.logical_volume_name
     , CONVERT(DECIMAL(18, 2), vs.total_bytes / 1073741824.0) AS [Total Size (GB)]
     , CONVERT(DECIMAL(18, 2), vs.available_bytes / 1073741824.0) AS [Available Size (GB)]
     , CAST(CAST(vs.available_bytes AS FLOAT) / CAST(vs.total_bytes AS FLOAT) AS DECIMAL(18, 2)) * 100 AS [Space Free %]
FROM sys.master_files AS f WITH(NOLOCK)
     CROSS APPLY sys.dm_os_volume_stats(f.database_id, f.[file_id]) AS vs
ORDER BY vs.volume_mount_point OPTION(RECOMPILE);


-- Drive level latency information (Query 2)
SELECT [Drive],
	CASE 
		WHEN num_of_reads = 0 THEN 0 
		ELSE (io_stall_read_ms/num_of_reads) 
	END AS [Read Latency],
	CASE 
		WHEN io_stall_write_ms = 0 THEN 0 
		ELSE (io_stall_write_ms/num_of_writes) 
	END AS [Write Latency],
	CASE 
		WHEN (num_of_reads = 0 AND num_of_writes = 0) THEN 0 
		ELSE (io_stall/(num_of_reads + num_of_writes)) 
	END AS [Overall Latency],
	CASE 
		WHEN num_of_reads = 0 THEN 0 
		ELSE (num_of_bytes_read/num_of_reads) 
	END AS [Avg Bytes/Read],
	CASE 
		WHEN io_stall_write_ms = 0 THEN 0 
		ELSE (num_of_bytes_written/num_of_writes) 
	END AS [Avg Bytes/Write],
	CASE 
		WHEN (num_of_reads = 0 AND num_of_writes = 0) THEN 0 
		ELSE ((num_of_bytes_read + num_of_bytes_written)/(num_of_reads + num_of_writes)) 
	END AS [Avg Bytes/Transfer]
FROM (SELECT LEFT(UPPER(mf.physical_name), 2) AS Drive, SUM(num_of_reads) AS num_of_reads,
	         SUM(io_stall_read_ms) AS io_stall_read_ms, SUM(num_of_writes) AS num_of_writes,
	         SUM(io_stall_write_ms) AS io_stall_write_ms, SUM(num_of_bytes_read) AS num_of_bytes_read,
	         SUM(num_of_bytes_written) AS num_of_bytes_written, SUM(io_stall) AS io_stall
      FROM sys.dm_io_virtual_file_stats(NULL, NULL) AS vfs
      INNER JOIN sys.master_files AS mf WITH (NOLOCK)
      ON vfs.database_id = mf.database_id AND vfs.file_id = mf.file_id
      GROUP BY LEFT(UPPER(mf.physical_name), 2)) AS tab
ORDER BY [Overall Latency] OPTION (RECOMPILE);



-- Calculates average stalls per read, per write, and per total input/output for each database file  (Query 3) 
SELECT DB_NAME(fs.database_id) AS [Database Name]
     , CAST(fs.io_stall_read_ms / (1.0 + fs.num_of_reads) AS NUMERIC(10, 1)) AS [avg_read_stall_ms]
     , CAST(fs.io_stall_write_ms / (1.0 + fs.num_of_writes) AS NUMERIC(10, 1)) AS [avg_write_stall_ms]
     , CAST((fs.io_stall_read_ms + fs.io_stall_write_ms) / (1.0 + fs.num_of_reads + fs.num_of_writes) AS NUMERIC(10, 1)) AS [avg_io_stall_ms]
     , CONVERT(DECIMAL(18, 2), mf.size / 128.0) AS [File Size (MB)]
     , mf.physical_name
     , mf.type_desc
     , fs.io_stall_read_ms
     , fs.num_of_reads
     , fs.io_stall_write_ms
     , fs.num_of_writes
     , fs.io_stall_read_ms + fs.io_stall_write_ms AS [io_stalls]
     , fs.num_of_reads + fs.num_of_writes AS [total_io]
FROM sys.dm_io_virtual_file_stats(NULL, NULL) AS fs
     INNER JOIN sys.master_files AS mf WITH(NOLOCK)
          ON fs.database_id = mf.database_id
             AND fs.[file_id] = mf.[file_id]
ORDER BY avg_io_stall_ms DESC OPTION(RECOMPILE);


-- Helps determine which database files on the entire instance have the most I/O bottlenecks
-- This can help you decide whether certain LUNs are overloaded and whether you might
-- want to move some files to a different location or perhaps improve your I/O performance

-- Look for I/O requests taking longer than 15 seconds in the two most recent SQL Server Error Logs (Query 4) 
CREATE TABLE #IOWarningResults(LogDate datetime, ProcessInfo sysname, LogText nvarchar(1000));

	INSERT INTO #IOWarningResults 
	EXEC xp_readerrorlog 0, 1, N'taking longer than 15 seconds';

	-- You can repeat this to look at older error logs
	INSERT INTO #IOWarningResults 
	EXEC xp_readerrorlog 1, 1, N'taking longer than 15 seconds';
	
SELECT LogDate, ProcessInfo, LogText
FROM #IOWarningResults
ORDER BY LogDate DESC;

DROP TABLE #IOWarningResults;  



-- I/O Statistics by file for the current database  (Query 5)
-- This helps you characterize your workload better from an I/O perspective for this database
-- It helps you determine whether you have an OLTP or DW/DSS type of workload
SELECT DB_NAME(DB_ID()) AS [Database Name]
     , df.name AS [Logical Name]
     , vfs.[file_id]
     , df.physical_name AS [Physical Name]
     , vfs.num_of_reads
     , vfs.num_of_writes
     , vfs.io_stall_read_ms
     , vfs.io_stall_write_ms
     , CAST(100. * vfs.io_stall_read_ms / (vfs.io_stall_read_ms + vfs.io_stall_write_ms) AS DECIMAL(10, 1)) AS [IO Stall Reads Pct]
     , CAST(100. * vfs.io_stall_write_ms / (vfs.io_stall_write_ms + vfs.io_stall_read_ms) AS DECIMAL(10, 1)) AS [IO Stall Writes Pct]
     , (vfs.num_of_reads + vfs.num_of_writes) AS [Writes + Reads]
     , CAST(vfs.num_of_bytes_read / 1048576.0 AS DECIMAL(10, 2)) AS [MB Read]
     , CAST(vfs.num_of_bytes_written / 1048576.0 AS DECIMAL(10, 2)) AS [MB Written]
     , CAST(100. * vfs.num_of_reads / (vfs.num_of_reads + vfs.num_of_writes) AS DECIMAL(10, 1)) AS [# Reads Pct]
     , CAST(100. * vfs.num_of_writes / (vfs.num_of_reads + vfs.num_of_writes) AS DECIMAL(10, 1)) AS [# Write Pct]
     , CAST(100. * vfs.num_of_bytes_read / (vfs.num_of_bytes_read + vfs.num_of_bytes_written) AS DECIMAL(10, 1)) AS [Read Bytes Pct]
     , CAST(100. * vfs.num_of_bytes_written / (vfs.num_of_bytes_read + vfs.num_of_bytes_written) AS DECIMAL(10, 1)) AS [Written Bytes Pct]
FROM sys.dm_io_virtual_file_stats(DB_ID(), NULL) AS vfs
     INNER JOIN sys.database_files AS df WITH(NOLOCK)
          ON vfs.[file_id] = df.[file_id] OPTION(RECOMPILE);



SELECT top 5 
	DB_NAME(database_id),
	* FROM sys.dm_db_session_space_usage
ORDER BY (user_objects_alloc_page_count + internal_objects_alloc_page_count) DESC

select sum(user_object_reserved_page_count)*8 as user_objects_kb,
    sum(internal_object_reserved_page_count)*8 as internal_objects_kb,
    sum(version_store_reserved_page_count)*8  as version_store_kb,
    sum(unallocated_extent_page_count)*8 as freespace_kb
from sys.dm_db_file_space_usage
where database_id = 2