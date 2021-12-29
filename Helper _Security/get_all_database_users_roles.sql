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