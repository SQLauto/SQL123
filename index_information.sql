DECLARE @schemaName NVARCHAR(MAX) = NULL;
DECLARE @tableName NVARCHAR(100) = NULL;
DECLARE @indexName NVARCHAR(100) = NULL;
DECLARE @indexId BIGINT = NULL;

DECLARE @showIndexData BIT = 1;
DECLARE @unusedIndexes BIT = 0; -- Find out what indexes have never been used.
DECLARE @showBasicIndex BIT = 1; -- Basic items about a index.
DECLARE @showIndixLastUpate BIT = 0; -- Shows last updated information for an index.
DECLARE @showIndixUsage BIT = 0; -- Usage like index scans, seeks, and lookups.
DECLARE @showIndixColumns BIT = 0; -- Shows items like columns on the index, includes and filters.
DECLARE @showIndexLeadAndNonLeafUpdates BIT = 0;
DECLARE @showIndexLocks BIT = 0;
DECLARE @showIndexfullQuery BIT = 0;

DECLARE @showStatistics BIT = 0;

IF ISNULL(@showStatistics, 0) = 1 BEGIN
    SELECT 
    OBJECT_SCHEMA_NAME(s.object_id) AS SchemaName,
    OBJECT_NAME(s.object_id) AS TableName,
    s.name AS StatisticsName,
    s.stats_id AS StatId,
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
    ORDER BY s.object_id ASC, s.stats_id
END

