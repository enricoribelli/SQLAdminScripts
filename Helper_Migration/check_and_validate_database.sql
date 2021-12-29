------------------------------------------------------------------------------------------------------------------------------
-- overview jobs
------------------------------------------------------------------------------------------------------------------------------
select 
	job.job_id,
	job.name job_name,
	step.step_id,
	step.step_name step_name,
	step.database_name,
	DB_ID(step.database_name)
from dbo.sysjobs job 
	inner join dbo.sysjobsteps step on step.job_id = job.job_id

------------------------------------------------------------------------------------------------------------------------------
-- Get database orphan users
------------------------------------------------------------------------------------------------------------------------------
EXEC sp_change_users_login 'REPORT'


------------------------------------------------------------------------------------------------------------------------------
-- Check compatibility level of the database
------------------------------------------------------------------------------------------------------------------------------
SELECT db.database_id
     , db.name [database_name]
     , db.create_date
     , db.collation_name
	 , db.state_desc
	 , db.compatibility_level
	 , CASE  db.compatibility_level
			WHEN 65  THEN 'SQL Server 6.5'
			WHEN 70  THEN 'SQL Server 7.0'
			WHEN 80  THEN 'SQL Server 2000'
			WHEN 90  THEN 'SQL Server 2005'
			WHEN 100 THEN 'SQL Server 2008/R2'
			WHEN 110 THEN 'SQL Server 2012'
			WHEN 120 THEN 'SQL Server 2014'
			WHEN 130 THEN 'SQL Server 2016'
			WHEN 140 THEN 'SQL Server 2017'
			WHEN 150 THEN 'SQL Server 2019'
			ELSE 'new unknown - ' + CONVERT(varchar(10),db.compatibility_level) 
		END AS compatibility_level_desc
FROM sys.databases AS db
WHERE db.database_id = DB_ID()
order by [database_name];

------------------------------------------------------------------------------------------------------------------------------
-- Get database users
------------------------------------------------------------------------------------------------------------------------------
SELECT server_login = server_users.name
     , login_status = CASE
                          WHEN server_users.is_disabled = 1 THEN 'Disabled'
                          ELSE 'Enabled'
                      END
     , db_user = member_users.name
     , db_user_type_desc = member_users.type_desc
     , db_role = rolp.name

FROM sys.database_role_members AS mmbr
     INNER JOIN sys.database_principals AS rolp -- The DB Roles names table
          ON rolp.[principal_id] = mmbr.[role_principal_id]
     LEFT OUTER JOIN sys.database_principals AS member_users -- The DB users names table
          ON member_users.[principal_id] = mmbr.[member_principal_id]
     LEFT OUTER JOIN sys.server_principals AS server_users -- The Login accounts table
          ON member_users.[sid] = server_users.[sid];

------------------------------------------------------------------------------------------------------------------------------
-- Check collations of database if different the Latin1_General_CI_AS fix it 
------------------------------------------------------------------------------------------------------------------------------
SELECT dbs.name
     , dbs.collation_name
FROM sys.databases AS dbs
WHERE dbs.name IN(N'AccessSettings', N'AccessSettings_Develop', N'AccessSettings_Test')
	AND dbs.collation_name <> 'Latin1_General_CI_AS';

------------------------------------------------------------------------------------------------------------------------------
-- Check collations different from Latin1_General_CI_AS
------------------------------------------------------------------------------------------------------------------------------
SELECT      t.object_id,
			OBJECT_SCHEMA_NAME(t.object_id) AS schemaname,
            OBJECT_NAME(t.object_id)        AS tablename,
			c.name column_name,
			c.collation_name
FROM        sys.tables              AS t
INNER JOIN  sys.columns             AS c
   ON       c.object_id         = t.object_id
   AND      c.collation_name    <> 'Latin1_General_CI_AS' -- Table needs to have columns with "wrong" collation
INNER JOIN  sys.types               AS ty
   ON       ty.system_type_id   = c.system_type_id
   AND      ty.name             <> N'sysname' -- Exclusion retained from Philip C's original script
WHERE       t.is_ms_shipped = 0 -- Exclude Microsoft-shipped tables
GROUP BY    t.object_id, c.name, c.collation_name;


------------------------------------------------------------------------------------------------------------------------------
-- Get refences in the databases
------------------------------------------------------------------------------------------------------------------------------
WITH Ref_Objects AS (
SELECT OBJECT_SCHEMA_NAME(referencing_id) AS referencing_schema_name
     , OBJECT_NAME(referencing_id) AS referencing_entity_name
     , o.type_desc AS referencing_desciption
     , COALESCE(COL_NAME(referencing_id, referencing_minor_id), '(n/a)') AS referencing_minor_id
     , referencing_class_desc
     , referenced_class_desc
     , referenced_server_name
     , referenced_database_name
     , referenced_schema_name
     , referenced_entity_name
     , COALESCE(COL_NAME(referenced_id, referenced_minor_id), '(n/a)') AS referenced_column_name
     , is_caller_dependent
     , is_ambiguous
	 , sm.definition AS script
FROM sys.sql_expression_dependencies AS sed
     INNER JOIN sys.objects AS o
          ON sed.referencing_id = o.object_id
		INNER JOIN sys.sql_modules AS sm ON sm.object_id = o.object_id

)
SELECT referenced_server_name, referenced_database_name, referenced_schema_name, referenced_entity_name
FROM Ref_Objects
--WHERE referenced_server_name IS NOT NULL 
	-- AND referenced_database_name IS NOT NULL 
GROUP BY referenced_server_name, referenced_database_name, referenced_schema_name, referenced_entity_name
ORDER BY referenced_server_name, referenced_database_name, referenced_schema_name, referenced_entity_name


------------------------------------------------------------------------------------------------------------------------------
-- Get columns with path reference
------------------------------------------------------------------------------------------------------------------------------
With path_columns AS (
Select sch.name as [schema_name], tbl.name table_name, cols.name column_name
	, CAST(('SELECT * FROM '+sch.name +'.'+tbl.name) AS nvarchar(4000)) sql_text
from sys.tables tbl 
	inner join sys.columns cols on cols.object_id = tbl.object_id
	inner join sys.schemas sch on sch.schema_id = tbl.schema_id
where ((cols.name like '%path%') OR (cols.name like '%file%') OR (cols.name like '%location%')
		OR (cols.name like '%DataSource%')
		OR (cols.name like '%url%') OR (cols.name like '%http%') OR (cols.name like '%folder%')
	) AND (
		-- ignore table names
		tbl.name  not in ('AccessAppOptions','EnvironmentDataSource','AccessAppOptionsDefault','ConnectionDefault','Connection','AccessAppOptionsEnvironment', 'AccessDatabase','AccessUserInfoSetting')
	)
)
Select [schema_name], [table_name], [sql_text]
From path_columns
GROUP BY [schema_name], [table_name], [sql_text]
ORDER BY [schema_name], [table_name], [sql_text]

