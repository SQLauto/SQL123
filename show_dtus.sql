DECLARE @dt DATETIME2 = DATEADD(minute, -120, GETDATE())
SELECT DISTINCT
    MIN(end_time) AS 'Start Time',
    MAX(end_time) AS 'End Time',
    CAST(AVG(avg_cpu_percent) AS decimal(4,2)) AS 'Avg CPU',
    MAX(avg_cpu_percent) AS 'Max CPU',
    MIN(avg_cpu_percent) AS 'Min CPU',
    CAST(AVG(avg_data_io_percent) AS decimal(4,2)) AS 'Avg IO',
    Min(avg_data_io_percent) AS 'Min IO',
    MAX(avg_data_io_percent) AS 'Max IO',
    CAST(AVG(avg_log_write_percent) AS decimal(4,2)) AS 'Avg Log Write',
    MIN(avg_log_write_percent) AS 'Min Log Write',
    MAX(avg_log_write_percent) AS 'Max Log Write',
    CAST(AVG(avg_memory_usage_percent) AS decimal(4,2)) AS 'Avg Memory',
    MIN(avg_memory_usage_percent) AS 'Min Memory',
    MAX(avg_memory_usage_percent) AS 'Max Memory'
ROM sys.dm_db_resource_stats
WHERE end_time >= @dt