DECLARE @tableName NVARCHAR(100) = NULL;
DECLARE @indexName NVARCHAR(100) = NULL;
DECLARE @schemaName NVARCHAR(MAX) = NULL;
DECLARE @showIndexData BIT = 1;
DECLARE @showColumnStatistics BIT = 0;

-- DBCC SHOW_STATISTICS('<schema>.<table name>',<index name>);
-- NOT RECOMMENDED TO TURN ON PERSIST_SAMPLE_PERCENT
-- For an index
-- UPDATE STATISTICS <schema>.<table name> <index name> WITH PERSIST_SAMPLE_PERCENT = OFF; -- Turn off manually setting the sampling percent for a index and use SQL Server default.
-- UPDATE STATISTICS <schema>.<table name> <index name> WITH FULLSCAN, PERSIST_SAMPLE_PERCENT = ON; -- Set sampling statistics at 100% for a index , shown in column persisted_sample_percent/PersistedSamplePercent.
-- UPDATE STATISTICS <schema>.<table name> <index name> WITH SAMPLE 60 PERCENT, PERSIST_SAMPLE_PERCENT = ON; -- Set sampling statistics percent for a index , shown in column persisted_sample_percent/PersistedSamplePercent.
-- For entire table
-- UPDATE STATISTICS <schema>.<table name> WITH PERSIST_SAMPLE_PERCENT = OFF; -- Turn off manually setting the sampling percent for the entire table and use SQL Server default.
-- UPDATE STATISTICS <schema>.<table name> WITH FULLSCAN, PERSIST_SAMPLE_PERCENT = ON; -- Set sampling statistics at 100% for the entire table , shown in column persisted_sample_percent/PersistedSamplePercent.
-- UPDATE STATISTICS <schema>.<table name> WITH SAMPLE 60 PERCENT, PERSIST_SAMPLE_PERCENT = ON; -- Set sampling statistics percent for the entire table , shown in column persisted_sample_percent/PersistedSamplePercent.

-- ALTER INDEX <INDEX NAME> ON <TABLE NAME> DISABLE; 
-- ALTER INDEX <INDEX NAME> ON <TABLE NAME> REBUILD; 

