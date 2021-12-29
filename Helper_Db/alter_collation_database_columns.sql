
USE master;
GO
 
-- Set to single-user mode
ALTER DATABASE lutfi_test SET SINGLE_USER WITH ROLLBACK IMMEDIATE
GO
  
-- change collation
ALTER DATABASE lutfi_test COLLATE SQL_Latin1_General_CP1_CI_AI ;
GO  
 
-- Set to multi-user mode
ALTER DATABASE lutfi_test SET MULTI_USER WITH ROLLBACK IMMEDIATE;
GO  
 

--Verify the collation setting.
SELECT name, collation_name FROM sys.databases WHERE name = N'lutfi_test';
GO


SELECT 
    'ALTER TABLE [' +  TABLE_SCHEMA + '].[' + TABLE_NAME  
    + '] ALTER COLUMN [' + COLUMN_NAME + '] ' + DATA_TYPE 
    + '(' + CAST(CHARACTER_MAXIMUM_LENGTH AS nvarchar(100)) 
    + ') COLLATE ' + 'Latin1_General_CI_AS' 
    + CASE WHEN IS_NULLABLE = 'YES' THEN ' NULL' ELSE ' NOT NULL' END 
FROM 
    INFORMATION_SCHEMA.COLUMNS 
WHERE 
    DATA_TYPE like '%char'