IF ISNULL(@showIndexData, 0) = 1 BEGIN
    DROP TABLE IF EXISTS #TempStatistics;
    SELECT 
    OBJECT_SCHEMA_NAME(o.object_id) AS SchemaName,
    o.name AS TableName,
    i.name AS IndexName,
    i.object_id ObjectId,
    i.index_id AS IndexId,
    i.type_desc AS IndexType,
    i.is_disabled AS IsDisabled,
    i.auto_created AS IndexCreatedByAutomaticTuning,
    STATS_DATE(i.object_id,i.index_id) IndexStatisticsLastUpdatedOrCreated,
    DATEDIFF(d,STATS_DATE(i.object_id,i.index_id), GETDATE()) DaysOld,
    sp.modification_counter AS TotalNumberOfModificationsForLeadingStatisticsColumn,
    sp.rows AS RowsWhenStatisticsLastUpdated,
    sp.rows_sampled AS TotalNumberOfRowsSampledForStatisticsCalculations,
    (sp.rows_sampled * 100)/rows AS SamplePercent,
    sp.persisted_sample_percent PersistedSamplePercent,
    sp.steps AS NumberOfStepsInTheHistogram,
    i.allow_row_locks AS AllowRowLocks,
    o.create_date AS TableCreateDateTime, 
    o.modify_date AS TableModifyDateTime,
    ius.user_seeks AS UserSeek,
    ius.last_user_seek AS LastUserSeek,
    ius.user_scans AS UserScans,
    ius.last_user_scan AS LastUserScan,
    ius.user_lookups AS UserLookups,
    ius.last_user_lookup AS LastUserLookup,
    ius.user_updates AS UserUpdates,
    ius.last_user_update AS LastUserUpdates,
    ius.system_seeks AS SystemSeek,
    ius.last_system_seek AS LastSystemSeek,
    ius.system_scans AS SystemScans,
    ius.last_system_scan AS LastSystemScan,
    ius.system_lookups AS SystemLookups,
    ius.last_system_lookup AS LastSystemLookup,
    ius.system_updates AS SystemUpdates,
    ius.last_system_update AS LastSystemUpdates,
    ios.nonleaf_allocation_count AS NonLeafAllocationCount,
    ios.nonleaf_insert_count AS NonLeafInsertCount,
    ios.nonleaf_delete_count AS NonLeafDeleteCount,
    ios.nonleaf_update_count AS NonUpdatesLeafUpdate,
    ios.leaf_allocation_count AS LeafAllocationCount,
    ios.leaf_insert_count AS LeafInsertCount,
    ios.leaf_delete_count AS LeafDeleteCount,
    ios.leaf_update_count AS UpdatesLeafUpdate,
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
    INTO #TempStatistics
    FROM sys.indexes i 
    LEFT JOIN sys.dm_db_index_usage_stats ius ON i.index_id = ius.index_id AND ius.object_id = i.object_id
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
        SUBSTRING
        (
            (
                SELECT ', ' + c.name AS [text()]
                FROM sys.index_columns ic
                INNER JOIN sys.columns c ON c.column_id = ic.column_id AND c.object_id = ic.object_id
                WHERE ic.is_included_column = 0
                AND ic.object_id = i.object_id
                AND i.index_id = ic.index_id
                FOR XML PATH ('')
            ), 3, 1000
        ) AS Columns,
        SUBSTRING
        (
            (
                SELECT ', ' + c.name AS [text()]
                FROM sys.index_columns ic
                INNER JOIN sys.columns c ON c.column_id = ic.column_id AND c.object_id = ic.object_id
                WHERE ic.is_included_column = 1
                AND ic.object_id = i.object_id
                AND i.index_id = ic.index_id
                FOR XML PATH ('')
            ), 3, 1000
        ) AS IncludeColumns
    ) oa_columns
    WHERE (o.name = @tableName OR @tableName IS NULL)
    AND (i.name = @indexName OR @indexName IS NULL)
    AND (i.index_id = @indexId OR @indexId IS NULL)
    AND (OBJECT_SCHEMA_NAME(o.object_id) = @schemaName OR @schemaName IS NULL)
    AND OBJECT_SCHEMA_NAME(o.object_id) != 'sys';

    IF ISNULL(@unusedIndexes, 1) = 1 BEGIN
        SELECT IndexId, SchemaName, TableName, IndexName, IndexType, ObjectId, DaysOld,
        RowCountTotal AS CurrentRows, TotalNumberOfModificationsForLeadingStatisticsColumn AS RowsModificatedLastUpdated, 
        IsDisabled, IndexCreatedByAutomaticTuning AS ByAutomaticTuning,
        IndexSizeKB, TotalUsedMB,TotalDataMB,ReservedMB,UnusedMB,
        used_pages AS UsedPages, reserved_pages As ReservedPages,
        IndexStatisticsLastUpdatedOrCreated AS IndexLastUpdated, TableCreateDateTime AS TableCreate, TableModifyDateTime AS TableModify
        FROM #TempStatistics
        WHERE IndexStatisticsLastUpdatedOrCreated IS NULL
        ORDER BY TableName ASC, IndexId ASC;
    END

    IF ISNULL(@showBasicIndex, 1) = 1 BEGIN
        SELECT IndexId, SchemaName, TableName, IndexName, IndexType, ObjectId, DaysOld,
        RowCountTotal AS CurrentRows, TotalNumberOfModificationsForLeadingStatisticsColumn AS RowsModificatedLastUpdated, 
        IsDisabled, IndexCreatedByAutomaticTuning AS ByAutomaticTuning,
        IndexSizeKB, TotalUsedMB,TotalDataMB,ReservedMB,UnusedMB,
        used_pages AS UsedPages, reserved_pages As ReservedPages,
        IndexStatisticsLastUpdatedOrCreated AS IndexLastUpdated, TableCreateDateTime AS TableCreate, TableModifyDateTime AS TableModify
        FROM #TempStatistics
        ORDER BY TableName ASC, IndexId ASC;
    END

    IF ISNULL(@showIndixLastUpate, 1) = 1 BEGIN
        SELECT IndexId, SchemaName, TableName, IndexName,
        IndexStatisticsLastUpdatedOrCreated AS IndexUpdated, DaysOld,
        RowCountTotal AS CurrentRows,
        TotalNumberOfModificationsForLeadingStatisticsColumn AS RowsModificatedLastUpdated,
        TotalNumberOfRowsSampledForStatisticsCalculations AS RowsSampled,
        SamplePercent,PersistedSamplePercent,NumberOfStepsInTheHistogram AS StepsInHistogram
        FROM #TempStatistics
        ORDER BY TableName ASC, IndexId ASC;
    END

     IF ISNULL(@showIndixUsage, 1) = 1 BEGIN
        SELECT IndexId, SchemaName, TableName, IndexName, RowCountTotal AS CurrentRows,
        UserSeek, LastUserSeek, UserScans, LastUserScan, UserLookups, LastUserLookup, UserUpdates,LastUserUpdates,
        SystemSeek, LastSystemSeek, SystemScans, LastSystemScan, SystemLookups, LastSystemLookup, SystemUpdates, LastSystemUpdates,
        LeafInsertCount,LeafDeleteCount,UpdatesLeafUpdate
        FROM #TempStatistics
        ORDER BY TableName ASC, IndexId ASC;
    END   

    IF ISNULL(@showIndixColumns, 1) = 1 BEGIN
        SELECT IndexId, SchemaName, TableName, IndexName,
        IndexColumns,IncludeColumns,HasFilter,IndexWhereFilter,IgnoreDupKey,IsPrimaryKey,IsUniqueConstraint
        FROM #TempStatistics
        ORDER BY TableName ASC, IndexId ASC;
    END
    
    IF ISNULL(@showIndexLeadAndNonLeafUpdates, 1) = 1 BEGIN
        SELECT IndexId, SchemaName, TableName, IndexName, IndexType, ObjectId,
        RowCountTotal AS CurrentRows, TotalNumberOfModificationsForLeadingStatisticsColumn AS RowsModificatedLastUpdated, 
        NonLeafAllocationCount, NonLeafInsertCount, NonLeafDeleteCount, NonUpdatesLeafUpdate, LeafAllocationCount
        FROM #TempStatistics
        ORDER BY TableName ASC, IndexId ASC;
    END
    
    IF ISNULL(@showIndexLocks, 1) = 1 BEGIN
        SELECT IndexId, SchemaName, TableName, IndexName, RowCountTotal AS CurrentRows,
        RowLockCount, RowLockWaitCount,RowLockWaitMilliseconds,
        page_lock_count AS PageLockCount, page_lock_wait_count,page_lock_wait_in_ms,
        index_lock_promotion_attempt_count,index_lock_promotion_count,page_latch_wait_count, page_latch_wait_in_ms,
        page_io_latch_wait_count,page_io_latch_wait_in_ms,tree_page_latch_wait_count,tree_page_latch_wait_in_ms,
        page_compression_attempt_count,page_compression_success_count
        FROM #TempStatistics
        ORDER BY TableName ASC, IndexId ASC;
    END

    IF ISNULL(@showIndexfullQuery, 1) = 1 BEGIN
        SELECT * 
        FROM #TempStatistics
        ORDER BY TableName ASC, IndexId ASC;
    END
END