IF ISNULL(@showIndexData, 0) = 1 BEGIN
    SELECT
    OBJECT_SCHEMA_NAME(o.object_id) AS SchemaName,
    o.name AS TableName,
    i.name AS IndexName,
    i.object_id,
    i.index_id,
    i.type_desc AS 'Index Type',
    i.is_disabled AS IsDisabled,
    i.auto_created AS IndexCreatedByAutomaticTuning,
    STATS_DATE(i.object_id,i.index_id) IndexStatisticsLastUpdatedOrCreated,
    sp.rows AS RowsWhenStatisticsLastUpdated,
    sp.rows_sampled AS TotalNumberOfRowsSampledForStatisticsCalculations,
    (sp.rows_sampled * 100)/rows AS SamplePercent,
    sp.persisted_sample_percent PersistedSamplePercent,
    sp.steps AS NumberOfStepsInTheHistogram,
    sp.modification_counter AS ModCounter,
    i.allow_row_locks AS AllowRowLocks,
    o.create_date AS TableCreateDateTime, 
    o.modify_date AS TableModifyDateTime,
    ius.user_seeks AS UserSeek,
    ius.user_scans AS UserScans,
    ius.user_lookups AS UserLookups,
    ius.user_updates AS Writes,
    ius.last_user_seek AS LastSeek,
    ius.last_user_scan AS LastScan,
    ius.last_user_lookup AS LastLookup,
    ius.last_user_update AS LastUpdate,
    ios.leaf_insert_count AS NumOfInserts,
    ios.leaf_delete_count AS NumOfDeletes,
    ios.leaf_update_count AS NumOfUpdates,
    ips.avg_fragmentation_in_percent AS Fragmentation,
    oa_index_size.IndexSizeKB,
    oa_index_size.TotalUsedMB,
    oa_index_size.TotalDataMB,
    oa_index_size.ReservedMB,
    oa_index_size.UnusedMB,
    oa_index_size.RowCountTotal,
    oa_index_size.used_pages,
    oa_index_size.reserved_pages,
    oa_columns.Columns AS IndexColumns,
    oa_columns.IncludeColumns AS IncludeColumns,
    i.has_filter HasFilter,
    i.filter_definition AS IndexWhereFilter,
    i.ignore_dup_key IgnoreDupKey,
    i.is_primary_key IsPrimaryKey,
    i.is_unique IsUnique,
    i.is_unique_constraint IsUniqueConstraint,
    ios.row_lock_count AS RowLockCount,
    ios.row_lock_wait_count AS RowLockWaitCount,
    ios.row_lock_wait_in_ms AS RowLockWaitMilliseconds,
    ios.page_lock_count,
    ios.page_lock_wait_count,
    ios.page_lock_wait_in_ms,
    ios.index_lock_promotion_attempt_count,
    ios.index_lock_promotion_count,
    ios.page_latch_wait_count,
    ios.page_latch_wait_in_ms,
    ios.page_io_latch_wait_count,
    ios.page_io_latch_wait_in_ms,
    ios.tree_page_latch_wait_count,
    ios.tree_page_latch_wait_in_ms,
    ios.tree_page_io_latch_wait_count,
    ios.tree_page_io_latch_wait_in_ms,
    ios.page_compression_attempt_count,
    ios.page_compression_success_count
    FROM sys.indexes i 
    LEFT JOIN sys.dm_db_index_usage_stats ius ON i.index_id = ius.index_id AND ius.object_id = i.object_id
    LEFT JOIN sys.dm_db_index_physical_stats(NULL,NULL,NULL,NULL,NULL) ips ON ius.object_id = ips.object_id AND ips.index_id = i.index_id
    INNER JOIN sys.objects o ON o.object_id = i.object_id
    LEFT JOIN sys.dm_db_index_operational_stats (NULL,NULL,NULL,NULL ) ios ON i.object_id = ios.object_id AND i.index_id = ios.index_id
    OUTER APPLY sys.dm_db_stats_properties (object_id(o.name), 1) sp
    OUTER APPLY
    (
    SELECT
            SUM(ps.used_page_count) used_pages,
            SUM(ps.reserved_page_count) reserved_pages,
            SUM(ps.used_page_count) * 8 IndexSizeKB,
            CONVERT(DECIMAL(19, 2), SUM( ps.used_page_count) / 128.0) AS TotalUsedMB,
            CONVERT(DECIMAL(19, 2), SUM(ps.in_row_data_page_count + ps.lob_used_page_count + ps.row_overflow_used_page_count) / 128.0) AS TotalDataMB,
            CONVERT(DECIMAL(19, 2), SUM(ps.reserved_page_count) / 128.0) AS ReservedMB,
            CONVERT(DECIMAL(19, 2), SUM(ps.reserved_page_count) / 128.0 - CONVERT(DECIMAL(19, 2), SUM( ps.used_page_count)) / 128.0) AS UnusedMB,
            MAX(ISNULL(row_count, 0)) AS RowCountTotal
        FROM sys.dm_db_partition_stats ps
        WHERE ps.object_id = o.object_id
            AND i.index_id = ps.index_id
        GROUP BY ps.object_id
    ) oa_index_size
    OUTER APPLY
    (
        SELECT
        SUBSTRING(
        (
            SELECT ', ' + c.name AS [text()]
            FROM sys.index_columns ic
                INNER JOIN sys.columns c ON c.column_id = ic.column_id AND c.object_id = ic.object_id
            WHERE ic.is_included_column = 0
                AND ic.object_id = i.object_id
                AND i.index_id = ic.index_id
            FOR XML PATH ('')
        ), 3, 1000) AS Columns,
            SUBSTRING(
        (
        SELECT ', ' + c.name AS [text()]
                FROM sys.index_columns ic
                    INNER JOIN sys.columns c ON c.column_id = ic.column_id AND c.object_id = ic.object_id
                WHERE ic.is_included_column = 1
                    AND ic.object_id = i.object_id
                    AND i.index_id = ic.index_id
                FOR XML PATH ('')
        ), 3, 1000) AS IncludeColumns
    ) oa_columns
    WHERE (o.name = @tableName OR @tableName IS NULL)
    AND (i.name = @indexName OR @indexName IS NULL)
    AND (OBJECT_SCHEMA_NAME(o.object_id) = @schemaName OR @schemaName IS NULL)
    GROUP BY o.object_id, o.name, i.name, i.type_desc, ius.user_seeks,
    o.create_date, o.modify_date,
    ius.user_scans, ius.user_lookups, ius.user_updates,
    ius.last_user_seek, ius.last_user_scan, ius.last_user_lookup,
    ius.last_user_update, ios.leaf_insert_count, ios.leaf_delete_count,
    ios.leaf_update_count,
    ios.row_lock_count,ios.row_lock_wait_count, ios.row_lock_wait_in_ms,
    page_lock_count, page_lock_wait_count, page_lock_wait_in_ms,
    ios.index_lock_promotion_attempt_count,
    ios.index_lock_promotion_count,
    ios.page_latch_wait_count,
    ios.page_latch_wait_in_ms,
    ios.page_io_latch_wait_count,
    ios.page_io_latch_wait_in_ms,
    ios.tree_page_latch_wait_count,
    ios.tree_page_latch_wait_in_ms,
    ios.tree_page_io_latch_wait_count,
    ios.tree_page_io_latch_wait_in_ms,
    ios.page_compression_attempt_count,
    ios.page_compression_success_count,
    i.has_filter,
    i.is_disabled,
    i.ignore_dup_key,
    i.is_primary_key,
    i.is_unique,
    i.is_unique_constraint,
    i.auto_created,
    i.allow_row_locks,
    oa_columns.Columns,
    oa_columns.IncludeColumns,
    i.object_id,
    i.index_id,
    i.filter_definition,
    ips.avg_fragmentation_in_percent,
    oa_index_size.used_pages,
    oa_index_size.reserved_pages,
    oa_index_size.ReservedMB,
    oa_index_size.TotalUsedMB,
    oa_index_size.TotalDataMB,
    oa_index_size.UnusedMB,
    oa_index_size.IndexSizeKB,
    oa_index_size.RowCountTotal,
    sp.modification_counter,
    sp.persisted_sample_percent,
    sp.rows,
    sp.rows_sampled,
    sp.steps
    ORDER BY o.name ASC, i.index_id ASC
