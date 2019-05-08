SELECT
    OBJECT_Name(ips.object_id) AS TableName,
    i.name AS IndexName,
    i.type_desc,
    ips.avg_page_space_used_in_percent,
    ips.avg_fragmentation_in_percent,
    ips.index_level,
    ips.record_count,
    ips.page_count,
    ips.fragment_count,
    ips.avg_record_size_in_bytes
-- Takes a really long time because it’s detailed.
-- FROM sys.dm_db_index_physical_stats
(DB_ID(),NULL,NULL,NULL,'DETAILED') ips
FROM sys.dm_db_index_physical_stats(DB_ID(),NULL,NULL,NULL,NULL) ips
    JOIN sys.indexes i ON ips.index_id = i.index_id
        AND ips.object_id = i.object_id
ORDER BY ips.object_id, avg_fragmentation_in_percent DESC