-- Frag information:
-- https://sqlcan.com/2019/02/05/managing-sql-server-database-fragmentation/#:~:text=If%20the%20SQL%20database%20fragmentation%20rate%20is%200,usually%20REBUILD%20the%20indexes.%20How%20to%20Reorganize%20Indexes
-- Types of defrags:
-- https://docs.microsoft.com/en-us/sql/relational-databases/indexes/reorganize-and-rebuild-indexes?view=sql-server-ver15

-- REORGANIZE index IX_MyIndex on table MyTable
-- ALTER INDEX IX_MyIndex ON dbo.MyTable REORGANIZE;

-- REORGANIZE all indexes on table MyTable
-- ALTER INDEX ALL ON dbo.MyTable REORGANIZE;

-- REBUILD index IX_MyIndex on table MyTable
-- ALTER INDEX IX_MyIndex ON dbo.MyTable REBUILD;

-- REBUILD all indexes on table MyTable
-- ALTER INDEX ALL ON dbo.MyTable REBUILD;
DECLARE @tableName NVARCHAR(MAX) = NULL;
DECLARE @indexName NVARCHAR(MAX) = NULL;

SELECT
OBJECT_Name(ips.object_id) AS TableName,
i.name AS IndexName,
i.type_desc,
ips.alloc_unit_type_desc,
ips.page_count,
ips.index_depth,
ips.avg_page_space_used_in_percent,
ips.avg_fragmentation_in_percent,
ips.index_level,
ips.record_count,
ips.fragment_count,
ips.avg_record_size_in_bytes
-- Takes a really long time because it’s detailed.
-- FROM sys.dm_db_index_physical_stats (DB_ID(),NULL,NULL,NULL,'DETAILED') ips
FROM sys.dm_db_index_physical_stats(DB_ID(),NULL,NULL,NULL,NULL) ips
JOIN sys.indexes i ON ips.index_id = i.index_id
AND ips.object_id = i.object_id
AND (@tableName IS NULL OR OBJECT_Name(ips.object_id) = @tableName)
AND (@indexName IS NULL OR OBJECT_Name(ips.object_id) = @indexName)
ORDER BY ips.object_id, avg_fragmentation_in_percent DESC

-- select alloc_unit_type_desc, index_depth, avg_fragment_size_in_pages, avg_fragmentation_in_percent, fragment_count
--  * from sys.dm_db_index_physical_stats(NULL,NULL,NULL,NULL,NULL) where index_id = 1 and object_id = 1333579789