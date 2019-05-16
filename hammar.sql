DECLARE @dt DATETIME2 = DATEADD(minute, -120, GETDATE());
DECLARE @top INT = 5;
DECLARE @plainId INT = NULL;
DECLARE @queryId INT = NULL;

DECLARE @showUserConnections BIT = 1;
DECLARE @showSpidSesisonLoginInformation BIT = 0;

DECLARE @showSqlServerMemoryProfile BIT = 0;
DECLARE @showQueryStoreMemoryGrants BIT = 0;

DECLARE @showAllAzureLimits BIT = 0;
DECLARE @showAzureMemoryUsage BIT = 0;
DECLARE @showAzureCpu BIT = 0;
DECLARE @showAzureAvgDataIoPercent BIT = 0;
DECLARE @showAzureAvgLogWritePercent BIT = 0;
DECLARE @showAzureAvgLoginRatePercent BIT = 0;
DECLARE @showAzureAvgXtpStoragePercent BIT = 0;
DECLARE @showAzureAvgMaxWorkerPercent BIT = 0;
DECLARE @showAzureMaxSessionPercent BIT = 0;
DECLARE @showAureInstanceCpuPercent BIT = 0;
DECLARE @showAzureInstanceMemory BIT = 0;
DECLARE @showAzureOverPercent FLOAT = 40;

DECLARE @showDmCpuDuration BIT = 0;
DECLARE @showDmPhysicalReads BIT = 0;
DECLARE @showDmLogicallWrites BIT = 0;
DECLARE @showDmLogicallReads BIT = 0;
DECLARE @showDmStoreParallelism BIT = 0;
DECLARE @showDmGrants BIT = 1;
DECLARE @showDmSpills BIT = 0;
DECLARE @showDmClrDuration BIT = 0;
DECLARE @minTotalExecutionsOrderingAvg TINYINT = 5;

DECLARE @showQueryStoreDuration BIT = 0;
DECLARE @showQueryStoreTotalDuration BIT = 0;
DECLARE @showQueryStoreTotalExecutions BIT = 0;
DECLARE @showQueryStoreIo BIT = 0;
DECLARE @showQueryStoreCpu BIT = 0;
DECLARE @showQueryStoreMemory BIT = 0;
DECLARE @showQueryStoreParallelism BIT = 0;

DECLARE @showSpidSessionRuntimeStats BIT = 0;
DECLARE @showSpidRequestRuntimeStats BIT = 0;
DECLARE @showSpidRequestQuery BIT = 0;
DECLARE @showSpidRequestWaitStat BIT = 0;

DECLARE @showStats BIT = 0;
DECLARE @statFilterOnTable VARCHAR(100) = 'Delivery';


DECLARE @isAzure BIT = 0

IF SERVERPROPERTY('Edition') = N'SQL Azure' BEGIN
	SET @isAzure = 1
END

