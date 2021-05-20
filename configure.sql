DECLARE @vieOnly BIT = 1;
DECLARE @updateConfig BIT = 0;

DECLARE @updateCostThresholdForParallelism BIT = 0;
-- This will remove all execution plans.
DECLARE @costThresholdForParallelism INT = 50;s

-- If you get an error, run the lines above first 
-- Minimum should be between 4 and 8
DECLARE @updateMaxdop BIT = 0;
DECLARE @maxdop INT = 4;

DECLARE @updateBackupChecksumDefault BIT = 0;
DECLARE @backupChecksumDefault BIT = 0;

DECLARE @updateBackupCompressionDefault BIT = 0;
DECLARE @backupCompressionDefault BIT = 0;

EXEC sp_configure 'show advanced options', 1;  
RECONFIGURE;

IF ISNULL(@vieOnly, 0) = 1
BEGIN
	EXEC sp_configure 'cost threshold for parallelism';
	EXEC sp_configure 'max degree of parallelism';
	EXEC sp_configure 'backup checksum default';
	EXEC sp_configure 'backup compression default';
	EXEC sp_configure 'max server memory (MB)'
	EXEC sp_configure 'optimize for ad hoc workloads'
	SELECT FORMAT(physical_memory_kb/1024, N'N0') + 'mb' AS MachinePhysicalMemory FROM sys.dm_os_sys_info
	SELECT  FORMAT(cntr_value/1024, N'N0') + 'mb' AS 'MaxMemory' FROM sys.dm_os_performance_counters WHERE counter_name LIKE '%Target Server%';
	SELECT FORMAT(cntr_value/1024, N'N0') + 'mb' AS 'CurrentUsedMemory'  FROM sys.dm_os_performance_counters WHERE counter_name LIKE '%Total Server%';
END

IF ISNULL(@updateConfig, 0) = 1
BEGIN
	IF ISNULL(@updateCostThresholdForParallelism, 0) = 1 BEGIN
		EXEC sp_configure 'cost threshold for parallelism', @costThresholdForParallelism;
		SELECT 'Updatedcost threshold for parallelism.'
	END
	IF ISNULL(@updateMaxdop, 0) = 1 BEGIN
		EXEC sp_configure 'max degree of parallelism', @maxdop;
		SELECT 'Updated max degree of parallelism.'
	END

	IF ISNULL(@updateBackupChecksumDefault, 0) = 1 BEGIN
		EXEC sp_configure 'backup checksum default', @backupChecksumDefault;
		SELECT 'Updated backup checksum default.'
	END

	IF ISNULL(@updateBackupCompressionDefault, 0) = 1 BEGIN
		EXEC sp_configure 'backup compression default', @backupCompressionDefault;
		SELECT 'Updated backup compression default.'
	END
END

EXEC sp_configure 'show advanced options', 0;  
RECONFIGURE