sp_helprotect
SELECT * FROM fn_my_permissions(NULL,'DATABASE') perm WHERE perm.permission_name like '%VIEW%'

SELECT DISTINCT pr.principal_id, pr.name, pr.type_desc, 
    pr.authentication_type_desc, pe.state_desc, pe.permission_name
FROM sys.database_principals AS pr
JOIN sys.database_permissions AS pe
    ON pe.grantee_principal_id = pr.principal_id;

SELECT roles.name AS server_role_name
    , roles.principal_id
    , roles.type AS role_type
    , roles.type_desc AS role_type_desc
    , roles.is_fixed_role AS role_is_fixed_role
    , memberserverprincipal.name AS member_principal_name
    , memberserverprincipal.principal_id AS member_principal_id
    , memberserverprincipal.type AS member_principal_type
    , memberserverprincipal.type_desc AS member_principal_type_desc
    , memberserverprincipal.is_fixed_role AS member_is_fixed_role
    , N'ALTER SERVER ROLE ' + QUOTENAME(roles.name) + N' ADD MEMBER ' + QUOTENAME(memberserverprincipal.name) AS AddRoleMembersStatement
FROM sys.server_principals AS roles
INNER JOIN sys.server_role_members
    ON sys.server_role_members.role_principal_id = roles.principal_id
INNER JOIN sys.server_principals AS memberserverprincipal
    ON memberserverprincipal.principal_id = sys.server_role_members.member_principal_id
WHERE roles.type = N'R'
ORDER BY server_role_name
    , member_principal_name