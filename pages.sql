-- View Pages for a table
-- https://kwelsql.wordpress.com/2016/01/31/dbcc-ind-and-dbcc-page/
-- <DatabaseName or DBID>', '<TableName or ObjectId>', -1
-- DBCC IND('MyDatabase', 'MyTable', -1)

-- View data for a page
-- DatabaseName or DBID, filenum, pagenum [, printopt={0|1|2|3}])
-- DBCC TRACEON (3604)
-- DBCC PAGE('MyDatabase', 1, 40101, 3)
-- DBCC TRACEOFF (3604)

SELECT 
t.NAME AS TableName,
p.rows AS RowCounts,
SUM(a.total_pages) AS TotalPages, 
SUM(a.used_pages) AS UsedPages,
(SUM(a.total_pages)-SUM(a.used_pages)) AS UnusedPages,
p.rows/SUM(a.used_pages) AS AverageRowsPerPage
FROM sys.tables t
INNER JOIN sys.indexes i ON t.OBJECT_ID = i.object_id
INNER JOIN sys.partitions p ON i.object_id = p.OBJECT_ID AND i.index_id = p.index_id
INNER JOIN sys.allocation_units a ON p.partition_id = a.container_id
WHERE t.NAME NOT LIKE 'dt%' 
AND t.is_ms_shipped = 0
AND i.OBJECT_ID > 255 
GROUP BY t.Name, p.Rows
ORDER BY t.Name