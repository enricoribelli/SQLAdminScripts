SELECT princ.name AS 'User'
     , princ.PRINCIPAL_ID
     , princ.type AS 'User Type'
     , princ.type_desc AS 'Login Type'
     , CAST(princ.create_date AS DATE) AS 'Date Created'
     , princ.default_database_name AS 'Database Name'
     , CASE
           WHEN princ.is_disabled LIKE 0
           THEN 'NO' --IIF(princ.is_fixed_role LIKE 0, 'No', 'Yes') AS 'Is Active'
           WHEN princ.is_disabled LIKE 1
           THEN 'YES'
       END AS 'Is Disabled'
FROM sys.server_principals AS princ
WHERE princ.type LIKE 's'
      OR princ.type LIKE 'u'
ORDER BY [User]
       , [Database Name];