SELECT *,
N'https://docs.microsoft.com/en-us/sql/t-sql/statements/alter-database-transact-sql-compatibility-level' AS CompatibiltyList
INTO #TempDatabases
FROM sys.databases
DECLARE @prodctionMajorVersion FLOAT =  CAST(SERVERPROPERTY(N'ProductMajorVersion') AS FLOAT);
DECLARE @productMinorVersion FLOAT =    CAST(SERVERPROPERTY(N'ProductMinorVersion') AS FLOAT);
DECLARE @productUpdateLevel SQL_VARIANT =     SERVERPROPERTY(N'ProductUpdateLevel');
DECLARE @productUpdateReference SQL_VARIANT = SERVERPROPERTY(N'ProductUpdateReference');
DECLARE @compatibilityLevel TINYINT = (SELECT TOP 1 compatibility_level FROM #TempDatabases WHERE name =  DB_NAME());

CREATE TABLE #TempTraceFlags (Name INT, Status INT, Global INT, Session INT)
INSERT INTO #TempTraceFlags  exec('DBCC TRACESTATUS()');

--SELECT 
--@@version as PrettyPrintVersion,
--SERVERPROPERTY(N'ProductMajorVersion') AS ProductMajorVersion, 
--SERVERPROPERTY(N'ProductMinorVersion') AS ProductMinorVersion, 
--SERVERPROPERTY(N'ProductUpdateLevel') AS ProductUpdateLevel, 
--SERVERPROPERTY(N'ProductUpdateReference') AS ProductUpdateReference, 
 
--SERVERPROPERTY(N'ProductVersion') AS ProductVersion, 
--SERVERPROPERTY (N'productlevel') AS ProductLevel, 
--SERVERPROPERTY (N'Edition') AS Edition, 
--IIF(SERVERPROPERTY(N'IsClustered') = 0, N'Not Clusterd', N'Clustered') AS IsClustered,
--IIF(SERVERPROPERTY(N'IsIntegratedSecurityOnly') = 0, N'Both Windows Authentication and SQL Server Authentication', N'Integrated security (Windows Authentication)') AS IntegratedSecurity


IF 
	@showDmCpuDuration = 1 
	OR @showDmPhysicalReads = 1 
	OR @showDmLogicallWrites = 1 
	OR @showDmLogicallReads = 1 
	OR @showDmClrDuration = 1 
	OR @showDmStoreParallelism = 1 
	OR @showDmGrants = 1 
	OR @showDmSpills = 1
BEGIN

	SELECT *,
	total_grant_kb/execution_count AS avg_grant_kb,
	total_used_grant_kb/execution_count AS avg_used_grant_kb,
	total_ideal_grant_kb/execution_count AS avg_ideal_grant_kb,
	total_dop/execution_count AS avg_dop,
	total_worker_time/execution_count AS avg_worker_time,
	total_logical_writes/execution_count AS avg_logical_writes,
	total_logical_reads/execution_count AS avg_logical_reads,
	total_physical_reads/execution_count AS avg_physical_reads,
	total_clr_time/execution_count AS avg_clr_time,
	total_spills/execution_count AS avg_spills,
	total_rows/execution_count AS avg_rows
	INTO #TempDmQueryStats
	FROM sys.dm_exec_query_stats 

	
	IF @showDmSpills = 1 BEGIN

		SELECT TOP(@top)
		@@SPID AS SPID,
		FORMAT(qs.total_rows , N'###,###,###0') AS TotalRows,
		FORMAT(qs.avg_rows , N'###,###,###0') AS AvgRows,
		FORMAT(qs.last_rows , N'###,###,###0') AS LastRows,
		FORMAT(qs.min_rows , N'###,###,###0') AS MinRows,
		FORMAT(qs.max_rows , N'###,###,###0') AS MaxRows,
		FORMAT(LEN(t.text) , N'###,###,###0') AS SQLTextLength,
		qs.creation_time AS CompiledDateTime,
		qs.last_execution_time AS LastExecutionDateTime,
		FORMAT(qs.execution_count , N'###,###,###0') AS TotalExections,

		FORMAT(qs.total_spills, N'###,###,###0') AS TotalSpills,
		FORMAT(qs.avg_spills, N'###,###,###0') AS AvgSpills,
		FORMAT(qs.last_spills, N'###,###,###0') AS LastSpills,
		FORMAT(qs.min_spills, N'###,###,###0') AS MinSpills,
		FORMAT(qs.max_spills, N'###,###,###0') AS MaxSpills,

		OBJECT_NAME(qp.objectid) AS DatabaseObject,
		qs.plan_generation_num AS PlanGenerationNumber,
		CAST(t.text AS XML)
		FROM #TempDmQueryStats AS qs
		CROSS APPLY sys.dm_exec_sql_text(qs.sql_handle) AS t
		CROSS apply sys.dm_exec_query_plan (qs.plan_handle) AS qp
		WHERE @minTotalExecutionsOrderingAvg IS NULL 
		OR qs.execution_count >= @minTotalExecutionsOrderingAvg
		ORDER BY qs.avg_spills DESC;

	END


	IF @showDmGrants = 1 BEGIN

		SELECT TOP(@top)
		@@SPID AS SPID,
		FORMAT(qs.total_rows , N'###,###,###0') AS TotalRows,
		FORMAT(qs.avg_rows , N'###,###,###0') AS AvgRows,
		FORMAT(qs.last_rows , N'###,###,###0') AS LastRows,
		FORMAT(qs.min_rows , N'###,###,###0') AS MinRows,
		FORMAT(qs.max_rows , N'###,###,###0') AS MaxRows,
		FORMAT(LEN(t.text) , N'###,###,###0') AS SQLTextLength,
		qs.creation_time AS CompiledDateTime,
		qs.last_execution_time AS LastExecutionDateTime,
		FORMAT(qs.execution_count , N'###,###,###0') AS TotalExections,

		FORMAT(qs.total_grant_kb/1024, N'###,###,###0 mb') AS TotalGrants,
		FORMAT(qs.avg_grant_kb/1024, N'###,###,###0 mb') AS AvgGrants,
		FORMAT(qs.last_grant_kb/1024, N'###,###,###0 mb') AS LastGrants,
		FORMAT(qs.min_grant_kb/1024, N'###,###,###0 mb') AS MinGrants,
		FORMAT(qs.max_grant_kb/1024, N'###,###,###0 mb') AS MaxGrants,

		FORMAT(qs.total_used_grant_kb/1024, N'###,###,###0 mb') AS TotalUsedGrants,
		FORMAT(qs.avg_used_grant_kb/1024, N'###,###,###0 mb') AS AvgUsedGrants,
		FORMAT(qs.last_used_grant_kb/1024, N'###,###,###0 mb') AS LastUsedGrants,
		FORMAT(qs.min_used_grant_kb/1024, N'###,###,###0 mb') AS MinUsedGrants,
		FORMAT(qs.max_used_grant_kb/1024, N'###,###,###0 mb') AS MaxUsedGrants,

		FORMAT(qs.total_ideal_grant_kb/1024, N'###,###,###0 mb') AS TotalIdealGrants,
		FORMAT(qs.avg_ideal_grant_kb/1024, N'###,###,###0 mb') AS AvgIdealGrants,
		FORMAT(qs.last_ideal_grant_kb/1024, N'###,###,###0 mb') AS LastIdealGrants,
		FORMAT(qs.min_ideal_grant_kb/1024, N'###,###,###0 mb') AS MinIdealGrants,
		FORMAT(qs.max_ideal_grant_kb/1024, N'###,###,###0 mb') AS MaxIdealGrants,

		OBJECT_NAME(qp.objectid) AS DatabaseObject,
		qs.plan_generation_num AS PlanGenerationNumber,
		CAST(t.text AS XML)
		FROM #TempDmQueryStats AS qs
		CROSS APPLY sys.dm_exec_sql_text(qs.sql_handle) AS t
		CROSS apply sys.dm_exec_query_plan (qs.plan_handle) AS qp
		WHERE @minTotalExecutionsOrderingAvg IS NULL 
		OR qs.execution_count >= @minTotalExecutionsOrderingAvg
		ORDER BY qs.avg_grant_kb DESC;

	END

	IF @showDmStoreParallelism = 1 BEGIN

		SELECT TOP(@top)
		@@SPID AS SPID,
		FORMAT(qs.total_rows , N'###,###,###0') AS TotalRows,
		FORMAT(qs.avg_rows , N'###,###,###0') AS AvgRows,
		FORMAT(qs.last_rows , N'###,###,###0') AS LastRows,
		FORMAT(qs.min_rows , N'###,###,###0') AS MinRows,
		FORMAT(qs.max_rows , N'###,###,###0') AS MaxRows,
		FORMAT(LEN(t.text) , N'###,###,###0') AS SQLTextLength,
		qs.creation_time AS CompiledDateTime,
		qs.last_execution_time AS LastExecutionDateTime,
		FORMAT(qs.execution_count , N'###,###,###0') AS TotalExections,

		FORMAT(qs.total_dop , N'###,###,###0') AS TotalParallelismOrDop,
		FORMAT(qs.avg_dop , N'###,###,###0') AS AvgParallelismOrDop,
		FORMAT(qs.last_dop , N'###,###,###0') AS LastParallelismDop,
		FORMAT(qs.min_dop , N'###,###,###0') AS MinParallelismDop,
		FORMAT(qs.max_dop , N'###,###,###0') AS MaxParallelismDop,

		OBJECT_NAME(qp.objectid) AS DatabaseObject,
		qs.plan_generation_num AS PlanGenerationNumber,
		CAST(t.text AS XML)
		FROM #TempDmQueryStats AS qs
		CROSS APPLY sys.dm_exec_sql_text(qs.sql_handle) AS t
		CROSS apply sys.dm_exec_query_plan (qs.plan_handle) AS qp
		WHERE @minTotalExecutionsOrderingAvg IS NULL 
		OR qs.execution_count >= @minTotalExecutionsOrderingAvg
		ORDER BY qs.avg_dop DESC;

	END

	IF @showDmCpuDuration = 1 BEGIN

		SELECT TOP(@top)
		@@SPID AS SPID,
		FORMAT(qs.total_rows , N'###,###,###0') AS TotalRows,
		FORMAT(qs.avg_rows , N'###,###,###0') AS AvgRows,
		FORMAT(qs.last_rows , N'###,###,###0') AS LastRows,
		FORMAT(qs.min_rows , N'###,###,###0') AS MinRows,
		FORMAT(qs.max_rows , N'###,###,###0') AS MaxRows,
		FORMAT(LEN(t.text) , N'###,###,###0') AS SQLTextLength,
		qs.creation_time AS CompiledDateTime,
		qs.last_execution_time AS LastExecutionDateTime,
		FORMAT(qs.execution_count , N'###,###,###0') AS TotalExections,

		CONVERT(VARCHAR(10), (qs.total_worker_time/1000/86400000)) + 'd ' +
		CONVERT(VARCHAR(10), ((qs.total_worker_time/1000%86400000)/3600000)) + 'h '+
		CONVERT(VARCHAR(10), (((qs.total_worker_time/1000%86400000)%3600000)/60000)) + 'm '+
		CONVERT(varchar(10), ((((qs.total_worker_time/1000%86400000)%3600000)%60000)/1000)) + 's ' +
		CONVERT(VARCHAR(10), (((qs.total_worker_time/1000%86400000)%3600000)%1000)) + 'ms' AS TotalCpuDuration,

		CONVERT(VARCHAR(10), (qs.avg_worker_time/1000/86400000)) + 'd ' +
		CONVERT(VARCHAR(10), ((qs.avg_worker_time/1000%86400000)/3600000)) + 'h '+
		CONVERT(VARCHAR(10), (((qs.avg_worker_time/1000%86400000)%3600000)/60000)) + 'm '+
		CONVERT(varchar(10), ((((qs.avg_worker_time/1000%86400000)%3600000)%60000)/1000)) + 's ' +
		CONVERT(VARCHAR(10), (((qs.avg_worker_time/1000%86400000)%3600000)%1000)) + 'ms' AS AvgCpuDuration,

		CONVERT(VARCHAR(10), (qs.last_worker_time/1000/86400000)) + 'd ' +
		CONVERT(VARCHAR(10), ((qs.last_worker_time/1000%86400000)/3600000)) + 'h '+
		CONVERT(VARCHAR(10), (((qs.last_worker_time/1000%86400000)%3600000)/60000)) + 'm '+
		CONVERT(varchar(10), ((((qs.last_worker_time/1000%86400000)%3600000)%60000)/1000)) + 's ' +
		CONVERT(VARCHAR(10), (((qs.last_worker_time/1000%86400000)%3600000)%1000)) + 'ms' AS LastCpuDuration,

		CONVERT(VARCHAR(10), (qs.min_worker_time/1000/86400000)) + 'd ' +
		CONVERT(VARCHAR(10), ((qs.min_worker_time/1000%86400000)/3600000)) + 'h '+
		CONVERT(VARCHAR(10), (((qs.min_worker_time/1000%86400000)%3600000)/60000)) + 'm '+
		CONVERT(varchar(10), ((((qs.min_worker_time/1000%86400000)%3600000)%60000)/1000)) + 's ' +
		CONVERT(VARCHAR(10), (((qs.min_worker_time/1000%86400000)%3600000)%1000)) + 'ms' AS MinCpuDuration,

		CONVERT(VARCHAR(10), (qs.max_worker_time/1000/86400000)) + 'd ' +
		CONVERT(VARCHAR(10), ((qs.max_worker_time/1000%86400000)/3600000)) + 'h '+
		CONVERT(VARCHAR(10), (((qs.max_worker_time/1000%86400000)%3600000)/60000)) + 'm '+
		CONVERT(varchar(10), ((((qs.max_worker_time/1000%86400000)%3600000)%60000)/1000)) + 's ' +
		CONVERT(VARCHAR(10), (((qs.max_worker_time/1000%86400000)%3600000)%1000)) + 'ms' AS MaxCpuDuration,

		OBJECT_NAME(qp.objectid) AS DatabaseObject,
		qs.plan_generation_num AS PlanGenerationNumber,
		CAST(t.text AS XML)
		FROM #TempDmQueryStats AS qs
		CROSS APPLY sys.dm_exec_sql_text(qs.sql_handle) AS t
		CROSS apply sys.dm_exec_query_plan (qs.plan_handle) AS qp
		WHERE @minTotalExecutionsOrderingAvg IS NULL 
		OR qs.execution_count >= @minTotalExecutionsOrderingAvg
		ORDER BY qs.avg_worker_time DESC;

	END

	IF @showDmLogicallWrites = 1 BEGIN

		SELECT TOP(@top)
		@@SPID AS SPID,
		FORMAT(qs.total_rows , N'###,###,###0') AS TotalRows,
		FORMAT(qs.avg_rows , N'###,###,###0') AS AvgRows,
		FORMAT(qs.last_rows , N'###,###,###0') AS LastRows,
		FORMAT(qs.min_rows , N'###,###,###0') AS MinRows,
		FORMAT(qs.max_rows , N'###,###,###0') AS MaxRows,
		FORMAT(LEN(t.text) , N'###,###,###0') AS SQLTextLength,
		qs.creation_time AS CompiledDateTime,
		qs.last_execution_time AS LastExecutionDateTime,
		FORMAT(qs.execution_count , N'###,###,###0') AS TotalExections,

		FORMAT(qs.total_logical_writes , N'###,###,###0') AS TotalLogicalWrites,
		FORMAT(qs.avg_logical_writes , N'###,###,###0') AS AvgLogicalWrites,
		FORMAT(qs.last_logical_writes , N'###,###,###0') AS LastLogicalWrites,
		FORMAT(qs.min_logical_writes , N'###,###,###0') AS MinLogicalWrites,
		FORMAT(qs.max_logical_writes , N'###,###,###0') AS MaxLogicalWrites,

		OBJECT_NAME(qp.objectid) AS DatabaseObject,
		qs.plan_generation_num AS PlanGenerationNumber,
		CAST(t.text AS XML)
		FROM #TempDmQueryStats AS qs
		CROSS APPLY sys.dm_exec_sql_text(qs.sql_handle) AS t
		CROSS apply sys.dm_exec_query_plan (qs.plan_handle) AS qp
		WHERE @minTotalExecutionsOrderingAvg IS NULL 
		OR qs.execution_count >= @minTotalExecutionsOrderingAvg
		ORDER BY qs.avg_logical_writes DESC;

	END

	IF @showDmLogicallReads = 1 BEGIN

		SELECT TOP(@top)
		@@SPID AS SPID,
		FORMAT(qs.total_rows , N'###,###,###0') AS TotalRows,
		FORMAT(qs.avg_rows , N'###,###,###0') AS AvgRows,
		FORMAT(qs.last_rows , N'###,###,###0') AS LastRows,
		FORMAT(qs.min_rows , N'###,###,###0') AS MinRows,
		FORMAT(qs.max_rows , N'###,###,###0') AS MaxRows,
		FORMAT(LEN(t.text) , N'###,###,###0') AS SQLTextLength,
		qs.creation_time AS CompiledDateTime,
		qs.last_execution_time AS LastExecutionDateTime,
		FORMAT(qs.execution_count , N'###,###,###0') AS TotalExections,

		FORMAT(qs.total_logical_reads , N'###,###,###0') AS TotalLogicalReads,
		FORMAT(qs.avg_logical_reads , N'###,###,###0') AS TotalLogicalReads,
		FORMAT(qs.last_logical_reads , N'###,###,###0') AS LastLogicalReads,
		FORMAT(qs.min_logical_reads , N'###,###,###0') AS MinLogicalReads,
		FORMAT(qs.max_logical_reads , N'###,###,###0') AS MaxLogicalReads,

		OBJECT_NAME(qp.objectid) AS DatabaseObject,
		qs.plan_generation_num AS PlanGenerationNumber,
		CAST(t.text AS XML)
		FROM #TempDmQueryStats AS qs
		CROSS APPLY sys.dm_exec_sql_text(qs.sql_handle) AS t
		CROSS apply sys.dm_exec_query_plan (qs.plan_handle) AS qp
		WHERE @minTotalExecutionsOrderingAvg IS NULL 
		OR qs.execution_count >= @minTotalExecutionsOrderingAvg
		ORDER BY qs.avg_logical_reads DESC;

	END

	IF @showDmPhysicalReads = 1 BEGIN

		SELECT TOP(@top)
		@@SPID AS SPID,
		FORMAT(qs.total_rows , N'###,###,###0') AS TotalRows,
		FORMAT(qs.avg_rows , N'###,###,###0') AS AvgRows,
		FORMAT(qs.last_rows , N'###,###,###0') AS LastRows,
		FORMAT(qs.min_rows , N'###,###,###0') AS MinRows,
		FORMAT(qs.max_rows , N'###,###,###0') AS MaxRows,
		FORMAT(LEN(t.text) , N'###,###,###00') AS SQLTextLength,
		qs.creation_time AS CompiledDateTime,
		qs.last_execution_time AS LastExecutionDateTime,
		FORMAT(qs.execution_count , N'###,###,###00') AS TotalExections,

		FORMAT(qs.total_physical_reads , N'###,###,###0') AS TotaPhysicalReads,
		FORMAT(qs.avg_physical_reads , N'###,###,###0') AS AvgPhysicalReads,
		FORMAT(qs.last_physical_reads , N'###,###,###0') AS LastPhysicalReads,
		FORMAT(qs.min_physical_reads , N'###,###,###0') AS MinPhysicalReads,
		FORMAT(qs.max_physical_reads , N'###,###,###0') AS MaxPhysicalReads,

		OBJECT_NAME(qp.objectid) AS DatabaseObject,
		qs.plan_generation_num AS PlanGenerationNumber,
		CAST(t.text AS XML)
		FROM #TempDmQueryStats AS qs
		CROSS APPLY sys.dm_exec_sql_text(qs.sql_handle) AS t
		CROSS apply sys.dm_exec_query_plan (qs.plan_handle) AS qp
		WHERE @minTotalExecutionsOrderingAvg IS NULL 
		OR qs.execution_count >= @minTotalExecutionsOrderingAvg
		ORDER BY qs.avg_physical_reads DESC;

	END

	IF @showDmClrDuration = 1 BEGIN

		SELECT TOP(@top)
		@@SPID AS SPID,
		FORMAT(qs.total_rows , N'###,###,###0') AS TotalRows,
		FORMAT(qs.avg_rows , N'###,###,###0') AS AvgRows,
		FORMAT(qs.last_rows , N'###,###,###0') AS LastRows,
		FORMAT(qs.min_rows , N'###,###,###0') AS MinRows,
		FORMAT(qs.max_rows , N'###,###,###0') AS MaxRows,
		FORMAT(LEN(t.text) , N'###,###,###0') AS SQLTextLength,
		qs.creation_time AS CompiledDateTime,
		FORMAT(qs.execution_count , N'###,###,###0') AS TotalExections,
		qs.execution_count AS TotalExections,

		CONVERT(VARCHAR(10), (qs.total_clr_time/1000/86400000)) + 'd ' +
		CONVERT(VARCHAR(10), ((qs.total_clr_time/1000%86400000)/3600000)) + 'h '+
		CONVERT(VARCHAR(10), (((qs.total_clr_time/1000%86400000)%3600000)/60000)) + 'm '+
		CONVERT(varchar(10), ((((qs.total_clr_time/1000%86400000)%3600000)%60000)/1000)) + 's ' +
		CONVERT(VARCHAR(10), (((qs.total_clr_time/1000%86400000)%3600000)%1000)) + 'ms' AS TotalDuration,

		CONVERT(VARCHAR(10), (qs.avg_clr_time/1000/86400000)) + 'd ' +
		CONVERT(VARCHAR(10), ((qs.avg_clr_time/1000%86400000)/3600000)) + 'h '+
		CONVERT(VARCHAR(10), (((qs.avg_clr_time/1000%86400000)%3600000)/60000)) + 'm '+
		CONVERT(varchar(10), ((((qs.avg_clr_time/1000%86400000)%3600000)%60000)/1000)) + 's ' +
		CONVERT(VARCHAR(10), (((qs.avg_clr_time/1000%86400000)%3600000)%1000)) + 'ms' AS AvgDuration,

		CONVERT(VARCHAR(10), (qs.last_clr_time/1000/86400000)) + 'd ' +
		CONVERT(VARCHAR(10), ((qs.last_clr_time/1000%86400000)/3600000)) + 'h '+
		CONVERT(VARCHAR(10), (((qs.last_clr_time/1000%86400000)%3600000)/60000)) + 'm '+
		CONVERT(varchar(10), ((((qs.last_clr_time/1000%86400000)%3600000)%60000)/1000)) + 's ' +
		CONVERT(VARCHAR(10), (((qs.last_clr_time/1000%86400000)%3600000)%1000)) + 'ms' AS LastClrDuration,

		CONVERT(VARCHAR(10), (qs.min_clr_time/1000/86400000)) + 'd ' +
		CONVERT(VARCHAR(10), ((qs.min_clr_time/1000%86400000)/3600000)) + 'h '+
		CONVERT(VARCHAR(10), (((qs.min_clr_time/1000%86400000)%3600000)/60000)) + 'm '+
		CONVERT(varchar(10), ((((qs.min_clr_time/1000%86400000)%3600000)%60000)/1000)) + 's ' +
		CONVERT(VARCHAR(10), (((qs.min_clr_time/1000%86400000)%3600000)%1000)) + 'ms' AS MinClrDuration,

		CONVERT(VARCHAR(10), (qs.max_clr_time/1000/86400000)) + 'd ' +
		CONVERT(VARCHAR(10), ((qs.max_clr_time/1000%86400000)/3600000)) + 'h '+
		CONVERT(VARCHAR(10), (((qs.max_clr_time/1000%86400000)%3600000)/60000)) + 'm '+
		CONVERT(varchar(10), ((((qs.max_clr_time/1000%86400000)%3600000)%60000)/1000)) + 's ' +
		CONVERT(VARCHAR(10), (((qs.max_clr_time/1000%86400000)%3600000)%1000)) + 'ms' AS MaxClrDuration,

		OBJECT_NAME(qp.objectid) AS DatabaseObject,
		qs.plan_generation_num AS PlanGenerationNumber,
		CAST(t.text AS XML)
		FROM #TempDmQueryStats AS qs
		CROSS APPLY sys.dm_exec_sql_text(qs.sql_handle) AS t
		CROSS apply sys.dm_exec_query_plan (qs.plan_handle) AS qp
		WHERE @minTotalExecutionsOrderingAvg IS NULL 
		OR qs.execution_count >= @minTotalExecutionsOrderingAvg
		ORDER BY qs.avg_clr_time DESC;

	END

	DROP TABLE #TempDmQueryStats
END

If @showStats = 1 BEGIN

	DECLARE @dynamicAutoUpateTraceFlage BIT = (
	SELECT IIF(Name IS NULL, 0, 1) 
	FROM #TempTraceFlags 
	WHERE Name = '2371' 
	AND @prodctionMajorVersion >= 10.5
	)

	SELECT t.name As TableName, 
	sp.stats_id StatId, 
	s.name StatName, 
	sp.last_updated AS LastUpdated,
	sp.rows_sampled AS RowsSampled, 
	sp.modification_counter, 
	sp.rows,
	CONVERT(DECIMAL(10,2), IIF(@compatibilityLevel >= 130 OR @dynamicAutoUpateTraceFlage = 1, SQRT(1000 * sp.rows), IIF(sp.rows <= 500, 500, sp.rows * .20 + 500)) ) AS RowsNeedToUpdate, 
	CONVERT(DECIMAL(10,2), IIF(@compatibilityLevel >= 130 OR @dynamicAutoUpateTraceFlage = 1, SQRT(1000 * sp.rows) + sp.rows, IIF(sp.rows <= 500, 500, sp.rows * .20 + 500 + sp.rows)) ) AS NextIndexUpdate, 
	CONVERT(DECIMAL(10,2), IIF(@compatibilityLevel >= 130 OR @dynamicAutoUpateTraceFlage = 1, (SQRT(1000 * sp.rows) + sp.rows) - sp.modification_counter, IIF(sp.rows <= 500, 500 - sp.modification_counter, (sp.rows * .20 + 500 + sp.rows) - sp.modification_counter)) ) AS RowsLeftToUpdate, 
	IIF(@compatibilityLevel >= 130 OR @dynamicAutoUpateTraceFlage = 1, STR(SQRT(1000 * sp.rows) / (SQRT(1000 * sp.rows)  + sp.rows) * 100, 5, 2) + N'%', IIF(sp.rows <= 500, N'<= 500 No %', '20% + 500')) AS PecentForNextUpdate,
	sp.persisted_sample_percent AS PersistedSamplePercent, 
	sp.steps AS Steps, 
	unfiltered_rows AS UnfilteredRows, 
	filter_definition AS FilterDefinition, 
	s.auto_created AS AutoCreated, 
	s.is_temporary AS IsTemporary, 
	s.no_recompute AS NoRecompute, 
	s.has_filter AS HasFilter, 
	s.is_incremental AS IsIncremental,
	N'https://docs.microsoft.com/en-us/sql/relational-databases/statistics/statistics' AS ViewAboutStatistics
	FROM sys.stats AS s   
	CROSS APPLY sys.dm_db_stats_properties(s.object_id, s.stats_id) AS sp 
	JOIN sys.tables t ON t.object_id = s.object_id
    WHERE (@statFilterOnTable IS NULL OR t.name = @statFilterOnTable)
    ORDER BY TableName

END 

IF @isAzure = 1 AND
    (
		@showAllAzureLimits = 1
        OR @showAzureMemoryUsage = 1
        OR @showAzureCpu = 1
        OR @showAzureAvgDataIoPercent = 1
        OR @showAzureAvgLogWritePercent = 1
        OR @showAzureAvgLoginRatePercent = 1
        OR @showAzureAvgXtpStoragePercent = 1
        OR @showAzureAvgMaxWorkerPercent = 1
        OR @showAzureMaxSessionPercent = 1
        OR @showAureInstanceCpuPercent = 1
        OR @showAzureInstanceMemory = 1
    )
BEGIN
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
        AND avg_memory_usage_percent > @showAzureOverPercent
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
        AND avg_cpu_percent > @showAzureOverPercent
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
        AND (@showAllAzureLimits = 1 OR @showAzureAvgDataIoPercent = 1)
        AND avg_data_io_percent > @showAzureOverPercent
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
        AND (@showAllAzureLimits = 1 OR @showAzureAvgLogWritePercent = 1)
        AND avg_log_write_percent > @showAzureOverPercent
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
        AND (@showAllAzureLimits = 1 OR @showAzureAvgLoginRatePercent = 1)
        AND avg_login_rate_percent > @showAzureOverPercent
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
        AND (@showAllAzureLimits = 1 OR @showAzureAvgXtpStoragePercent = 1)
        AND xtp_storage_percent > @showAzureOverPercent
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
        AND (@showAllAzureLimits = 1 OR @showAzureAvgMaxWorkerPercent = 1)
        AND max_worker_percent > @showAzureOverPercent
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
        AND (@showAllAzureLimits = 1 OR @showAzureMaxSessionPercent = 1)
        AND max_session_percent > @showAzureOverPercent
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
        AND (@showAllAzureLimits = 1 OR @showAureInstanceCpuPercent = 1)
        AND avg_instance_cpu_percent > @showAzureOverPercent
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
        AND avg_instance_memory_percent > @showAzureOverPercent
    ) AS max_log_write ON max_log_write.MaxAvgPercent = s.avg_instance_memory_percent
    WHERE end_time >= @dt
    AND MaxAvgPercent <> 0.00
    ORDER BY DataPointLimitType, EndDteTime DESC

