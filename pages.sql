DECLARE @schemaName NVARCHAR(MAX) = NULL;
DECLARE @tableName NVARCHAR(MAX) = NULL;

-- View Pages for a table
-- https://kwelsql.wordpress.com/2016/01/31/dbcc-ind-and-dbcc-page/
-- <DatabaseName or DBID>', '<TableName or ObjectId>', <index number, or -1 to see all indexes page details>
-- DBCC IND('<database>', '<table>', -1);

-- View data for a page
-- DatabaseName or DBID, PageFID, PageID [, printopt={0|1|2|3}])
 --DBCC TRACEON (3604);
 --DBCC PAGE('<database>', 1, 76713, 3);
 --DBCC TRACEOFF (3604);

SELECT
OBJECT_SCHEMA_NAME(t.object_id) AS SchemaName,
t.NAME AS TableName,
i.name AS IndexName,
i.index_id AS IndexId,
FORMAT(p.rows, N'N0') AS RowCounts,
FORMAT(SUM(a.total_pages), N'N0') AS TotalPages, 
FORMAT(SUM(a.used_pages), N'N0') AS UsedPages,
FORMAT((SUM(a.total_pages)-SUM(a.used_pages)), N'N0') AS UnusedPages,
FORMAT(IIF(SUM(a.used_pages) > 0, p.rows/SUM(a.used_pages), 0), N'N0') AS AverageRowsPerPage
FROM sys.tables t
INNER JOIN sys.indexes i ON t.OBJECT_ID = i.object_id
INNER JOIN sys.partitions p ON i.object_id = p.OBJECT_ID AND i.index_id = p.index_id
INNER JOIN sys.allocation_units a ON p.partition_id = a.container_id
WHERE t.NAME NOT LIKE 'dt%' 
AND t.is_ms_shipped = 0
AND i.OBJECT_ID > 255
AND (OBJECT_SCHEMA_NAME(t.object_id) = @schemaName OR @schemaName IS NULL)
AND (OBJECT_NAME(t.object_id) = @tableName OR @tableName IS NULL)
GROUP BY t.Name, p.Rows, i.name, t.object_id, i.index_id
ORDER BY SUM(a.total_pages) DESC