DECLARE @roleOrUser NVARCHAR(100) = NULL;

 -- Principal type:
--A = Application role
--C = User mapped to a certificate
--E = External user from Azure Active Directory
--G = Windows group
--K = User mapped to an asymmetric key
--R = Database role
--S = SQL user
--U = Windows user
--X = External group from Azure Active Directory group or applications

-- View permissions for role.
SELECT up.name AS SqlUser, up.type AS Type, up.type_desc As TypeDescription, up.default_schema_name AS DefaultSchema, up.create_date As CreatedDate, up.modify_date AS ModifyDate,
p.class AS Class, p.permission_name As PermissionName, p.State, p.state_desc AS StateDescription
FROM sys.database_principals up
LEFT JOIN sys.database_role_members rm  ON up.principal_id = rm.member_principal_id
LEFT JOIN sys.database_permissions p ON p.grantee_principal_id = up.principal_id
WHERE  (up.name = @roleOrUser OR @roleOrUser IS NULL)
--AND p.type = 'R'
ORDER BY up.name, p.permission_name

-- What role are they part of
SELECT up.name, rp.name
FROM sys.database_role_members AS rm
INNER JOIN sys.database_principals AS rp ON rm.role_principal_id = rp.principal_id
INNER JOIN sys.database_principals AS up ON up.principal_id = rm.member_principal_id
WHERE  (up.name = @roleOrUser OR @roleOrUser IS NULL)

SELECT rp.name AS RoleName, ISNULL(up.name, 'No members') AS UserName   
FROM sys.database_role_members AS rm  
RIGHT OUTER JOIN sys.database_principals AS rp ON rm.role_principal_id = rp.principal_id  
LEFT OUTER JOIN sys.database_principals AS up ON rm.member_principal_id = up.principal_id  
WHERE  (rp.name = @roleOrUser OR @roleOrUser IS NULL)
AND rp.type = 'R'
ORDER BY rp.name;  