END
ELSE IF @isAzure = 1 AND
    (
        @showAllAzureLimits = 1
        OR @showAzureMemoryUsage = 1
        OR @showAzureCpu = 1
        OR @showAzureAvgDataIoPercent = 1
        OR @showAzureAvgLogWritePercent = 1
        OR @showAzureAvgLoginRatePercent = 1
        OR @showAzureAvgXtpStoragePercent = 1
        OR @showAzureAvgMaxWorkerPercent = 1
        OR @showAzureMaxSessionPercent = 1
        OR @showAureInstanceCpuPercent = 1
        OR @showAzureInstanceMemory = 1
    )
BEGIN

    SELECT 'Must be Azure SQL Database to use DTU or CPU Limits'

END


-- select * from sys.dm_db_resource_stats

IF @showQueryStoreMemoryGrants= 1 BEGIN

	SELECT 
	s.login_name AS LoginName,
	s.nt_user_name AS NtUserName,
	s.nt_domain AS NtDomain,
	s.program_name AS ProgramName,
	s.[status] AS Status,
	query_cost AS QueryCost,
	is_next_candidate AS IsNextCanidate,
	grant_time As GrantTime,
	CAST(wait_time_ms AS VARCHAR(50)) + ' ms' AS  WaitTime,
	wait_order AS WaitOrder,
	rp.name AS ResourcePoolName, 
	request_time AS RequestTime,
	CAST(timeout_sec AS VARCHAR(50)) + ' secs' AS MemoryGrantRequestTimeout,
	CAST(mg.requested_memory_kb/1024 AS VARCHAR(50)) + ' mb' AS RequestedMemory,
	CAST(mg.granted_memory_kb/1024 AS VARCHAR(50)) + ' mb' AS GrantedMemory,
	CAST(mg.ideal_memory_kb/1024 AS VARCHAR(50)) + ' mb' AS IdealMemory,
	CAST(mg.required_memory_kb/1024 AS VARCHAR(50)) + ' mb' AS MinRequiredMemory,
	CAST(mg.used_memory_kb/1024 AS VARCHAR(50)) + ' mb' AS PhysicalUsedMemoryUsedAtMoment,
	CAST(mg.max_used_memory_kb/1024 AS VARCHAR(50)) + ' mb' AS MaxPhysicalUsedMemoryUpToMoment,
	t.text AS SqlText,
	CAST(qp.query_plan AS XML) AS ExecutionPlan
	FROM sys.dm_exec_query_memory_grants mg
	JOIN sys.dm_exec_sessions s ON s.session_id = mg.session_id
	LEFT JOIN sys.dm_exec_query_resource_semaphores rs ON rs.resource_semaphore_id = mg.resource_semaphore_id AND rs.pool_id = mg.pool_id
	LEFT JOIN sys.dm_resource_governor_resource_pools rp ON rp.pool_id = rs.pool_id
	CROSS APPLY sys.dm_exec_sql_text(sql_handle) t
	CROSS APPLY sys.dm_exec_query_plan(mg.plan_handle) qp

