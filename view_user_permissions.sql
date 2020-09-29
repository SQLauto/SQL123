DECLARE @roleOrUser NVARCHAR(100) = null;

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
SELECT DISTINCT up.name AS SqlUser, up.type AS Type, up.type_desc As TypeDescription, up.default_schema_name AS DefaultSchema, up.create_date As CreatedDate, up.modify_date AS ModifyDate,
p.class AS Class, p.permission_name As PermissionName, p.State, p.state_desc AS StateDescription,
(SELECT TOP	1 Name
 FROM sys.database_principals up2
 WHERE up2.principal_id = up.owning_principal_id) AS OwerName
FROM sys.database_principals up
LEFT JOIN sys.database_role_members rm  ON up.principal_id = rm.member_principal_id
LEFT JOIN sys.database_permissions p ON p.grantee_principal_id = up.principal_id
WHERE  (up.name = @roleOrUser OR @roleOrUser IS NULL)
--AND p.type = 'R'
ORDER BY up.name, p.permission_name

SELECT DISTINCT rp.name AS SqlUser, ObjectType = rp.type_desc, PermissionType = pm.class_desc, pm.permission_name, pm.state_desc,
CASE
    WHEN obj.type_desc IS NULL OR obj.type_desc = 'SYSTEM_TABLE' THEN pm.class_desc
    ELSE obj.type_desc
END AS ObjectType,
s.Name as SchemaName,
ISNULL(ss.name, OBJECT_NAME(pm.major_id)) AS ObjectName
FROM   sys.database_principals rp
INNER JOIN sys.database_permissions pm ON pm.grantee_principal_id = rp.principal_id
LEFT JOIN sys.schemas ss ON pm.major_id = ss.schema_id
LEFT JOIN sys.objects obj ON pm.[major_id] = obj.[object_id]
LEFT JOIN sys.schemas s ON s.schema_id = obj.schema_id
WHERE  (rp.name = @roleOrUser OR @roleOrUser IS NULL)
AND rp.type_desc = 'DATABASE_ROLE'
AND pm.class_desc <> 'DATABASE'
ORDER BY rp.name, rp.type_desc, pm.class_desc

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

-- SELECT l.name AS Login, Islogin, u.name AS UserName, l.Type_desc, default_database_name, l.*
-- FROM sys.sysusers u
-- FULL OUTER JOIN master.sys.sql_logins l ON u.sid = l.sid
-- WHERE
-- (
--     Islogin = 1
--     AND u.sid is not null
--     AND  (u.name = @roleOrUser OR @roleOrUser IS NULL)
-- )
-- OR
-- (
--     (l.name = @roleOrUser OR @roleOrUser IS NULL)
-- )

-- GRANT EXECUTE ON GetNextPdfToExport TO db_role_virtuescript_import;
-- 		GRANT EXECUTE ON MarkPdfExported TO db_role_virtuescript_import;
-- 		GRANT EXECUTE On MarkPdfExportError TO db_role_virtuescript_import;
