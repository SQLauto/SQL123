-- Statistics: https://docs.microsoft.com/en-us/sql/relational-databases/statistics/statistics
-- Cardinality Estimation: https://docs.microsoft.com/en-us/sql/relational-databases/performance/cardinality-estimation-sql-serve
-- Row Estimates: https://dba.stackexchange.com/questions/186193/statistics-and-row-estimation
DECLARE @schemaName NVARCHAR(MAX) = NULL;
DECLARE @tableName NVARCHAR(MAX) = NULL;
DECLARE @statName NVARCHAR(MAX) = NULL;

-- ALTER DATABASE CURRENT SET AUTO_UPDATE_STATISTICS OFF;
-- ALTER DATABASE CURRENT SET AUTO_UPDATE_STATISTICS ON;

-- DBCC SHOW_STATISTICS('<schema>.<table name>',<index name>);
-- Put OPTION(QUERYTRACEON 3604, QUERYTRACEON 2363) at and end of a query to find out why statistics are being used.
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
sp.steps StatsSteps, 
FORMAT(500+(0.20*sp.rows), N'N0') AS '20% Threshold',
FORMAT(SQRT( sp.rows*1000), N'N0') AS 'SQRT Threshold',
FORMAT(sp.modification_counter, N'N0') AS Modifications,
FORMAT((CAST(sp.modification_counter AS FLOAT)/CAST(sp.rows AS FLOAT))*100, N'N0') + '%'  AS 'Modification %',
sp.persisted_sample_percent AS 'PersistedSample %',
FORMAT(sp.rows_sampled, N'N0') AS RowsSampled, 
FORMAT(((sp.rows_sampled * 100)/sp.rows), 'N0') + '%' AS 'Sample %'
FROM sys.stats s
INNER JOIN sys.stats_columns sc ON s.stats_id = sc.stats_id AND s.object_id = sc.object_id
INNER JOIN sys.columns c ON sc.column_id = c.column_id AND c.object_id = sc.object_id
INNER JOIN sys.all_columns ac ON ac.column_id = sc.column_id AND ac.object_id = sc.object_id
CROSS APPLY sys.dm_db_stats_properties(s.object_id, s.stats_id) sp
WHERE (OBJECT_SCHEMA_NAME(s.object_id) = @schemaName OR @schemaName IS NULL)
AND (OBJECT_NAME(s.object_id) = @tableName OR @tableName IS NULL)
AND (s.name = @statName OR @statName IS NULL)
AND OBJECT_SCHEMA_NAME(s.object_id) != 'sys'
ORDER BY OBJECT_NAME(s.object_id) ASC, s.stats_id




