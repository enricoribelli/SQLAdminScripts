/*
--------------------------------------------------------------------------------------------------
	TEMP_DB		
--------------------------------------------------------------------------------------------------
	Multiple temp_db data files (start with 4-8)	
		1. same size and auto-grow increment
		2. Another reason you might want to use multiple data files is to increase the I/O throughput to tempdb 
			- especially if it’s running on very fast storage.
		3. 1:1 mapping between the number of files and logical CPUs

*/



/* Re-sizing TempDB to 8 GB */
USE [master]; 
GO 
alter database tempdb modify file (name='tempdev', size = 8GB);
GO

/* Adding three additional files */
USE [master];
GO
ALTER DATABASE [tempdb] ADD FILE (NAME = N'tempdev2', FILENAME = N'F:\MSSQL12.MSSQLSERVER\MSSQL\Data\tempdev2.ndf' , SIZE = 8GB , FILEGROWTH = 0);
ALTER DATABASE [tempdb] ADD FILE (NAME = N'tempdev3', FILENAME = N'F:\MSSQL12.MSSQLSERVER\MSSQL\Data\tempdev3.ndf' , SIZE = 8GB , FILEGROWTH = 0);
ALTER DATABASE [tempdb] ADD FILE (NAME = N'tempdev4', FILENAME = N'F:\MSSQL12.MSSQLSERVER\MSSQL\Data\tempdev4.ndf' , SIZE = 8GB , FILEGROWTH = 0);
ALTER DATABASE [tempdb] ADD FILE (NAME = N'tempdev5', FILENAME = N'F:\MSSQL12.MSSQLSERVER\MSSQL\Data\tempdev5.ndf' , SIZE = 8GB , FILEGROWTH = 0);
ALTER DATABASE [tempdb] ADD FILE (NAME = N'tempdev6', FILENAME = N'F:\MSSQL12.MSSQLSERVER\MSSQL\Data\tempdev6.ndf' , SIZE = 8GB , FILEGROWTH = 0);
ALTER DATABASE [tempdb] ADD FILE (NAME = N'tempdev7', FILENAME = N'F:\MSSQL12.MSSQLSERVER\MSSQL\Data\tempdev7.ndf' , SIZE = 8GB , FILEGROWTH = 0);
ALTER DATABASE [tempdb] ADD FILE (NAME = N'tempdev8', FILENAME = N'F:\MSSQL12.MSSQLSERVER\MSSQL\Data\tempdev8.ndf' , SIZE = 8GB , FILEGROWTH = 0);
GO


-- remove 
/*
USE [tempdb]
GO
DBCC SHRINKFILE (N'tempdev5', EMPTYFILE)
GO

ALTER DATABASE [tempdb]  REMOVE FILE [tempdev5]
GO
*/