END

IF @showSqlServerMemoryProfile = 1 BEGIN

	DECLARE @totalMemoryInMb INT;
	DECLARE @targetMemoryInMb INT;
	DECLARE @memoryPressurePercent NVARCHAR(40);

	-- Total Server Memory/ Target Server Memory ratio should be close to 1 for best performance
	-- If there is a large gap between total and targer, there may be memory presssure.

	-- Current memory SQL Server has allocated for itself.
	SELECT TOP 1 @totalMemoryInMb = cntr_value/1024  
	FROM sys.dm_os_performance_counters 
	WHERE counter_name = N'Total Server Memory (KB)' 

	-- How much memory SQL Server needs to function normally. 
	SELECT TOP 1 @targetMemoryInMb = cntr_value/1024  
	FROM sys.dm_os_performance_counters 
	WHERE counter_name = N'Target Server Memory (KB)'; 
                                              
	SET @memoryPressurePercent = CAST(CAST(CAST(@totalMemoryInMb AS FLOAT) / CAST(@targetMemoryInMb AS FLOAT) * 100 AS INT) AS NVARCHAR(3)) + N'%';

	IF @isAzure = 0 BEGIN

		SELECT
		CAST(@totalMemoryInMb AS NVARCHAR(50)) + N' mb' AS TotalMemory,
		CAST(@targetMemoryInMb AS NVARCHAR(50)) + N' mb' AS TargetMemory,
		@memoryPressurePercent AS N'MemoryPressure(Higher is better)',
		CAST(memory_utilization_percentage AS NVARCHAR(3)) + N'%' MemoryUtilizationPercentage,
		process_physical_memory_low AS ProcessPhysicalMemoryLow,
		process_virtual_memory_low AS ProcessVirtualMemoryLow,
		IIF(locked_page_allocations_kb = 0, N'0', FORMAT(locked_page_allocations_kb/1024, N'###,###,###0')) + N' mb' AS LockedPageAllocations,
		FORMAT(physical_memory_in_use_kb/1024,'###,###,###0') + N' mb' AS PhysicalMemoryInUse,
		FORMAT(available_commit_limit_kb/1024, N'###,###,###0') + N' mb' As AvailableCommitLimit,
		FORMAT(virtual_address_space_available_kb/1024/1024, N'###,###,###0') + N' gb' AS VirtualAddressAvailable,
		FORMAT(virtual_address_space_reserved_kb/1024, N'###,###,###0') + N' mb' AS VirtualAddressSpaceReserved,
		FORMAT(virtual_address_space_committed_kb/1024, N'###,###,###0') + N' mb' AS VirtualAddressCommitted,
		FORMAT(total_virtual_address_space_kb/1024/1024, N'###,###,###0') + N' gb' AS TotalVirtualAddressSpace,
		IIF(large_page_allocations_kb = 0, N'0', FORMAT(large_page_allocations_kb/1024, N'###,###,###0')) + N' mb' AS LargePageAllocation,
		page_fault_count AS PageFaultCount
		from  sys.dm_os_process_memory;

	END
	ELSE BEGIN

		SELECT
		CAST(@totalMemoryInMb AS NVARCHAR(50)) + N' mb' AS TotalMemory,
		CAST(@targetMemoryInMb AS NVARCHAR(50)) + N' mb' AS TargetMemory,
		@memoryPressurePercent AS N'MemoryPressure(Higher is better)'

	END

