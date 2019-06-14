DECLARE @login varchar(100) = NULL
DECLARE @user varchar(100) = IIF(@login IS NULL, NULL, @login + 'usr')


SELECT p.name AS SqlUser, p.type AS Type, p.type_desc As TypeDescription, p.default_schema_name AS DefaultSchema, create_date As CreatedDate, modify_date AS ModifyDate,
dp.class AS Class, permission_name As PermissionName, State, state_desc AS StateDescription
FROM sys.database_principals p
LEFT JOIN sys.database_permissions dp ON dp.grantee_principal_id = p.principal_id
WHERE p.type = 'S'
AND (name = @user OR @user  IS NULL)
ORDER BY p.name, dp.permission_name
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
