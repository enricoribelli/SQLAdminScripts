USE MSDB;
GO

UPDATE MSDB.dbo.sysjobs
SET Enabled = 0
WHERE [Name] LIKE 'NavPlus %';
GO