END

IF @showSpidSesisonLoginInformation = 1 
	OR @showSpidSessionRuntimeStats = 1 
	OR @showSpidRequestRuntimeStats = 1 
	OR @showSpidRequestQuery = 1 
	OR @showSpidRequestWaitStat = 1 
	OR @showUserConnections = 1 BEGIN

    SELECT 
	s.session_id AS SPID,
	c.connect_time AS ConnectionConnectTime, 
	c.protocol_type As ConnectionProtocolType, 
	c.net_transport AS ConnectionNetTransport, 
	c.client_net_address AS ConnectionClientNetAddress, 
	c.client_tcp_port AS ConnectionTcpPort,
    login_name AS SessionLoginName,
    s.original_login_name AS SessionOriginalLoginName,
    nt_user_name AS SessionNtUserName,
    nt_domain AS SessionNtDomain,
    login_time AS SessionLoginTime,
	s.program_name AS ProgramName,
    s.client_version AS SessionClientVersion,
    s.client_interface_name AS SessionClient,
    s.status AS SessionStatus,
    s.cpu_time AS SessionCpuTime,
    s.memory_usage AS SessionMemoryUsage8KBPages,
    s.total_elapsed_time AS SessionTotalElapedTime,
    s.total_scheduled_time As SessionTotalTimeScheduledForExection,
    s.last_request_start_time AS SessionRequestedStartTime,
    s.last_request_end_time AS SessionRequestedEndTime,
    s.reads AS SessionReadsPerformed,
    s.writes AS SessionWritesPerformed,
    s.logical_reads AS SessionLogicalReads,
    s.is_user_process AS SessionIsUserProcess,
    s.text_size,
    CASE
	 WHEN s.transaction_isolation_level = 0 THEN N'Unspecified'
	 WHEN s.transaction_isolation_level = 1 THEN N'Read Uncomitted'
	 WHEN s.transaction_isolation_level = 2 THEN N'Read Committed'
	 WHEN s.transaction_isolation_level = 5 THEN N'Repeatable'
	 WHEN s.transaction_isolation_level = 4 THEN N'Serializable'
	 WHEN s.transaction_isolation_level = 5 THEN N'Snapshot'
	 ELSE N'View here https://docs.microsoft.com/en-us/sql/relational-databases/system-dynamic-management-views/sys-dm-exec-sessions-transact-sql?view=sql-server-2017 to find out'
	END As SessionTransactionIsolationLevel,
    s.lock_timeout AS SessionLockTimeout,
    s.deadlock_priority AS SessionDeadlockPriority,
    s.row_count AS SessionRowCount,
    s.prev_error AS SessionPreviousError,
    s.last_successful_logon AS SessionLastSuccessfulLogon,
    s.last_unsuccessful_logon AS SessionLastUnSuccessfulLogon,
    DB_NAME(s.database_id) AS SessionDatabase,
    s.open_transaction_count AS SessionOpenTransactionCount,
    r.start_time As RequestStartTime,
    r.status As RequestStatus,
    r.command As RequestCommand,
    DB_NAME(r.database_id) AS RequestDatabase,
    r.blocking_session_id AS RequestBlockingSessionId,
    r.wait_type AS RequestWaitType,
    r.wait_time AS RequestWaitTime,
    r.last_wait_type AS RequestLastWaitType,
    r.wait_resource AS RequestWaitResource,
    r.sql_handle AS RequestSqlHandle,
    r.statement_start_offset AS RequestStatementStartOffset,
    r.statement_end_offset AS RequestStatementEndOffset,
    r.plan_handle AS RequestPlanHandle,
    r.user_id AS RequestUserId,
    r.connection_id AS RequestConnectionId,
    r.open_transaction_count AS RequestOpenTransactionCount,
    transaction_id AS RequestTransactionId,
    r.cpu_time AS RequestCpuTime,
    r.total_elapsed_time AS RequestTotalElapedTime,
    r.scheduler_id AS RequestSchedulerThatIsSchedulingTheRequest,
    r.reads AS RequestReads,
    r.writes AS RequestWrites,
    r.logical_reads AS RequestLogicalReads,
    CASE
	 WHEN r.transaction_isolation_level = 0 THEN N'Unspecified'
	 WHEN r.transaction_isolation_level = 1 THEN N'Read Uncomitted'
	 WHEN r.transaction_isolation_level = 2 THEN N'Read Committed'
	 WHEN r.transaction_isolation_level = 5 THEN N'Repeatable'
	 WHEN r.transaction_isolation_level = 4 THEN N'Serializable'
	 WHEN r.transaction_isolation_level = 5 THEN N'Snapshot'
	 ELSE N'View here https://docs.microsoft.com/en-us/sql/relational-databases/system-dynamic-management-views/sys-dm-exec-sessions-transact-sql?view=sql-server-2017 to find out'
	END As RequestTransactionIsolationLevel,
    r.lock_timeout AS RequestLockTimeout,
    r.deadlock_priority AS RequestDeadlockPriority,
    r.row_count AS RequestRowCount,
    r.prev_error AS RequestPreviousError,
    r.nest_level AS RequestNestLevel,
    r.granted_query_memory AS RequestQueryMemoryGrant,
    r.dop AS RequestDegreeOfParallelismForQuery,
    r.parallel_worker_count AS RequestParallelWorkerCount,
	t.text AS SqlText,
	CAST(qp.query_plan AS XML) AS ExecutionPlan
    INTO #TempSessionsRequestAndConnections
    FROM sys.dm_exec_sessions s
    JOIN sys.dm_exec_requests r on r.session_id = s.session_id
	JOIN sys.dm_exec_connections c on c.session_id = s.session_id
	CROSS APPLY sys.dm_exec_sql_text(r.sql_handle) AS t
	CROSS APPLY sys.dm_exec_query_plan(r.plan_handle) AS qp

	DECLARE @TempMemory TABLE
	(
		TotalMemoryInMb INT,
		TargetMemoryInMb INT,
		MemoryPressurePrecent NVARCHAR(5)
	)

	INSERT INTO @TempMemory(TotalMemoryInMb, TargetMemoryInMb, MemoryPressurePrecent) VALUES(NULL, NULL, NULL);

	-- Total Server Memory/ Target Server Memory ratio should be close to 1 for best performance
	-- If there is a large gap between total and targer, there may be memory presssure.

	-- Current memory SQL Server has allocated for itself.
	UPDATE @TempMemory 
	SET TotalMemoryInMb = (SELECT TOP 1 cntr_value/1024  
					  FROM sys.dm_os_performance_counters 
					  WHERE counter_name = N'Total Server Memory (KB)')

	-- How much memory SQL Server needs to function normally. 
	UPDATE @TempMemory 
	SET TargetMemoryInMb = (SELECT TOP 1 cntr_value/1024  
					  FROM sys.dm_os_performance_counters 
					  WHERE counter_name = N'Target Server Memory (KB)'); 

	UPDATE @TempMemory SET MemoryPressurePrecent = (SELECT TOP 1 CAST(CAST(CAST(TotalMemoryInMb AS FLOAT) / CAST(TargetMemoryInMb AS FLOAT) * 100 AS INT) AS NVARCHAR(3)) + N'%'
												   FROM @TempMemory);

    IF @showSpidSesisonLoginInformation = 1 OR @showUserConnections = 1 BEGIN

        -- select scheduler_id, cpu_id, status, is_online 
        -- from sys.dm_os_schedulers 
        -- where status = 'VISIBLE ONLINE'

        -- select * from sysprocesses
        -- -- where status = 'runnable' --comment this out
        -- order by CPU
        -- desc


        SELECT 
		SPID,
		ConnectionConnectTime, 
		ConnectionProtocolType, 
		ConnectionNetTransport, 
		ConnectionClientNetAddress, 
		ConnectionTcpPort,
        SessionDatabase,
        SessionLoginName
		SessionNtUserName,
        SessionNtDomain,
		SessionLoginTime,
        SessionClient,
        SessionClientVersion,
        SessionIsUserProcess,
        SessionStatus,
        CAST(SessionTotalElapedTime AS NVARCHAR(50)) + ' ms' AS SessionTotalElapedTime,
        SessionRequestedStartTime,
        SessionRequestedEndTime,
        SessionLastSuccessfulLogon,
        SessionLastUnSuccessfulLogon
        FROM #TempSessionsRequestAndConnections
        WHERE @showUserConnections = 1 OR SPID = @@SPID

    END

    IF @showSpidSessionRuntimeStats = 1 BEGIN

        SELECT
        SPID,
        SessionDatabase,
        SessionLoginName,
        SessionStatus,
        SessionCpuTime,
        SessionMemoryUsage8KBPages,
        SessionReadsPerformed,
        SessionWritesPerformed,
        SessionLogicalReads,
        SessionTransactionIsolationLevel,
        SessionLockTimeout
		SessionDeadlockPriority,
        SessionRowCount,
        SessionPreviousError
        FROM #TempSessionsRequestAndConnections
        WHERE SPID = @@SPID

    END

    IF @showSpidRequestRuntimeStats = 1 BEGIN

        SELECT
        SPID,
        RequestDatabase,
        RequestStartTime,
        RequestStatus,
        RequestOpenTransactionCount AS N'Open Trans Count',
        RequestTransactionId,
        RequestCpuTime,
        RequestTotalElapedTime,
        RequestReads,
        RequestWrites,
        RequestLogicalReads,
        RequestTransactionIsolationLevel,
        RequestLockTimeout,
        RequestDeadlockPriority,
        RequestRowCount,
        RequestPreviousError,
        RequestNestLevel,
        RequestParallelWorkerCount
        FROM #TempSessionsRequestAndConnections
        WHERE SPID = @@SPID

    END

    IF @showSpidRequestWaitStat = 1 BEGIN

        SELECT
        SPID,
        SessionDatabase,
        RequestCommand,
        RequestBlockingSessionId,
        RequestWaitType,
        RequestWaitTime,
        RequestLastWaitType,
        RequestWaitResource
        FROM #TempSessionsRequestAndConnections
        WHERE SPID = @@SPID

    END

    IF @showSpidRequestQuery = 1 BEGIN

        SELECT
        SPID,
        SessionDatabase,
        RequestCommand,
        sqlText.text As SqlText,
        substring
		(REPLACE
		(REPLACE
			(SUBSTRING
			(sqlText.text
			, (r.RequestStatementStartOffset/2) + 1
			, (
				(CASE RequestStatementEndOffset
					WHEN -1
					THEN DATALENGTH(sqlText.text)  
					ELSE r.RequestStatementEndOffset
					END
					- r.RequestStatementStartOffset)/2) + 1)
		, CHAR(10), N' N'), CHAR(13), N' N'), 1, 512)  AS N'Currently Executing',
        RequestQueryMemoryGrant,
        RequestCpuTime,
        RequestLogicalReads,
        RequestRowCount,
        RequestPreviousError,
        RequestDegreeOfParallelismForQuery,
        RequestStatementStartOffset,
        RequestStatementEndOffset,
        CAST(planHandle.query_plan AS XML) AS N'Execution Plan' 
        FROM #TempSessionsRequestAndConnections AS r
		CROSS APPLY sys.dm_exec_sql_text(r.RequestSqlHandle) AS sqlText
		CROSS APPLY sys.dm_exec_query_plan(r.RequestPlanHandle) AS planHandle
        WHERE SPID = @@SPID

    END

    DROP TABLE #TempSessionsRequestAndConnections