END

IF ISNULL(@showColumnStatistics, 0) = 1 BEGIN
    SELECT 
    OBJECT_SCHEMA_NAME(s.object_id) AS SchemaName,
    OBJECT_NAME(s.object_id) AS TableName,
    s.name AS StatisticsName,
    s.stats_id,
    c.name ColumnName,
    sp.last_updated AS LastUpdated, 
    sp.rows AS Rows,
    sp.rows_sampled, 
    sp.steps, 
    modification_counter AS ModCounter,
    persisted_sample_percent 
    PersistedSamplePercent,
    (rows_sampled * 100)/rows AS 'Sample %'
    FROM sys.stats s
    INNER JOIN sys.stats_columns sc ON s.stats_id = sc.stats_id AND s.object_id = sc.object_id
    INNER JOIN sys.columns c ON sc.column_id = c.column_id AND c.object_id = sc.object_id
    INNER JOIN sys.all_columns ac ON ac.column_id = sc.column_id AND ac.object_id = sc.object_id
    CROSS APPLY sys.dm_db_stats_properties(s.object_id, s.stats_id) sp
    WHERE (OBJECT_NAME(s.object_id) = @tableName OR @tableName IS NULL)
    ORDER BY OBJECT_NAME(s.object_id) ASC, s.stats_id, c.name ASC
END