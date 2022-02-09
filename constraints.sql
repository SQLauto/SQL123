-- C = Check Constraint
-- D = DEFAULT (constraint or stand-alone)
-- F = FOREIGN KEY
-- P = PRIMARY KEY
-- R = Rule (old-style, stand-alone)
-- T = 'Assembly (CLR-integration) trigger
-- T = SQL trigger
-- U = UNIQUE constraint
-- E = Edge constraint

DECLARE @constraintType AS CHAR = NULL;
DECLARE @tableName AS NVARCHAR(MAX) = NULL;

SELECT s.name As 'Schema Name', t.Name AS 'Table Name', co.name As 'Constraint Name', 
co.type AS 'Constraint Type', co.type_desc AS 'Constraint Description', 
cc.definition AS 'Check Constraint Definition',
ccc.Name AS 'Check Constraint Column',
dc.definition AS 'Default Value Constraint Definition',
dcl.Name AS 'Default Value Constraint Column',
co.create_date As CreatedDateTime, co.modify_date As ModifyDateTime
FROM sys.schemas s
INNER JOIN sys.objects t ON s.schema_id = t.schema_id
INNER JOIN sys.sysconstraints ct ON t.object_id = ct.id
INNER JOIN sys.objects co ON ct.constid = co.object_id
LEFT JOIN sys.default_constraints dc ON dc.object_id = ct.constid
LEFT JOIN sys.all_columns dcl ON dc.parent_column_id = dcl.column_id AND t.object_id = dcl.object_id
LEFT JOIN sys.check_constraints cc ON cc.object_id = ct.constid
LEFT JOIN sys.all_columns ccc ON cc.parent_column_id = ccc.column_id AND cc.parent_object_id = ccc.object_id
WHERE (@tableName IS NULL OR t.name = @tableName)
AND (@constraintType IS NULL OR co.type = @constraintType)
ORDER  BY t.name
