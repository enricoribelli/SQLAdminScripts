/* 

SETUP.EXE /QUIET /ACTION=REBUILDDATABASE /INSTANCENAME=TEST /SQLCOLLATION=Latin1_General_CI_AS /SQLSYSADMINACCOUNTS=BIS-IS\admin-anthoo*** /SAPWD=**************

*/
SELECT @@servername

SELECT @@servicename


SELECT name, collation_name FROM sys.databases

SELECT CONVERT (varchar, SERVERPROPERTY('collation')) AS 'Server Collation'
SELECT name, collation_name FROM sys.databases WHERE name = 'master';
--SELECT name, collation_name FROM sys.databases WHERE name = 'Products';
--SELECT COLUMN_NAME, COLLATION_NAME FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'ProductGuid'


SELECT SERVERPROPERTY ('InstanceName')
