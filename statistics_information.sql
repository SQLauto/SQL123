-- MAAIgnore
-- Statistics: https://docs.microsoft.com/en-us/sql/relational-databases/statistics/statistics
-- Cardinality Estimation: https://docs.microsoft.com/en-us/sql/relational-databases/performance/cardinality-estimation-sql-serve
-- Row Estimates: https://dba.stackexchange.com/questions/186193/statistics-and-row-estimation
-- Selectivity : https://www.programmerinterview.com/database-sql/selectivity-in-sql-databases/
DECLARE @schemaName NVARCHAR(MAX) = NULL;
DECLARE @tableName NVARCHAR(MAX) = NULL;
DECLARE @statName NVARCHAR(MAX) = NULL;
DECLARE @orderByModification BIT = 0;
DECLARE @thresholdSqrtPercent BIT = 1;
DECLARE @threshold20Percent BIT = 0;

-- Statistics
-- AVG_RANGE_ROWS = RANGE_ROWS/DISTINCT_RANGE_ROWS

-- column = @variable: When doing an equal with a variable, the value of the variable is not known.
-- All density * Rows on the Statistics 

-- column < @variable: When doing an equal with a variable, the value of the variable is not known.
-- 30% * Rows on the Statistics 

-- DBCC SHOW_STATISTICS('MyTable', MyStatisticsName);
-- Put OPTION(QUERYTRACEON 3604, QUERYTRACEON 2363) at and end of a query to find out why statistics are being used. Will give you the selectivity for the statistic and the calculation being performed and the stat id it used.
-- ALTER DATABASE <DatabaseName/CURRENT> SET AUTO_CREATE_STATISTICS (ON|OFF);
-- ALTER DATABASE <DatabaseNam/CURRENTe> SET AUTO_UPDATE_STATISTICS (ON|OFF);
-- ALTER DATABASE <DatabaseName/CURRENT> SET AUTO_UPDATE_STATISTICS_ASYNC (ON|OFF);
-- SELECT name, is_auto_update_stats_on, is_auto_update_stats_async_on, is_auto_create_stats_on, is_auto_create_stats_incremental_on FROM sys.databases
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

-- Create Statistics
-- CREATE STATISTICS <Stats Name> ON <schema>.<table>(<column>)

-- DROPPING Statistics
-- DROP STATISTICS <table>.<statistics name>;


SELECT
OBJECT_SCHEMA_NAME(s.object_id) AS SchemaName,
OBJECT_NAME(s.object_id) AS TableName,
s.name AS StatisticsName,
s.stats_id AS StatId,
-- 1 Means that statistics will not auto update for an index.
-- 0 Means that statistics will update for an index.
s.no_recompute AS Noecompute,
c.name ColumnName,
sp.last_updated AS StatsLastUpdated, 
FORMAT(sp.rows, N'N0') AS StatsRowsOnUpdate,
FORMAT(sp.modification_counter, N'N0') AS Modifications,
FORMAT((CAST(sp.modification_counter AS FLOAT)/CAST(sp.rows AS FLOAT))*100, N'N0') + '%'  AS 'Modification %',
FORMAT(500+(0.20*sp.rows), N'N0') AS '20% Threshold',
CAST(FORMAT(FLOOR(sp.modification_counter/(500+(0.20*sp.rows)) * 100), N'N0') AS NVARCHAR(20)) + '%' AS '% to 20% Threshold',
FORMAT(SQRT(sp.rows*1000), N'N0') AS 'SQRT Threshold',
CAST(FORMAT(FLOOR(sp.modification_counter/(SQRT(sp.rows*1000)) * 100), 'N0') AS NVARCHAR(20)) + '%' AS '% to SQRT Threshold',
sp.persisted_sample_percent AS 'PersistedSample %',
FORMAT(sp.rows_sampled, N'N0') AS RowsSampled, 
FORMAT(((sp.rows_sampled * 100)/sp.rows), 'N0') + '%' AS 'Sample %',
sp.steps AS StatsSteps,
s.user_created AS IsUserCreated,
s.auto_created AS IsAutoCreated,
s.auto_drop AS IsAutoDrop,
s.filter_definition AS FilterDefinition,
s.has_persisted_sample AS PersistedSample,
s.is_incremental AS IsIncremental,
s.is_temporary As IsTemporary,
s.no_recompute AS NoRecompile,
s.stats_generation_method_desc AS StatsGenerationMethodDesc,
c.max_length AS MaxLength,
c.is_ansi_padded AS AnsiPadded,
c.is_column_set AS IsColumnSet,
c.is_data_deletion_filter_column AS DataDeletionFilter_Column,
c.is_dts_replicated AS IsDtsReplicated,
c.is_filestream AS IsFileStream,
c.is_hidden AS IsHidden,
c.is_identity AS IsIdentity,
c.is_masked AS IsMasked,
c.is_merge_published AS IsMergePublished,
c.is_non_sql_subscribed AS IsNonSqlSubscribed,
c.is_nullable AS IsNullable,
c.is_replicated AS IsReplicated,
c.is_rowguidcol AS IsRowGuidCol,
c.is_sparse AS Sparse,
c.is_xml_document AS IsXmlDocument
FROM sys.stats s
INNER JOIN sys.stats_columns sc ON s.stats_id = sc.stats_id AND s.object_id = sc.object_id
INNER JOIN sys.columns c ON sc.column_id = c.column_id AND c.object_id = sc.object_id
INNER JOIN sys.all_columns ac ON ac.column_id = sc.column_id AND ac.object_id = sc.object_id
CROSS APPLY sys.dm_db_stats_properties(s.object_id, s.stats_id) sp
WHERE (OBJECT_SCHEMA_NAME(s.object_id) = @schemaName OR @schemaName IS NULL)
AND (OBJECT_NAME(s.object_id) = @tableName OR @tableName IS NULL)
AND (s.name = @statName OR @statName IS NULL)
AND OBJECT_SCHEMA_NAME(s.object_id) != 'sys'
ORDER BY
CASE WHEN ISNULL(@threshold20Percent, 0) = 1 THEN FLOOR(sp.modification_counter/(500+(0.20*sp.rows)) * 100) END DESC,
CASE WHEN ISNULL(@thresholdSqrtPercent, 0) = 1 THEN FLOOR(sp.modification_counter/(SQRT(sp.rows*1000)) * 100) END DESC,
CASE WHEN ISNULL(@orderByModification, 0) = 1 THEN sp.modification_counter END DESC,
OBJECT_NAME(s.object_id) ASC, s.stats_id ASC




