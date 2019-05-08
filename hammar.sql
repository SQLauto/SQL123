DECLARE @dt DATETIME2 = DATEADD(minute, -120, GETDATE());
SELECT
    qsp.plan_id,
    qsq.query_id,
    qsq.object_id,
    OBJECT_NAME(qsq.object_id) AS 'Database Object',
    ca_aggregate_runtime_stats.FirstExecutionTime,
    ca_aggregate_runtime_stats.LastExecutionTime,
    FORMAT(ca_runtime_executions.TotalExections, '###,###,###') AS TotalExections,
    FORMAT(ca_runtime_executions.TotalDuration, '###,###,###') AS TotalDuration,
    Convert(varchar(1000), FLOOR(ca_runtime_executions.TotalDuration/(10006060))) + 'h ' +
Convert(varchar(1000), FLOOR(( ca_runtime_executions.TotalDuration%(10006060))/(100060))) + 'm ' +
Convert(varchar(1000), FLOOR(((ca_runtime_executions.TotalDuration%(10006060))%(100060))/1000)) + 's ' +
Convert(varchar(1000), FLOOR(((ca_runtime_executions.TotalDuration%(10006060))%(100060))%1000)) + 'ms' AS TotalDurationInFormat,
    CONVERT(VARCHAR(100), CAST(ca_aggregate_runtime_stats.AvgDuration AS FLOAT) / 1000) + ' milliseconds' AS 'Avg Duration in Milliseconds',
    CONVERT(VARCHAR(100), CAST(ca_aggregate_runtime_stats.LastDuration AS FLOAT) / 1000) + ' milliseconds' AS 'Last Duration in Milliseconds',
    CONVERT(VARCHAR(100), CAST(ca_aggregate_runtime_stats.MaxDuration AS FLOAT) / 1000) + ' milliseconds' AS 'Max Duration in Milliseconds',
    CONVERT(VARCHAR(100), CAST(ca_aggregate_runtime_stats.MinDuration AS FLOAT) / 1000) + ' milliseconds' AS 'Min Duration in Milliseconds',
    LEN(qsqt.query_sql_text) AS SQLTextLength,
    qsqt.query_sql_text,
    ca_queries_for_plan.total_queries_for_plan AS 'Queries For Plan',
    ca_aggregate_runtime_stats.AvgRowCount,
    ca_aggregate_runtime_stats.LastRowCount,
    ca_aggregate_runtime_stats.MaxRowCount,
    ca_aggregate_runtime_stats.MinRowCount,
    CONVERT(VARCHAR(100), CAST(ca_aggregate_runtime_stats.AvgCpuTime AS FLOAT) / 1000) + ' milliseconds' AS 'Avg CPU in Milliseconds',
    CONVERT(VARCHAR(100), CAST(ca_aggregate_runtime_stats.LastCpuTime AS FLOAT) / 1000) + ' milliseconds' AS 'Last CPU in Milliseconds',
    CONVERT(VARCHAR(100), CAST(ca_aggregate_runtime_stats.MaxCpuTime AS FLOAT) / 1000) + ' milliseconds' AS 'Max CPU in Milliseconds',
    CONVERT(VARCHAR(100), CAST(ca_aggregate_runtime_stats.MinCpuTime AS FLOAT) / 1000) + ' milliseconds' AS 'Min CPU in Milliseconds',
    ca_aggregate_runtime_stats.AvgMaxUsedMemory * 0.001 AS 'Avg MemoryInMegabytes',
    ca_aggregate_runtime_stats.LastMaxUsedMemory * 0.001 AS 'Last MemoryInMegabytes',
    ca_aggregate_runtime_stats.MaxMaxUsedMemory * 0.001 AS 'Min MemoryInMegabytes',
    ca_aggregate_runtime_stats.MinMaxUsedMemory * 0.001 AS 'Max MemoryInMegabytes',
    ca_aggregate_runtime_stats.AvgDop AS 'Avg Degree of Parallelism',
    ca_aggregate_runtime_stats.LastDop AS 'Last Degree of Parallelism',
    ca_aggregate_runtime_stats.MaxDop AS 'Max Degree of Parallelism',
    ca_aggregate_runtime_stats.MinDop AS 'Min Degree of Parallelism',
    ca_aggregate_runtime_stats.AvgLogicalIoReads,
    ca_aggregate_runtime_stats.LastLogicalIoReads,
    ca_aggregate_runtime_stats.MaxLogicalIoReads,
    ca_aggregate_runtime_stats.MinLogicalIoReads,
    ca_aggregate_runtime_stats.AvgLogicalIoWrites,
    ca_aggregate_runtime_stats.LastLogicalIoWrites,
    ca_aggregate_runtime_stats.MaxLogicalIoWrites,
    ca_aggregate_runtime_stats.MinLogicalIoWrites,
    ca_aggregate_runtime_stats.AvgPhysicalIoReads,
    ca_aggregate_runtime_stats.LastPhysicalIoReads,
    ca_aggregate_runtime_stats.MaxPhysicalIoReads,
    ca_aggregate_runtime_stats.MinPhysicalIoReads,
    ca_aggregate_runtime_stats.AvgNumPhysicalIoReads,
    ca_aggregate_runtime_stats.LastNumPhysicalIoReads,
    ca_aggregate_runtime_stats.MaxNumPhysicalIoReads,
    ca_aggregate_runtime_stats.MinNumPhysicalIoReads,
    CAST(qsp.query_plan AS XML) AS 'Execution Plan'
