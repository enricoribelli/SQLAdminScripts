SELECT db.database_id AS [Database Name]
     , db.name AS [Database Name]
     , mf.name AS [Logical Name]
     , mf.type_desc AS [File Type]
     , mf.physical_name AS [Path]
     , CAST((mf.Size * 8) / 1024.0 AS DECIMAL(18, 1)) AS [Initial Size (MB)]
     , mf.is_percent_growth
     , CASE
           WHEN mf.is_percent_growth = 1
           THEN CAST(mf.growth AS VARCHAR(10)) + '%'
           WHEN mf.is_percent_growth = 0
           THEN CAST(CAST((mf.growth * 8) / 1024 AS DECIMAL(18, 1)) AS VARCHAR) + ' MB'
       END AS [Autogrowth]
     , CASE
           WHEN mf.max_size = 0
           THEN 'No growth is allowed'
           WHEN mf.max_size = -1
           THEN 'Unlimited'
           WHEN mf.max_size NOT IN(0, -1)
           THEN CAST(CAST(mf.max_size AS BIGINT) * 8 / 1024 AS VARCHAR) + ' MB'
       END
FROM sys.master_files AS mf
     INNER JOIN sys.databases AS db
          ON db.database_id = mf.database_id
     INNER JOIN sys.sysprocesses AS pr
          ON pr.dbid = mf.database_id;

/*
			select * from sys.schemas

exec sp_databases

select * from sys.databases
select * from sys.master_files
select * from sys.backup_devices
--select * from sys.database_files

select * from sys.change_tracking_databases
select * from sys.change_tracking_tables

			*/