END

IF @showQueryStoreDuration = 1 OR @showQueryStoreCpu = 1 OR @showQueryStoreIo = 1 OR @showQueryStoreMemory = 1 OR @showQueryStoreParallelism = 1 OR @showQueryStoreTotalDuration = 1 OR @showQueryStoreTotalExecutions = 1 BEGIN

    SELECT rs.*
    INTO #tempQueryStoreRuntimeStats
    FROM sys.query_store_runtime_stats rs
    INNER JOIN sys.query_store_runtime_stats_interval i on rs.runtime_stats_interval_id = i.runtime_stats_interval_id
    WHERE end_time >= @dt

    SELECT
    @@SPID AS SPID,
    qsp.plan_id,
    qsq.query_id,
    qsq.object_id,
    OBJECT_NAME(qsq.object_id) AS N'Database Object',
    ca_aggregate_runtime_stats.FirstExecutionTime,
    ca_aggregate_runtime_stats.LastExecutionTime,
    ca_runtime_executions.TotalExections AS TotalExections,
    FORMAT(ca_runtime_executions.TotalExections, N'###,###,###0') AS TotalExectionsAsString,
    ca_runtime_executions.TotalDuration AS TotalDuration,
    FORMAT(ca_runtime_executions.TotalDuration, N'###,###,###0') + N' ms' AS TotalDurationString,

	CONVERT(VARCHAR(10), (ca_runtime_executions.TotalDuration/1000/86400000)) + 'd ' +
	CONVERT(VARCHAR(10), ((ca_runtime_executions.TotalDuration/1000%86400000)/3600000)) + 'h '+
	CONVERT(VARCHAR(10), (((ca_runtime_executions.TotalDuration/1000%86400000)%3600000)/60000)) + 'm '+
	CONVERT(varchar(10), ((((ca_runtime_executions.TotalDuration/1000%86400000)%3600000)%60000)/1000)) + 's ' +
	CONVERT(VARCHAR(10), (((ca_runtime_executions.TotalDuration/1000%86400000)%3600000)%1000)) + 'ms' AS TotalDurationInFormatAsString,

    ca_aggregate_runtime_stats.AvgDuration AS AvgDuration,
    CONVERT(VARCHAR(100), CAST(ca_aggregate_runtime_stats.AvgDuration AS FLOAT) / 1000) + N' ms' AS AvgDurationAsString,
    ca_aggregate_runtime_stats.LastDuration AS LastDuration,
    CONVERT(VARCHAR(100), CAST(ca_aggregate_runtime_stats.LastDuration AS FLOAT) / 1000) + N' ms' AS LastDurationAsString,
    ca_aggregate_runtime_stats.MinDuration AS MinDuration,
    CONVERT(VARCHAR(100), CAST(ca_aggregate_runtime_stats.MinDuration AS FLOAT) / 1000) + N' ms' AS MinDurationAsString,
    ca_aggregate_runtime_stats.MaxDuration AS MaxDuration,
    CONVERT(VARCHAR(100), CAST(ca_aggregate_runtime_stats.MaxDuration AS FLOAT) / 1000) + N' ms' AS MaxDurationAsString,
    LEN(qsqt.query_sql_text) AS SQLTextLength,
    qsqt.query_sql_text,
    ca_queries_for_plan.total_queries_for_plan AS N'Queries For Plan',
    ca_aggregate_runtime_stats.AvgRowCount,
    ca_aggregate_runtime_stats.LastRowCount,
    ca_aggregate_runtime_stats.MaxRowCount,
    ca_aggregate_runtime_stats.MinRowCount,
    ca_aggregate_runtime_stats.AvgCpuTime AS AvgCpuTime,
    CONVERT(VARCHAR(100), CAST(ca_aggregate_runtime_stats.AvgCpuTime AS FLOAT) / 1000) + N' ms' AS AvgCpuTimeAsString,
    ca_aggregate_runtime_stats.LastCpuTime AS LastCpuTime,
    CONVERT(VARCHAR(100), CAST(ca_aggregate_runtime_stats.LastCpuTime AS FLOAT) / 1000) + N' ms' AS LastCpuTimeAsString,
    ca_aggregate_runtime_stats.MinCpuTime AS MinCpuTime,
    CONVERT(VARCHAR(100), CAST(ca_aggregate_runtime_stats.MinCpuTime AS FLOAT) / 1000) + N' ms' AS MinCpuTimeAsString,
    ca_aggregate_runtime_stats.MaxCpuTime AS MaxCpuTime,
    CONVERT(VARCHAR(100), CAST(ca_aggregate_runtime_stats.MaxCpuTime AS FLOAT) / 1000) + N' ms' AS MaxCpuTimeAsString,
    ca_aggregate_runtime_stats.AvgMaxUsedMemory * 0.001 AS AvgMemoryInMegabytes,
    ca_aggregate_runtime_stats.LastMaxUsedMemory * 0.001 AS LastMemoryInMegabytes,
    ca_aggregate_runtime_stats.MinMaxUsedMemory * 0.001 AS MinMemoryInMegabytes,
    ca_aggregate_runtime_stats.MaxMaxUsedMemory * 0.001 AS MaxMemoryInMegabytes,
    ca_aggregate_runtime_stats.AvgDop AS AvgDegreeOfParallelism,
    ca_aggregate_runtime_stats.LastDop AS LastDegreeOfParallelism,
    ca_aggregate_runtime_stats.MinDop AS MinDegreeOfParallelism,
    ca_aggregate_runtime_stats.MaxDop AS MaxDegreeOfParallelism,
    ca_aggregate_runtime_stats.AvgLogicalIoReads,
    ca_aggregate_runtime_stats.LastLogicalIoReads,
    ca_aggregate_runtime_stats.MinLogicalIoReads,
    ca_aggregate_runtime_stats.MaxLogicalIoReads,
    ca_aggregate_runtime_stats.AvgLogicalIoWrites,
    ca_aggregate_runtime_stats.LastLogicalIoWrites,
    ca_aggregate_runtime_stats.MinLogicalIoWrites,
    ca_aggregate_runtime_stats.MaxLogicalIoWrites,
    ca_aggregate_runtime_stats.AvgPhysicalIoReads,
    ca_aggregate_runtime_stats.LastPhysicalIoReads,
    ca_aggregate_runtime_stats.MinPhysicalIoReads,
    ca_aggregate_runtime_stats.MaxPhysicalIoReads,
    ca_aggregate_runtime_stats.AvgNumPhysicalIoReads,
    ca_aggregate_runtime_stats.LastNumPhysicalIoReads,
    ca_aggregate_runtime_stats.MinNumPhysicalIoReads,
    ca_aggregate_runtime_stats.MaxNumPhysicalIoReads,
    CAST(qsp.query_plan AS XML) AS N'Execution Plan'
    INTO #QueryStoreData
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
        FROM #tempQueryStoreRuntimeStats qrs (NOLOCK)
        WHERE qrs.plan_id = qsp.plan_id
        GROUP BY qrs.plan_id
	) ca_aggregate_runtime_stats
	CROSS APPLY
	(
		SELECT CONVERT(int, SUM(rs.avg_duration))*0.001 AS TotalDuration,
        SUM(rs.count_executions) AS TotalExections
        FROM #tempQueryStoreRuntimeStats rs (NOLOCK)
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
    AND (@plainId IS NULL OR qsp.plan_id = @plainId)
    AND (@queryId IS NULL OR qsp.query_id = @queryId)

    DROP TABLE #tempQueryStoreRuntimeStats;

    IF @showQueryStoreDuration = 1 BEGIN

        SELECT TOP(@top)
        SPID,
        plan_id,
        query_id,
        TotalExections,
        SQLTextLength,
        AvgDurationAsString,
        LastDurationAsString,
        MinDurationAsString,
        MaxDurationAsString,
        [Database Object],
        object_id,
        FirstExecutionTime,
        LastExecutionTime,
        query_sql_text,
        [Queries For Plan],
        [Execution Plan]
        FROM #QueryStoreData
        ORDER BY AvgDuration DESC

    END

    IF @showQueryStoreTotalDuration = 1 BEGIN

        SELECT TOP(@top)
        SPID,
        plan_id,
        query_id,
        TotalExections,
        SQLTextLength,
        TotalDuration,
        TotalDurationString,
        TotalDurationInFormatAsString,
        [Database Object],
        object_id,
        FirstExecutionTime,
        LastExecutionTime,
        query_sql_text,
        [Queries For Plan],
        [Execution Plan]
        FROM #QueryStoreData
        ORDER BY TotalDuration DESC

    END

    IF @showQueryStoreTotalExecutions = 1 BEGIN

        SELECT TOP(@top)
        SPID,
        plan_id,
        query_id,
        TotalExections,
        TotalExectionsAsString,
        SQLTextLength,
        [Database Object],
        object_id,
        FirstExecutionTime,
        LastExecutionTime,
        query_sql_text,
        [Queries For Plan],
        [Execution Plan]
        FROM #QueryStoreData
        ORDER BY TotalExections DESC

    END


    IF @showQueryStoreCpu = 1 BEGIN

        SELECT TOP(@top)
        SPID,
        plan_id,
        query_id,
        TotalExections,
        SQLTextLength,
        AvgCpuTimeAsString,
        LastCpuTimeAsString,
        MinCpuTimeAsString,
        MaxCpuTimeAsString,
        [Database Object],
        object_id,
        FirstExecutionTime,
        LastExecutionTime,
        query_sql_text,
        [Queries For Plan],
        [Execution Plan]
        FROM #QueryStoreData
        ORDER BY AvgCpuTime DESC

    END

    IF @showQueryStoreMemory = 1 BEGIN

        SELECT TOP(@top)
        SPID,
        plan_id,
        query_id,
        TotalExections,
        SQLTextLength,
        AvgMemoryInMegabytes,
        LastMemoryInMegabytes,
        MinMemoryInMegabytes,
        MaxMemoryInMegabytes,
        [Database Object],
        object_id,
        FirstExecutionTime,
        LastExecutionTime,
        query_sql_text,
        [Queries For Plan],
        [Execution Plan]
        FROM #QueryStoreData
        ORDER BY AvgMemoryInMegabytes DESC

    END

    IF @showQueryStoreParallelism = 1 BEGIN

        SELECT TOP(@top)
        SPID,
        plan_id,
        query_id,
        TotalExections,
        SQLTextLength,
        AvgDegreeOfParallelism,
        LastDegreeOfParallelism,
        MinDegreeOfParallelism,
        MaxDegreeOfParallelism,
        [Database Object],
        object_id,
        FirstExecutionTime,
        LastExecutionTime,
        query_sql_text,
        [Queries For Plan],
        [Execution Plan]
        FROM #QueryStoreData
        ORDER BY AvgDegreeOfParallelism DESC

    END

    IF @showQueryStoreIo = 1 BEGIN

        SELECT TOP(@top)
        SPID,
        plan_id,
        query_id,
        TotalExections,
        SQLTextLength,
        AvgLogicalIoReads,
        LastLogicalIoReads,
        MinLogicalIoReads,
        MaxLogicalIoReads,
        AvgLogicalIoWrites,
        LastLogicalIoWrites,
        MinLogicalIoWrites,
        MaxLogicalIoWrites,
        AvgPhysicalIoReads,
        LastPhysicalIoReads,
        MinPhysicalIoReads,
        MaxPhysicalIoReads,
        AvgNumPhysicalIoReads,
        LastNumPhysicalIoReads,
        MinNumPhysicalIoReads,
        MaxNumPhysicalIoReads,
        [Database Object],
        object_id,
        FirstExecutionTime,
        LastExecutionTime,
        query_sql_text,
        [Queries For Plan],
        [Execution Plan]
        FROM #QueryStoreData
        ORDER BY AvgLogicalIoReads DESC

    END

    DROP TABLE #QueryStoreData
END

DROP TABLE #TempDatabases
DROP TABLE #TempTraceFlags

--TODO
--select *  FROM sys.database_files
--Show users
--Show users permissions
-- Show Transactions
-- Show locking
-- Show Page Life Expectancy(PLE)
-- Show Index Information
-- Show DTU information
-- Show tempdb 
-- show queries spilling into tempdb
-- show batches per minute
-- Show parameter sniffing queries
-- Most memory allowed by a single query -- Buffer Pool Memory?
-- Show Large Resource Semaphore
-- Show Small Resource Semaphore
-- Show all current logged in users
-- Show what wait states users are in
-- permission for those users.
-- Threading settings


--- maintanice windows
    -- statistics/stats -  that get updated more often you might want to do every day more reorgs that rebuilds online/offline reorgs??
    --              - tables that don't get update often don't need to
    --               DBCC CHECKDB? - Brent Ozar Unlimited® - https://www.brentozar.com/archive/2016/02/how-often-should-i-run-dbcc-checkdb/ 
    --              backup - 
    --              traceflage for updating statistics

    -- 
-- know your baseline cpu usage for the past few weeks during different times
-- how many log flushes
-- how many batche requests