-- MAAIgnore
IF SERVERPROPERTY('Edition') = 'SQL Azure' 
BEGIN
   IF DB_NAME() = 'master' BEGIN
    SELECT
    rs.database_name AS DatabaseName,
    sku AS SKU,
    FORMAT(allocated_storage_in_megabytes, N'N0') AS AllocatedSizeInMB,
    FORMAT(storage_in_megabytes, N'N0') AS AllocatedSizeUnusedInMB,
    CAST(CAST(storage_in_megabytes/allocated_storage_in_megabytes  * 100 AS DECIMAL(10,2)) AS VARCHAR(50)) + '%'  AS PercentUsed
    FROM sys.resource_stats rs
   END
   ELSE BEGIN
    SELECT
    DB_NAME() AS DatabaseName, 
    FORMAT(SUM(size/128.0), N'N0') AS AllocatedSizeInMB,
    FORMAT(SUM(size/128.0 - CAST(FILEPROPERTY(name, 'SpaceUsed') AS int)/128.0), N'N0') AS AllocatedSizeUnusedInMB,
    CAST(CAST(SUM(size/128.0 - CAST(FILEPROPERTY(name, 'SpaceUsed') AS int)/128.0) / SUM(size/128.0) * 100 AS DECIMAL(10,2)) AS VARCHAR(50)) + '%' AS PercentUsed
    FROM sys.database_files df
    GROUP BY type_desc
    HAVING type_desc = 'ROWS'
    -- SELECT FILEPROPERTY('VirtueScript', 'MaxSizeInBytes'), * FROM sys.database_files df 
   END
END
ELSE BEGIN
    SELECT 
    d.Name AS DatabaseName,
    FORMAT(SUM(max_size/8/128.0), N'N0') AS AllocatedSizeInMB,
    FORMAT(SUM(CAST(mf.size AS BIGINT))*8/1024, N'N0') AS AllocatedSizeUnusedInMB,
    CAST(CAST(IIF(SUM(max_size) < 0, 0, SUM(CAST(mf.size AS BIGINT))*8/1024/SUM(max_size/8/128.0))*100 AS DECIMAL(10,2)) AS NVARCHAR(50)) + '%' AS PercentUsed
    FROM sys.master_files mf
    INNER JOIN sys.databases d ON d.database_id = mf.database_id
    GROUP BY d.Name, d.database_id
    ORDER BY d.database_id
END
