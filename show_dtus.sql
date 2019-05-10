DECLARE @dt DATETIME2 = DATEADD(minute, -120, GETDATE())

DECLARE @showAllAzureLimits BIT = 1;
DECLARE @showAzureMemoryUsage BIT = 1
DECLARE @showAzureCpu BIT = 0;
DECLARE @showAvgDataIoPercent BIT = 0;
DECLARE @showAvgLogWritePercent BIT = 0;
DECLARE @showAvgLoginRatePercent BIT = 0;
DECLARE @showAvgXtpStoragePercent BIT = 0;
DECLARE @showAvgMaxWorkerPercent BIT = 0;
DECLARE @showMaxSessionPercent BIT = 0;
DECLARE @showInstanceCpuPercent BIT = 0;
DECLARE @showAzureInstanceMemory BIT = 0;
DECLARE @showOverPercent FLOAT = 40;

SELECT 
'Memory Usage' AS DataPointLimitType,
GETDATE() AS CurrentDateTime,
end_time AS EndDteTime,
s.dtu_limit AS DtuLimit,
s.cpu_limit AS CpuLimit,
MaxAvgPercent AS AvgPercent
FROM sys.dm_db_resource_stats s
JOIN (
    SELECT MAX(avg_memory_usage_percent) AS MaxAvgPercent
    FROM sys.dm_db_resource_stats
    WHERE end_time >= @dt
    AND (@showAllAzureLimits = 1 OR @showAzureMemoryUsage = 1)
    AND avg_memory_usage_percent > @showOverPercent
) AS max_memory ON max_memory.MaxAvgPercent = s.avg_memory_usage_percent
WHERE end_time >= @dt
AND MaxAvgPercent <> 0.00
UNION ALL
SELECT 
'CPU' AS DataPointLimitType,
GETDATE() AS CurrentDateTime,
end_time AS EndDteTime,
s.dtu_limit AS DtuLimit,
s.cpu_limit AS CpuLimit,
MaxAvgPercent AS AvgPercent
FROM sys.dm_db_resource_stats s
JOIN (
    SELECT MAX(avg_cpu_percent) AS MaxAvgPercent
    FROM sys.dm_db_resource_stats
    WHERE end_time >= @dt
    AND (@showAllAzureLimits = 1 OR @showAzureCpu = 1)
    AND avg_cpu_percent > @showOverPercent
) AS max_avg ON max_avg.MaxAvgPercent = s.avg_cpu_percent
WHERE end_time >= @dt
AND MaxAvgPercent <> 0.00
UNION ALL
SELECT 
'Data IO' AS DataPointLimitType,
GETDATE() AS CurrentDateTime,
end_time AS EndDteTime,
s.dtu_limit AS DtuLimit,
s.cpu_limit AS CpuLimit,
MaxAvgPercent AS AvgPercent
FROM sys.dm_db_resource_stats s
JOIN (
    SELECT MAX(avg_data_io_percent) AS MaxAvgPercent
    FROM sys.dm_db_resource_stats
    WHERE end_time >= @dt
    AND (@showAllAzureLimits = 1 OR @showAvgDataIoPercent = 1)
    AND avg_data_io_percent > @showOverPercent
) AS max_avg ON max_avg.MaxAvgPercent = s.avg_data_io_percent
WHERE end_time >= @dt
AND MaxAvgPercent <> 0.00
UNION ALL
SELECT 
'Log Write' AS DataPointLimitType,
GETDATE() AS CurrentDateTime,
end_time AS EndDteTime,
s.dtu_limit AS DtuLimit,
s.cpu_limit AS CpuLimit,
MaxAvgPercent AS AvgPercent
FROM sys.dm_db_resource_stats s
JOIN (
    SELECT MAX(avg_log_write_percent) AS MaxAvgPercent
    FROM sys.dm_db_resource_stats
    WHERE end_time >= @dt
    AND (@showAllAzureLimits = 1 OR @showAvgLogWritePercent = 1)
    AND avg_log_write_percent > @showOverPercent
) AS max_log_write ON max_log_write.MaxAvgPercent = s.avg_log_write_percent
WHERE end_time >= @dt
AND MaxAvgPercent <> 0.00
UNION ALL
SELECT 
'Login Rate' AS DataPointLimitType,
GETDATE() AS CurrentDateTime,
end_time AS EndDteTime,
s.dtu_limit AS DtuLimit,
s.cpu_limit AS CpuLimit,
MaxAvgPercent AS AvgPercent
FROM sys.dm_db_resource_stats s
JOIN (
    SELECT MAX(avg_login_rate_percent) AS MaxAvgPercent
    FROM sys.dm_db_resource_stats
    WHERE end_time >= @dt
    AND (@showAllAzureLimits = 1 OR @showAvgLoginRatePercent = 1)
    AND avg_login_rate_percent > @showOverPercent
) AS max_log_write ON max_log_write.MaxAvgPercent = s.avg_login_rate_percent
WHERE end_time >= @dt
AND MaxAvgPercent <> 0.00
UNION ALL
SELECT 
'XTP Storage' AS DataPointLimitType,
GETDATE() AS CurrentDateTime,
end_time AS EndDteTime,
s.dtu_limit AS DtuLimit,
s.cpu_limit AS CpuLimit,
MaxAvgPercent AS AvgPercent
FROM sys.dm_db_resource_stats s
JOIN (
    SELECT MAX(xtp_storage_percent) AS MaxAvgPercent
    FROM sys.dm_db_resource_stats
    WHERE end_time >= @dt
    AND (@showAllAzureLimits = 1 OR @showAvgXtpStoragePercent = 1)
    AND xtp_storage_percent > @showOverPercent
) AS max_log_write ON max_log_write.MaxAvgPercent = s.xtp_storage_percent
WHERE end_time >= @dt
AND MaxAvgPercent <> 0.00
UNION ALL
SELECT 
'Max Worker' AS DataPointLimitType,
GETDATE() AS CurrentDateTime,
end_time AS EndDteTime,
s.dtu_limit AS DtuLimit,
s.cpu_limit AS CpuLimit,
MaxAvgPercent AS AvgPercent
FROM sys.dm_db_resource_stats s
JOIN (
    SELECT MAX(max_worker_percent) AS MaxAvgPercent
    FROM sys.dm_db_resource_stats
    WHERE end_time >= @dt
    AND (@showAllAzureLimits = 1 OR @showAvgMaxWorkerPercent = 1)
    AND max_worker_percent > @showOverPercent
) AS max_log_write ON max_log_write.MaxAvgPercent = s.max_worker_percent
WHERE end_time >= @dt
AND MaxAvgPercent <> 0.00
UNION ALL
SELECT 
'Max Session' AS DataPointLimitType,
GETDATE() AS CurrentDateTime,
end_time AS EndDteTime,
s.dtu_limit AS DtuLimit,
s.cpu_limit AS CpuLimit,
MaxAvgPercent AS AvgPercent
FROM sys.dm_db_resource_stats s
JOIN (
    SELECT MAX(max_session_percent) AS MaxAvgPercent
    FROM sys.dm_db_resource_stats
    WHERE end_time >= @dt
    AND (@showAllAzureLimits = 1 OR @showMaxSessionPercent = 1)
    AND max_session_percent > @showOverPercent
) AS max_log_write ON max_log_write.MaxAvgPercent = s.max_session_percent
WHERE end_time >= @dt
AND MaxAvgPercent <> 0.00
UNION ALL
SELECT 
'Instance Cpu' AS DataPointLimitType,
GETDATE() AS CurrentDateTime,
end_time AS EndDteTime,
s.dtu_limit AS DtuLimit,
s.cpu_limit AS CpuLimit,
MaxAvgPercent AS AvgPercent
FROM sys.dm_db_resource_stats s
JOIN (
    SELECT MAX(avg_instance_cpu_percent) AS MaxAvgPercent
    FROM sys.dm_db_resource_stats
    WHERE end_time >= @dt
    AND (@showAllAzureLimits = 1 OR @showInstanceCpuPercent = 1)
    AND avg_instance_cpu_percent > @showOverPercent
) AS max_log_write ON max_log_write.MaxAvgPercent = s.avg_instance_cpu_percent
WHERE end_time >= @dt
AND MaxAvgPercent <> 0.00
UNION ALL
SELECT 
'Instance Memory' AS DataPointLimitType,
GETDATE() AS CurrentDateTime,
end_time AS EndDteTime,
s.dtu_limit AS DtuLimit,
s.cpu_limit AS CpuLimit,
MaxAvgPercent AS AvgPercent
FROM sys.dm_db_resource_stats s
JOIN (
    SELECT MAX(avg_instance_memory_percent) AS MaxAvgPercent
    FROM sys.dm_db_resource_stats
    WHERE end_time >= @dt
    AND (@showAllAzureLimits = 1 OR @showAzureInstanceMemory = 1)
    AND avg_instance_memory_percent > @showOverPercent
) AS max_log_write ON max_log_write.MaxAvgPercent = s.avg_instance_memory_percent
WHERE end_time >= @dt
AND MaxAvgPercent <> 0.00
ORDER BY DataPointLimitType, EndDteTime DESC


-- select * from sys.dm_db_resource_stats