FROM sys.query_store_plan qsp (NOLOCK)
    INNER JOIN sys.query_store_query qsq (NOLOCK)
    ON qsp.query_id = qsq.query_id
    INNER JOIN sys.query_store_query_text qsqt (NOLOCK)
    ON qsq.query_text_id = qsqt.query_text_id
CROSS APPLY
(
SELECT
        MAX(qrs.last_execution_time) AS LastExecutionTime, MIN(qrs.first_execution_time) AS FirstExecutionTime,
        AVG(qrs.avg_rowcount) AS AvgRowCount, MAX(qrs.last_rowcount) AS LastRowCount, MAX(qrs.max_rowcount) AS MaxRowCount, MIN(qrs.min_rowcount) AS MinRowCount,
        AVG(qrs.avg_duration) AS AvgDuration, MAX(qrs.last_duration) AS LastDuration, MAX(qrs.max_duration) AS MaxDuration, MIN(qrs.min_duration) AS MinDuration,
        AVG(qrs.avg_cpu_time) AS AvgCpuTime, MAX(qrs.last_cpu_time) AS LastCpuTime, MAX(qrs.max_cpu_time) AS MaxCpuTime, MIN(qrs.min_cpu_time) AS MinCpuTime,
        AVG(qrs.avg_query_max_used_memory) AS AvgMaxUsedMemory, MAX(qrs.last_query_max_used_memory) AS LastMaxUsedMemory, MAX(qrs.max_query_max_used_memory) AS MaxMaxUsedMemory, MIN(qrs.min_query_max_used_memory) AS MinMaxUsedMemory,
        AVG(qrs.avg_dop) AS AvgDop, MAX(qrs.last_dop) AS LastDop, MAX(qrs.max_dop) AS MaxDop, MIN(qrs.min_dop) AS MinDop,
        AVG(qrs.avg_logical_io_reads) AS AvgLogicalIoReads, MAX(qrs.last_logical_io_reads) AS LastLogicalIoReads, MAX(qrs.max_logical_io_reads) AS MaxLogicalIoReads, MIN(qrs.min_logical_io_reads) AS MinLogicalIoReads,
        AVG(qrs.avg_logical_io_writes) AS AvgLogicalIoWrites, MAX(qrs.last_logical_io_writes) AS LastLogicalIoWrites, MAX(qrs.max_logical_io_writes) AS MaxLogicalIoWrites, MIN(qrs.min_logical_io_writes) AS MinLogicalIoWrites,
        AVG(qrs.avg_physical_io_reads) AS AvgPhysicalIoReads, MAX(qrs.last_physical_io_reads) AS LastPhysicalIoReads, MAX(qrs.max_physical_io_reads) AS MaxPhysicalIoReads, MIN(qrs.min_physical_io_reads) AS MinPhysicalIoReads,
        AVG(qrs.avg_num_physical_io_reads) AS AvgNumPhysicalIoReads, MAX(qrs.last_num_physical_io_reads) AS LastNumPhysicalIoReads, MAX(qrs.max_num_physical_io_reads) AS MaxNumPhysicalIoReads, MIN(qrs.min_num_physical_io_reads) AS MinNumPhysicalIoReads
    FROM sys.query_store_runtime_stats qrs (NOLOCK)
        INNER JOIN sys.query_store_runtime_stats_interval i on qrs.runtime_stats_interval_id = i.runtime_stats_interval_id
    WHERE qrs.plan_id = qsp.plan_id
        AND i.end_time >= @dt
    GROUP BY qrs.plan_id
) ca_aggregate_runtime_stats
CROSS APPLY
(
SELECT CONVERT(int, SUM(rs.avg_duration))*0.001 AS TotalDuration,
        SUM(rs.count_executions) AS TotalExections
    FROM sys.query_store_runtime_stats rs (NOLOCK)
    WHERE rs.plan_id = qsp.plan_id
        AND rs.first_execution_time >= @dt
    GROUP BY rs.plan_id
) ca_runtime_executions
CROSS APPLY
(
SELECT COUNT(ca_qsp.query_id) AS total_queries_for_plan
    FROM sys.query_store_plan AS ca_qsp
    WHERE ca_qsp.plan_id = qsp.plan_id
    GROUP BY ca_qsp.plan_id
) ca_queries_for_plan
WHERE qsqt.query_sql_text NOT LIKE N'%sys.query_store%'
    AND qsqt.query_sql_text NOT LIKE N'%sys.dm%'
-- AND qsqt.has_restricted_text LIKE '%@p100%'
ORDER BY ca_aggregate_runtime_stats.AvgDuration DESC
--ORDER BY ca_aggregate_runtime_stats.AvgCpuTime DESC
--ORDER BY ca_aggregate_runtime_stats.AvgMaxUsedMemory DESC
--ORDER BY ca_runtime_executions.TotalDuration DESC
--ORDER BY ca_runtime_executions.TotalExections DESC