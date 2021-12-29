SELECT @@servername

SELECT @@servicename


SELECT name, collation_name FROM sys.databases

SELECT CONVERT (varchar, SERVERPROPERTY('collation')) AS 'Server Collation'
SELECT name, collation_name FROM sys.databases WHERE name = 'master';
--SELECT name, collation_name FROM sys.databases WHERE name = 'Products';
--SELECT COLUMN_NAME, COLLATION_NAME FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'ProductGuid'


SELECT SERVERPROPERTY ('InstanceName')

SELECT 'SQL_Latin1_General_CP1_CI_AS' AS 'Collation',
	COLLATIONPROPERTY('SQL_Latin1_General_CP1_CI_AS', 'CodePage') AS 'CodePage', 
	COLLATIONPROPERTY('SQL_Latin1_General_CP1_CI_AS', 'LCID') AS 'LCID',
	COLLATIONPROPERTY('SQL_Latin1_General_CP1_CI_AS', 'ComparisonStyle') AS 'ComparisonStyle', 
	COLLATIONPROPERTY('SQL_Latin1_General_CP1_CI_AS', 'Version') AS 'Version'
UNION ALL
SELECT 'Latin1_General_CI_AS' AS 'Collation', 
	COLLATIONPROPERTY('Latin1_General_CI_AS', 'CodePage') AS 'CodePage', 
	COLLATIONPROPERTY('Latin1_General_CI_AS', 'LCID') AS 'LCID',
	COLLATIONPROPERTY('Latin1_General_CI_AS', 'ComparisonStyle') AS 'ComparisonStyle', 
	COLLATIONPROPERTY('Latin1_General_CI_AS', 'Version') AS 'Version'
GO

--Create a table using collation Latin1_General_CI_AS and add some data to it 
DECLARE @MyTable1 TABLE (
	ID INT IDENTITY(1, 1), 
	Comments VARCHAR(100) COLLATE Latin1_General_CI_AS
)
INSERT INTO @MyTable1 (Comments) VALUES ('Chiapas')
INSERT INTO @MyTable1 (Comments) VALUES ('Colima')
INSERT INTO @MyTable1 (Comments) VALUES ('Chiapas')

--Create a table using collation Latin1_General_CI_AS and add some data to it 
DECLARE @MyTable2 TABLE (
	ID INT IDENTITY(1, 1), 
	Comments VARCHAR(100) COLLATE SQL_Latin1_General_CP1_CI_AS
)
INSERT INTO @MyTable2 (Comments) VALUES ('Chiapas')
INSERT INTO @MyTable2 (Comments) VALUES ('Colima')


SELECT * FROM @MyTable1 M1
INNER JOIN @MyTable2 M2 ON M1.Comments = M2.Comments


SELECT * FROM @MyTable1
SELECT * FROM @MyTable2