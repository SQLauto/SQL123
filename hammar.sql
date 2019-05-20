DROP TABLE IF EXISTS #TempDatabases
DROP TABLE IF EXISTS #TempTraceFlags
DROP TABLE IF EXISTS #TempDmQueryStats
DROP TABLE IF EXISTS #tempQueryStoreRuntimeStats
DROP TABLE IF EXISTS #TempQueryStoreData;
DROP TABLE IF EXISTS #TempSessionsRequestAndConnections

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
DECLARE @showDmGrants BIT = 0;
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

	SELECT

    @@SPID                                                                                                           AS SPID,

    qs.total_rows                                                                                                    AS TotalRowsAsInt,
    FORMAT(qs.total_rows , N'###,###,###0')                                                                          AS TotalRowsAsString,
    qs.total_rows/qs.execution_count                                                                                 AS AvgRowsAsInt,
    FORMAT(qs.total_rows/qs.execution_count    , N'###,###,###0')                                                    AS AvgRowsAsString,
    qs.last_rows                                                                                                     AS LastRowsAsInt,
    FORMAT(qs.last_rows , N'###,###,###0')                                                                           AS LastRowsAsString,
    qs.min_rows                                                                                                      AS MinRowsAsInt,
    FORMAT(qs.min_rows , N'###,###,###0')                                                                            AS MinRowsAsString,
    qs.max_rows                                                                                                      AS MaxRowsAsInt,
    FORMAT(qs.max_rows , N'###,###,###0')                                                                            AS MaxRowsAsString,
                
    qs.execution_count                                                                                               AS TotalExectionsCountAsInt,
    FORMAT(qs.execution_count , N'###,###,###0')                                                                     AS TotalExectionsCountAsString,

    qs.creation_time                                                                                                 AS CompiledDateTimeAsDateTime,
    qs.last_execution_time                                                                                           AS LastExecutionDateTime,

    qs.plan_generation_num                                                                                           AS PlanGenerationNumber,
                
    qs.total_dop                                                                                                     AS TotalParallelismOrDopAsInt,
    FORMAT(qs.total_dop , N'###,###,###0')                                                                           AS TotalParallelismOrDopAsString,
    qs.total_dop/qs.execution_count                                                                                  AS AvgParallelismOrDopAsInt,
    FORMAT(qs.total_dop/qs.execution_count , N'###,###,###0')                                                        AS AvgParallelismOrDopAsString,
    qs.last_dop                                                                                                      AS LastlParallelismOrDopAsInt,
    FORMAT(qs.last_dop , N'###,###,###0')                                                                            AS LastlParallelismOrDopAsString,
    qs.min_dop                                                                                                       AS MinlParallelismOrDopAsInt,
    FORMAT(qs.min_dop , N'###,###,###0')                                                                             AS MinlParallelismOrDopAsString,
    qs.max_dop                                                                                                       AS MaxlParallelismOrDopAsInt,
    FORMAT(qs.max_dop , N'###,###,###0')                                                                             AS MaxlParallelismOrDopAsString,

    qs.total_spills                                                                                                  AS TotalSpillsAsInt,
    FORMAT(qs.total_spills , N'###,###,###0')                                                                        AS TotalSpillsAsString,
    qs.total_spills/qs.execution_count                                                                               AS AvgSpillsAsInt,
    FORMAT(qs.total_spills/qs.execution_count    , N'###,###,###0')                                                  AS AvgSpillsAsString,
    qs.last_spills                                                                                                   AS LastSpillsAsInt,
    FORMAT(qs.last_spills , N'###,###,###0')                                                                         AS LastSpillsAsString,
    qs.min_spills                                                                                                    AS MinSpillsAsInt,
    FORMAT(qs.min_spills , N'###,###,###0')                                                                          AS MinSpillsAsString,
    qs.max_spills                                                                                                    AS MaxSpillsAsInt,
    FORMAT(qs.max_spills , N'###,###,###0')                                                                          AS MaxSpillsAsString,
                
    qs.total_used_grant_kb                                                                                           AS TotalGrantAsInt,
    FORMAT(qs.total_used_grant_kb, N'###,###,###0')                                                                  AS TotalGrantAsString,
    qs.total_used_grant_kb/qs.execution_count                                                                        AS AvgGrantAsInt,
    FORMAT(qs.total_used_grant_kb/qs.execution_count    , N'###,###,###0')                                           AS AvgGrantAsString,
    qs.last_used_grant_kb                                                                                            AS LastGrantAsInt,
    FORMAT(qs.last_used_grant_kb, N'###,###,###0')                                                                   AS LastGrantAsString,
    qs.min_used_grant_kb                                                                                             AS MinGrantAsInt,
    FORMAT(qs.min_used_grant_kb, N'###,###,###0')                                                                    AS MinGrantAsString,
    qs.max_used_grant_kb                                                                                             AS MaxGrantAsInt,
    FORMAT(qs.max_used_grant_kb, N'###,###,###0')                                                                    AS MaxGrantAsString,
                
    qs.total_used_grant_kb                                                                                           AS TotalUsedGrantInt,
    FORMAT(qs.total_used_grant_kb, N'###,###,###0')                                                                  AS TotalUsedGrantString,
    qs.total_used_grant_kb/qs.execution_count                                                                        AS AvgUsedGrantInt,
    FORMAT(qs.total_used_grant_kb/qs.execution_count    , N'###,###,###0')                                           AS AvgUsedGrantString,
    qs.last_used_grant_kb                                                                                            AS LastUsedGrantInt,
    FORMAT(qs.last_used_grant_kb, N'###,###,###0')                                                                   AS LastUsedGrantString,
    qs.min_used_grant_kb                                                                                             AS MinUsedGrantInt,
    FORMAT(qs.min_used_grant_kb, N'###,###,###0')                                                                    AS MinUsedGrantString,
    qs.max_used_grant_kb                                                                                             AS MaxUsedGrantInt,
    FORMAT(qs.max_used_grant_kb, N'###,###,###0')                                                                    AS MaxUsedGrantString,
                
    qs.total_ideal_grant_kb                                                                                          AS TotalIdealGrantInt,
    FORMAT(qs.total_ideal_grant_kb, N'###,###,###0')                                                                 AS TotalIdealGrantString,
    qs.total_ideal_grant_kb/qs.execution_count                                                                       AS AvgIdealGrantInt,
    FORMAT(qs.total_ideal_grant_kb/qs.execution_count    , N'###,###,###0')                                          AS AvgIdealGrantString,
    qs.last_ideal_grant_kb                                                                                           AS LastIdealGrantInt,
    FORMAT(qs.last_ideal_grant_kb, N'###,###,###0')                                                                  AS LastIdealGrantString,
    qs.min_ideal_grant_kb                                                                                            AS MinIdealGrantInt,
    FORMAT(qs.min_ideal_grant_kb, N'###,###,###0')                                                                   AS MinIdealGrantString,
    qs.max_ideal_grant_kb                                                                                            AS MaxIdealGrantInt,
    FORMAT(qs.max_ideal_grant_kb, N'###,###,###0')                                                                   AS MaxIdealGrantString,

    qs.total_worker_time/1000                                                                                        AS TotalCpuDurationAsInt,
    CONVERT(VARCHAR(10), (qs.total_worker_time/1000/86400000)) + 'd ' +
    CONVERT(VARCHAR(10), ((qs.total_worker_time/1000%86400000)/3600000)) + 'h '+
    CONVERT(VARCHAR(10), (((qs.total_worker_time/1000%86400000)%3600000)/60000)) + 'm '+
    CONVERT(varchar(10), ((((qs.total_worker_time/1000%86400000)%3600000)%60000)/1000)) + 's ' +
    CONVERT(VARCHAR(10), (((qs.total_worker_time/1000%86400000)%3600000)%1000)) + 'ms'                               AS TotalCpuDurationAsString,

    qs.total_worker_time/1000/qs.execution_count                                                                     AS AvgCpuDurationAsInt,
    CONVERT(VARCHAR(10), (qs.total_worker_time/qs.execution_count/1000/86400000)) + 'd ' +
    CONVERT(VARCHAR(10), ((qs.total_worker_time/qs.execution_count/1000%86400000)/3600000)) + 'h '+
    CONVERT(VARCHAR(10), (((qs.total_worker_time/qs.execution_count/1000%86400000)%3600000)/60000)) + 'm '+
    CONVERT(varchar(10), ((((qs.total_worker_time/qs.execution_count/1000%86400000)%3600000)%60000)/1000)) + 's ' +
    CONVERT(VARCHAR(10), (((qs.total_worker_time/qs.execution_count/1000%86400000)%3600000)%1000)) + 'ms'            AS AvgCpuDurationAsString,

    qs.last_worker_time/1000                                                                                         AS LastCpuDurationAsInt,
    CONVERT(VARCHAR(10), (qs.last_worker_time/1000/86400000)) + 'd ' +
    CONVERT(VARCHAR(10), ((qs.last_worker_time/1000%86400000)/3600000)) + 'h '+
    CONVERT(VARCHAR(10), (((qs.last_worker_time/1000%86400000)%3600000)/60000)) + 'm '+
    CONVERT(varchar(10), ((((qs.last_worker_time/1000%86400000)%3600000)%60000)/1000)) + 's ' +
    CONVERT(VARCHAR(10), (((qs.last_worker_time/1000%86400000)%3600000)%1000)) + 'ms'                                AS LastCpuDurationAsString,

    qs.min_worker_time/1000                                                                                          AS MinCpuDurationAsInt, 
    CONVERT(VARCHAR(10), (qs.min_worker_time/1000/86400000)) + 'd ' +
    CONVERT(VARCHAR(10), ((qs.min_worker_time/1000%86400000)/3600000)) + 'h '+
    CONVERT(VARCHAR(10), (((qs.min_worker_time/1000%86400000)%3600000)/60000)) + 'm '+
    CONVERT(varchar(10), ((((qs.min_worker_time/1000%86400000)%3600000)%60000)/1000)) + 's ' +
    CONVERT(VARCHAR(10), (((qs.min_worker_time/1000%86400000)%3600000)%1000)) + 'ms'                                 AS MinCpuDurationAsString,

    qs.max_worker_time/1000                                                                                          AS MaxCpuDurationAsInt, 
    CONVERT(VARCHAR(10), (qs.max_worker_time/1000/86400000)) + 'd ' +
    CONVERT(VARCHAR(10), ((qs.max_worker_time/1000%86400000)/3600000)) + 'h '+
    CONVERT(VARCHAR(10), (((qs.max_worker_time/1000%86400000)%3600000)/60000)) + 'm '+
    CONVERT(varchar(10), ((((qs.max_worker_time/1000%86400000)%3600000)%60000)/1000)) + 's ' +
    CONVERT(VARCHAR(10), (((qs.max_worker_time/1000%86400000)%3600000)%1000)) + 'ms'                                 AS MaxCpuDurationAsString,

    qs.total_logical_writes                                                                                          AS TotalLogicalWritesAsInt,
    FORMAT(qs.total_logical_writes, N'###,###,###0')                                                                 AS TotalLogicalWritesAsString,
    qs.total_logical_writes/qs.execution_count                                                                       AS AvgLogicalWritesAsInt,
    FORMAT(qs.total_logical_writes/qs.execution_count, N'###,###,###0')                                              AS AvgLogicalWritesAsString,
    qs.last_logical_writes                                                                                           AS LastLogicalWritesAsInt,
    FORMAT(qs.last_logical_writes, N'###,###,###0')                                                                  AS LastLogicalWritesAsString,
    qs.min_logical_writes                                                                                            AS MinLogicalWritesAsInt,
    FORMAT(qs.min_logical_writes, N'###,###,###0')                                                                   AS MinLogicalWritesAsString,
    qs.max_logical_writes                                                                                            AS MaxLogicalWritesAsInt,
    FORMAT(qs.max_logical_writes, N'###,###,###0')                                                                   AS MaxLogicalWritesAsString,

    qs.total_logical_reads                                                                                           AS TotalLogicalReadsAsInt,
    FORMAT(qs.total_logical_reads, N'###,###,###0')                                                                  AS TotalLogicalReadsAsString,
    qs.total_logical_reads/qs.execution_count                                                                        AS AvgLogicalReadsAsInt,
    FORMAT(qs.total_logical_reads/qs.execution_count, N'###,###,###0')                                               AS AvgLogicalReadsAsString,
    qs.last_logical_reads                                                                                            AS LastLogicalReadsAsInt,
    FORMAT(qs.last_logical_reads, N'###,###,###0')                                                                   AS LastLogicalReadsAsString,
    qs.min_logical_reads                                                                                             AS MinLogicalReadsAsInt,
    FORMAT(qs.min_logical_reads, N'###,###,###0')                                                                    AS MinLogicalReadsAsString,
    qs.max_logical_reads                                                                                             AS MaxLogicalReadsAsInt,
    FORMAT(qs.max_logical_reads, N'###,###,###0')                                                                    AS MaxLogicalReadsAsString,

    qs.total_physical_reads                                                                                          AS TotalPhysicalReadsAsInt,
    FORMAT(qs.total_physical_reads, N'###,###,###0')                                                                 AS TotalPhysicalReadsAsString,
    qs.total_physical_reads/qs.execution_count                                                                       AS AvgPhysicalReadsAsInt,
    FORMAT(qs.total_physical_reads/qs.execution_count, N'###,###,###0')                                              AS AvgPhysicalReadsAsString,
    qs.last_physical_reads                                                                                           AS LastPhysicalReadsAsInt,
    FORMAT(qs.last_physical_reads, N'###,###,###0')                                                                  AS LastPhysicalReadsAsString,
    qs.min_physical_reads                                                                                            AS MinPhysicalReadsAsInt,
    FORMAT(qs.min_physical_reads, N'###,###,###0')                                                                   AS MinPhysicalReadsAsString,
    qs.max_physical_reads                                                                                            AS MaxPhysicalReadsAsInt,
    FORMAT(qs.max_physical_reads, N'###,###,###0')                                                                   AS MaxPhysicalReadsAsString,

    qs.total_clr_time/1000                                                                                           AS TotalClrTimeAsInt,
    CONVERT(VARCHAR(10), (qs.total_clr_time/1000/86400000)) + 'd ' +
    CONVERT(VARCHAR(10), ((qs.total_clr_time/1000%86400000)/3600000)) + 'h '+
    CONVERT(VARCHAR(10), (((qs.total_clr_time/1000%86400000)%3600000)/60000)) + 'm '+
    CONVERT(varchar(10), ((((qs.total_clr_time/1000%86400000)%3600000)%60000)/1000)) + 's ' +
    CONVERT(VARCHAR(10), (((qs.total_clr_time/1000%86400000)%3600000)%1000)) + 'ms'                                  AS TotalClrTimeAsString,

    qs.total_clr_time/1000/qs.execution_count                                                                        AS AvgClrTimeAsInt,
    CONVERT(VARCHAR(10), (qs.total_clr_time/qs.execution_count/1000/86400000)) + 'd ' +
    CONVERT(VARCHAR(10), ((qs.total_clr_time/qs.execution_count/1000%86400000)/3600000)) + 'h '+
    CONVERT(VARCHAR(10), (((qs.total_clr_time/qs.execution_count/1000%86400000)%3600000)/60000)) + 'm '+
    CONVERT(varchar(10), ((((qs.total_clr_time/qs.execution_count/1000%86400000)%3600000)%60000)/1000)) + 's ' +
    CONVERT(VARCHAR(10), (((qs.total_clr_time/qs.execution_count/1000%86400000)%3600000)%1000)) + 'ms'               AS AvgClrTimeAsString,

    qs.last_clr_time/1000                                                                                            AS LastClrTimeAsInt,
    CONVERT(VARCHAR(10), (qs.last_clr_time/1000/86400000)) + 'd ' +
    CONVERT(VARCHAR(10), ((qs.last_clr_time/1000%86400000)/3600000)) + 'h '+
    CONVERT(VARCHAR(10), (((qs.last_clr_time/1000%86400000)%3600000)/60000)) + 'm '+
    CONVERT(varchar(10), ((((qs.last_clr_time/1000%86400000)%3600000)%60000)/1000)) + 's ' +
    CONVERT(VARCHAR(10), (((qs.last_clr_time/1000%86400000)%3600000)%1000)) + 'ms'                                   AS LastClrTimeAsString,

    qs.min_clr_time/1000                                                                                             AS MinClrTimeAsInt, 
    CONVERT(VARCHAR(10), (qs.min_clr_time/1000/86400000)) + 'd ' +
    CONVERT(VARCHAR(10), ((qs.min_clr_time/1000%86400000)/3600000)) + 'h '+
    CONVERT(VARCHAR(10), (((qs.min_clr_time/1000%86400000)%3600000)/60000)) + 'm '+
    CONVERT(varchar(10), ((((qs.min_clr_time/1000%86400000)%3600000)%60000)/1000)) + 's ' +
    CONVERT(VARCHAR(10), (((qs.min_clr_time/1000%86400000)%3600000)%1000)) + 'ms'                                    AS MinClrTimeAsString,

    qs.max_clr_time/1000                                                                                             AS MaxClrTimeAsInt, 
    CONVERT(VARCHAR(10), (qs.max_clr_time/1000/86400000)) + 'd ' +
    CONVERT(VARCHAR(10), ((qs.max_clr_time/1000%86400000)/3600000)) + 'h '+
    CONVERT(VARCHAR(10), (((qs.max_clr_time/1000%86400000)%3600000)/60000)) + 'm '+
    CONVERT(varchar(10), ((((qs.max_clr_time/1000%86400000)%3600000)%60000)/1000)) + 's ' +
    CONVERT(VARCHAR(10), (((qs.max_clr_time/1000%86400000)%3600000)%1000)) + 'ms'                                    AS MaxClrTimeAsString,

    qs.statement_start_offset                                                                                        AS StatementStartOffset,
    qs.statement_start_offset                                                                                        AS StatementEndOffset,

    qs.sql_handle                                                                                                    AS SqlHandle,
    qs.plan_handle                                                                                                   AS PlanHandle

	INTO #TempDmQueryStats
	FROM sys.dm_exec_query_stats AS qs


	IF @showDmGrants = 1 BEGIN

        SELECT TOP(@top)
		SPID,
        qs.TotalRowsAsString AS TotalRows,
        qs.AvgRowsAsString AS AvgRows,
        qs.LastRowsAsString AS LastRows,
        qs.MinRowsAsString AS MinRows,
        qs.MaxRowsAsString AS MaxRows,
		FORMAT(LEN(t.text) , N'###,###,###0') AS SQLTextLength,
		qs.TotalExectionsCountAsString AS TotalExections,
		qs.CompiledDateTimeAsDateTime,
		qs.LastExecutionDateTime,

		qs.AvgGrantAsString AS AvgGrants,
		qs.LastGrantAsString AS LastGrants,
		qs.MinGrantAsString AS MinGrants,
		qs.MaxGrantAsString AS MaxGrants,
		qs.TotalGrantAsString AS TotalGrants,

        qs.AvgUsedGrantString AS AvgUsedGrants,
		qs.LastUsedGrantString AS LastUsedGrants,
		qs.MinUsedGrantString AS MinUsedGrants,
		qs.MaxUsedGrantString AS MaxUsedGrants,
		qs.TotalUsedGrantString AS TotalUsedGrants,

        qs.AvgIdealGrantString AS AvgUsedGrants,
		qs.LastIdealGrantString AS LastUsedGrants,
		qs.MinIdealGrantString AS MinUsedGrants,
		qs.MaxIdealGrantString AS MaxUsedGrants,
		qs.TotalIdealGrantString AS TotalUsedGrants,

		OBJECT_NAME(qp.objectid) AS DatabaseObject,
        qp.number AS NumberedStoreProcedure,
		qs.PlanGenerationNumber,
        SUBSTRING(t.text, (qs.StatementStartOffset/2) + 1,  
        ((
            CASE qs.StatementEndOffset   
                WHEN -1 THEN DATALENGTH(t.text)  
                ELSE qs.StatementEndOffset 
            END - qs.StatementStartOffset)/2
        ) + 1) AS QueryTextInBatch,
        t.text AS QueryText,
		CAST(qp.query_plan AS XML) AS QueryPlan
		FROM #TempDmQueryStats AS qs
		CROSS APPLY sys.dm_exec_sql_text(qs.SqlHandle) AS t
		CROSS apply sys.dm_exec_query_plan (qs.PlanHandle) AS qp
		WHERE @minTotalExecutionsOrderingAvg IS NULL 
		OR qs.TotalExectionsCountAsInt >= @minTotalExecutionsOrderingAvg
		ORDER BY qs.AvgGrantAsString DESC;

	END

    IF @showDmCpuDuration = 1 BEGIN

        SELECT TOP(@top)
		SPID,
        qs.TotalRowsAsString AS TotalRows,
        qs.AvgRowsAsString AS AvgRows,
        qs.LastRowsAsString AS LastRows,
        qs.MinRowsAsString AS MinRows,
        qs.MaxRowsAsString AS MaxRows,
		FORMAT(LEN(t.text) , N'###,###,###0') AS SQLTextLength,
		qs.TotalExectionsCountAsString AS TotalExections,
		qs.CompiledDateTimeAsDateTime,
		qs.LastExecutionDateTime,
		
		qs.AvgCpuDurationAsString AS AvgCpuDuration,
		qs.LastCpuDurationAsString AS LastCpuDuration,
		qs.MinCpuDurationAsString AS MinCpuDuration,
		qs.MaxCpuDurationAsString AS MaxCpuDuration,
		qs.TotalCpuDurationAsString AS TotalCpuDuration,

		OBJECT_NAME(qp.objectid) AS DatabaseObject,
        qp.number AS NumberedStoreProcedure,
		qs.PlanGenerationNumber,
        SUBSTRING(t.text, (qs.StatementStartOffset/2) + 1,  
        ((
            CASE qs.StatementEndOffset   
                WHEN -1 THEN DATALENGTH(t.text)  
                ELSE qs.StatementEndOffset 
            END - qs.StatementStartOffset)/2
        ) + 1) AS QueryTextInBatch,
        t.text AS QueryText,
		CAST(qp.query_plan AS XML) AS QueryPlan
		FROM #TempDmQueryStats AS qs
		CROSS APPLY sys.dm_exec_sql_text(qs.SqlHandle) AS t
		CROSS apply sys.dm_exec_query_plan (qs.PlanHandle) AS qp
		WHERE @minTotalExecutionsOrderingAvg IS NULL 
		OR qs.TotalExectionsCountAsInt >= @minTotalExecutionsOrderingAvg
		ORDER BY qs.AvgCpuDurationAsInt DESC;

	END

    
	IF @showDmLogicallReads = 1 BEGIN

		SELECT TOP(@top)
		SPID,
        qs.TotalRowsAsString AS TotalRows,
        qs.AvgRowsAsString AS AvgRows,
        qs.LastRowsAsString AS LastRows,
        qs.MinRowsAsString AS MinRows,
        qs.MaxRowsAsString AS MaxRows,
		FORMAT(LEN(t.text) , N'###,###,###0') AS SQLTextLength,
		qs.TotalExectionsCountAsString AS TotalExections,
		qs.CompiledDateTimeAsDateTime,
		qs.LastExecutionDateTime,
		
		qs.AvgLogicalReadsAsString AS AvgLogicalReads,
		qs.LastLogicalReadsAsString AS LastLogicalReads,
		qs.MinLogicalReadsAsString AS MinLogicalReads,
		qs.MaxLogicalReadsAsString AS MaxLogicalReads,
		qs.TotalLogicalReadsAsString AS TotalLogicalReads,

		OBJECT_NAME(qp.objectid) AS DatabaseObject,
        qp.number AS NumberedStoreProcedure,
		qs.PlanGenerationNumber,
        SUBSTRING(t.text, (qs.StatementStartOffset/2) + 1,  
        ((
            CASE qs.StatementEndOffset   
                WHEN -1 THEN DATALENGTH(t.text)  
                ELSE qs.StatementEndOffset 
            END - qs.StatementStartOffset)/2
        ) + 1) AS QueryTextInBatch,
        t.text AS QueryText,
		CAST(qp.query_plan AS XML) AS QueryPlan
		FROM #TempDmQueryStats AS qs
		CROSS APPLY sys.dm_exec_sql_text(qs.SqlHandle) AS t
		CROSS apply sys.dm_exec_query_plan (qs.PlanHandle) AS qp
		WHERE @minTotalExecutionsOrderingAvg IS NULL 
		OR qs.TotalExectionsCountAsInt >= @minTotalExecutionsOrderingAvg
		ORDER BY qs.AvgLogicalReadsAsInt DESC;

	END

        
    IF @showDmSpills = 1 BEGIN

		SELECT TOP(@top)
		SPID,
        qs.TotalRowsAsString AS TotalRows,
        qs.AvgRowsAsString AS AvgRows,
        qs.LastRowsAsString AS LastRows,
        qs.MinRowsAsString AS MinRows,
        qs.MaxRowsAsString AS MaxRows,
		FORMAT(LEN(t.text) , N'###,###,###0') AS SQLTextLength,
		qs.TotalExectionsCountAsString AS TotalExections,
		qs.CompiledDateTimeAsDateTime,
		qs.LastExecutionDateTime,

		qs.AvgSpillsAsString AS AvgSpills,
		qs.LastSpillsAsString AS LastSpills,
		qs.MinSpillsAsString AS MinSpills,
		qs.MaxSpillsAsString AS MaxSpills,
		qs.TotalSpillsAsString AS TotalSpills,

		OBJECT_NAME(qp.objectid) AS DatabaseObject,
        qp.number AS NumberedStoreProcedure,
		qs.PlanGenerationNumber,
        SUBSTRING(t.text, (qs.StatementStartOffset/2) + 1,  
        ((
            CASE qs.StatementEndOffset   
                WHEN -1 THEN DATALENGTH(t.text)  
                ELSE qs.StatementEndOffset 
            END - qs.StatementStartOffset)/2
        ) + 1) AS QueryTextInBatch,
        t.text AS QueryText,
		CAST(qp.query_plan AS XML) AS QueryPlan
		FROM #TempDmQueryStats AS qs
		CROSS APPLY sys.dm_exec_sql_text(qs.SqlHandle) AS t
		CROSS apply sys.dm_exec_query_plan (qs.PlanHandle) AS qp
		WHERE @minTotalExecutionsOrderingAvg IS NULL 
		OR qs.TotalExectionsCountAsInt >= @minTotalExecutionsOrderingAvg
		ORDER BY qs.AvgSpillsAsInt DESC;

	END

	IF @showDmStoreParallelism = 1 BEGIN

        SELECT TOP(@top)
		SPID,
        qs.TotalRowsAsString AS TotalRows,
        qs.AvgRowsAsString AS AvgRows,
        qs.LastRowsAsString AS LastRows,
        qs.MinRowsAsString AS MinRows,
        qs.MaxRowsAsString AS MaxRows,
		FORMAT(LEN(t.text) , N'###,###,###0') AS SQLTextLength,
		qs.TotalExectionsCountAsString AS TotalExections,
		qs.CompiledDateTimeAsDateTime,
		qs.LastExecutionDateTime,
		
		qs.AvgParallelismOrDopAsString AS AvgParallelismOrDop,
		qs.LastlParallelismOrDopAsString AS LastParallelismDop,
		qs.MinlParallelismOrDopAsString AS MinParallelismDop,
		qs.MaxlParallelismOrDopAsString AS MaxParallelismDop,
		qs.TotalParallelismOrDopAsString AS TotalParallelismOrDop,

		OBJECT_NAME(qp.objectid) AS DatabaseObject,
        qp.number AS NumberedStoreProcedure,
		qs.PlanGenerationNumber,
        SUBSTRING(t.text, (qs.StatementStartOffset/2) + 1,  
        ((
            CASE qs.StatementEndOffset   
                WHEN -1 THEN DATALENGTH(t.text)  
                ELSE qs.StatementEndOffset 
            END - qs.StatementStartOffset)/2
        ) + 1) AS QueryTextInBatch,
        t.text AS QueryText,
		CAST(qp.query_plan AS XML) AS QueryPlan
		FROM #TempDmQueryStats AS qs
		CROSS APPLY sys.dm_exec_sql_text(qs.SqlHandle) AS t
		CROSS apply sys.dm_exec_query_plan (qs.PlanHandle) AS qp
		WHERE @minTotalExecutionsOrderingAvg IS NULL 
		OR qs.TotalExectionsCountAsInt >= @minTotalExecutionsOrderingAvg
		ORDER BY qs.AvgParallelismOrDopAsInt DESC;

	END


	IF @showDmClrDuration = 1 BEGIN

		SELECT TOP(@top)
		SPID,
        qs.TotalRowsAsString AS TotalRows,
        qs.AvgRowsAsString AS AvgRows,
        qs.LastRowsAsString AS LastRows,
        qs.MinRowsAsString AS MinRows,
        qs.MaxRowsAsString AS MaxRows,
		FORMAT(LEN(t.text) , N'###,###,###0') AS SQLTextLength,
		qs.TotalExectionsCountAsString AS TotalExections,
		qs.CompiledDateTimeAsDateTime,
		qs.LastExecutionDateTime,
		
		qs.AvgPhysicalReadsAsString AS AvgPhysicalReads,
		qs.LastPhysicalReadsAsString AS LastPhysicalReads,
		qs.MinPhysicalReadsAsString AS MinPhysicalReads,
		qs.MaxPhysicalReadsAsString AS MaxPhysicalReads,
		qs.TotalPhysicalReadsAsString AS TotalPhysicalReads,

		OBJECT_NAME(qp.objectid) AS DatabaseObject,
        qp.number AS NumberedStoreProcedure,
		qs.PlanGenerationNumber,
        SUBSTRING(t.text, (qs.StatementStartOffset/2) + 1,  
        ((
            CASE qs.StatementEndOffset   
                WHEN -1 THEN DATALENGTH(t.text)  
                ELSE qs.StatementEndOffset 
            END - qs.StatementStartOffset)/2
        ) + 1) AS QueryTextInBatch,
        t.text AS QueryText,
		CAST(qp.query_plan AS XML) AS QueryPlan
		FROM #TempDmQueryStats AS qs
		CROSS APPLY sys.dm_exec_sql_text(qs.SqlHandle) AS t
		CROSS apply sys.dm_exec_query_plan (qs.PlanHandle) AS qp
		WHERE @minTotalExecutionsOrderingAvg IS NULL 
		OR qs.TotalExectionsCountAsInt >= @minTotalExecutionsOrderingAvg
		ORDER BY qs.AvgPhysicalReadsAsInt DESC;

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
	c.connect_time AS ConnectionConnectTimeAsDateTime, 
	c.protocol_type As ConnectionProtocolTypeAsString, 
	c.net_transport AS ConnectionNetTransportAsString, 
	c.client_net_address AS ConnectionClientNetAddressAsString, 
	c.client_tcp_port AS ConnectionTcpPortAsInt,
    login_name AS SessionLoginNameAsString,
    s.original_login_name AS SessionOriginalLoginNameAsString,
    nt_user_name AS SessionNtUserNameAsString,
    nt_domain AS SessionNtDomainAsString,
    login_time AS SessionLoginTimeAsDateTime,
	s.program_name AS ProgramNameAsString,
    s.client_version AS SessionClientVersionAsInt,
    s.client_interface_name AS SessionClientAsString,
    s.status AS SessionStatusAsString,
    s.cpu_time AS SessionCpuTimeAsInt,
    s.memory_usage AS SessionMemoryUsage8KBPagesAsInt,
    s.total_elapsed_time AS SessionTotalElapedTimeAsInt,
    s.total_scheduled_time As SessionTotalTimeScheduledForExectionAsInt,
    s.last_request_start_time AS SessionRequestedStartTimeAsDateTime,
    s.last_request_end_time AS SessionRequestedEndTimeAsDateTime,
    s.reads AS SessionReadsPerformedAsInt,
    s.writes AS SessionWritesPerformedAsInt,
    s.logical_reads AS SessionLogicalReadsAsInt,
    s.is_user_process AS SessionIsUserProcessAsBit,
    s.text_size TextSizeAsInt,
    CASE
	 WHEN s.transaction_isolation_level = 0 THEN N'Unspecified'
	 WHEN s.transaction_isolation_level = 1 THEN N'Read Uncomitted'
	 WHEN s.transaction_isolation_level = 2 THEN N'Read Committed'
	 WHEN s.transaction_isolation_level = 5 THEN N'Repeatable'
	 WHEN s.transaction_isolation_level = 4 THEN N'Serializable'
	 WHEN s.transaction_isolation_level = 5 THEN N'Snapshot'
	 ELSE N'View here https://docs.microsoft.com/en-us/sql/relational-databases/system-dynamic-management-views/sys-dm-exec-sessions-transact-sql?view=sql-server-2017 to find out'
	END As SessionTransactionIsolationLevelAsString,
    s.lock_timeout AS SessionLockTimeoutAsInt,
    s.deadlock_priority AS SessionDeadlockPriorityAsInt,
    s.row_count AS SessionRowCountAsInt,
    s.prev_error AS SessionPreviousErrorAsInt,
    s.last_successful_logon AS SessionLastSuccessfulLogonAsDateTime,
    s.last_unsuccessful_logon AS SessionLastUnSuccessfulLogonAsDateTime,
    DB_NAME(s.database_id) AS SessionDatabaseAsString,
    s.open_transaction_count AS SessionOpenTransactionCountAsInt,
    r.start_time As RequestStartTimeAsDateTime,
    r.status As RequestStatusAsString,
    r.command As RequestCommandAsString,
    DB_NAME(r.database_id) AS RequestDatabaseAsString,
    r.blocking_session_id AS RequestBlockingSessionIdAsInt,
    r.wait_type AS RequestWaitTypeAsString,
    r.wait_time AS RequestWaitTimeAsInt,
    r.last_wait_type AS RequestLastWaitTypeAsString,
    r.wait_resource AS RequestWaitResourceAsString,
    r.sql_handle AS RequestSqlHandleAsBinary,
    r.statement_start_offset AS RequestStatementStartOffsetAsInt,
    r.statement_end_offset AS RequestStatementEndOffsetAsInt,
    r.plan_handle AS RequestPlanHandleAsBinary,
    r.user_id AS RequestUserIdAsInt,
    r.connection_id AS RequestConnectionIdAsUniqueIdentifier,
    r.open_transaction_count AS RequestOpenTransactionCountAsInt,
    transaction_id AS RequestTransactionIdAsInt,
    r.cpu_time AS RequestCpuTimeAsInt,
    r.total_elapsed_time AS RequestTotalElapedTimeAsInt,
    r.scheduler_id AS RequestSchedulerThatIsSchedulingTheRequestAsInt,
    r.reads AS RequestReadsAsInt,
    r.writes AS RequestWritesAsInt,
    r.logical_reads AS RequestLogicalReadsAsInt,
    CASE
	 WHEN r.transaction_isolation_level = 0 THEN N'Unspecified'
	 WHEN r.transaction_isolation_level = 1 THEN N'Read Uncomitted'
	 WHEN r.transaction_isolation_level = 2 THEN N'Read Committed'
	 WHEN r.transaction_isolation_level = 5 THEN N'Repeatable'
	 WHEN r.transaction_isolation_level = 4 THEN N'Serializable'
	 WHEN r.transaction_isolation_level = 5 THEN N'Snapshot'
	 ELSE N'View here https://docs.microsoft.com/en-us/sql/relational-databases/system-dynamic-management-views/sys-dm-exec-sessions-transact-sql?view=sql-server-2017 to find out'
	END As RequestTransactionIsolationLevelAsString,
    r.lock_timeout AS RequestLockTimeoutAsInt,
    r.deadlock_priority AS RequestDeadlockPriorityAsInt,
    r.row_count AS RequestRowCountAsInt,
    r.prev_error AS RequestPreviousErrorAsInt,
    r.nest_level AS RequestNestLevelAsInt,
    r.granted_query_memory AS RequestQueryMemoryGrantAsInt,
    r.dop AS RequestDegreeOfParallelismForQueryAsInt,
    r.parallel_worker_count AS RequestParallelWorkerCountAsInt,
	t.text AS SqlTextAsString,
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

        SELECT 
		SPID,
		ConnectionConnectTimeAsDateTime, 
		ConnectionProtocolTypeAsString, 
		ConnectionNetTransportAsString, 
		ConnectionClientNetAddressAsString, 
		ConnectionTcpPortAsInt,
        SessionDatabaseAsString,
        SessionLoginNameAsString,
		SessionNtUserNameAsString,
        SessionNtDomainAsString,
		SessionLoginTimeAsDateTime,
        SessionClientAsString,
        SessionClientVersionAsInt,
        SessionIsUserProcessAsBit,
        SessionStatusAsString,
        CAST(SessionTotalElapedTimeAsInt AS NVARCHAR(50)) + ' ms' AS SessionTotalElapedTime,
        SessionRequestedStartTimeAsDateTime,
        SessionRequestedEndTimeAsDateTime,
        SessionLastSuccessfulLogonAsDateTime,
        SessionLastUnSuccessfulLogonAsDateTime
        FROM #TempSessionsRequestAndConnections
        WHERE @showUserConnections = 1 OR SPID = @@SPID

    END

    IF @showSpidSessionRuntimeStats = 1 BEGIN

        SELECT
        SPID,
        SessionDatabaseAsString,
        SessionLoginNameAsString,
        SessionStatusAsString,
        SessionCpuTimeAsInt,
        SessionMemoryUsage8KBPagesAsInt,
        SessionReadsPerformedAsInt,
        SessionWritesPerformedAsInt,
        SessionLogicalReadsAsInt,
        SessionTransactionIsolationLevelAsString,
        SessionLockTimeoutAsInt
		SessionDeadlockPriorityAsInt,
        SessionRowCountAsInt,
        SessionPreviousErrorAsInt
        FROM #TempSessionsRequestAndConnections
        WHERE SPID = @@SPID

    END

    IF @showSpidRequestRuntimeStats = 1 BEGIN

        SELECT
        SPID,
        RequestDatabaseAsString,
        RequestStartTimeAsDateTime,
        RequestStatusAsString,
        RequestOpenTransactionCountAsInt,
        RequestTransactionIdAsInt,
        RequestCpuTimeAsInt,
        RequestTotalElapedTimeAsInt,
        RequestReadsAsInt,
        RequestWritesAsInt,
        RequestLogicalReadsAsInt,
        RequestTransactionIsolationLevelAsString,
        RequestLockTimeoutAsInt,
        RequestDeadlockPriorityAsInt,
        RequestRowCountAsInt,
        RequestPreviousErrorAsInt,
        RequestNestLevelAsInt,
        RequestParallelWorkerCountAsInt
        FROM #TempSessionsRequestAndConnections
        WHERE SPID = @@SPID

    END

    IF @showSpidRequestWaitStat = 1 BEGIN

        SELECT
        SPID,
        SessionDatabaseAsString,
        RequestCommandAsString,
        RequestBlockingSessionIdAsInt,
        RequestWaitTypeAsString,
        RequestWaitTimeAsInt,
        RequestLastWaitTypeAsString,
        RequestWaitResourceAsString
        FROM #TempSessionsRequestAndConnections
        WHERE SPID = @@SPID

    END

    IF @showSpidRequestQuery = 1 BEGIN

        SELECT
        SPID,
        SessionDatabaseAsString,
        RequestCommandAsString,
        sqlText.text As SqlText,
		SUBSTRING(sqlText.text, (r.RequestStatementStartOffsetAsInt/2) + 1,  
        ((
            CASE r.RequestStatementEndOffsetAsInt 
                WHEN -1 THEN DATALENGTH(sqlText.text)  
                ELSE r.RequestStatementEndOffsetAsInt
            END - r.RequestStatementStartOffsetAsInt)/2
        ) + 1) AS QueryTextInBatch,
        sqlText.text AS QueryText,
        RequestQueryMemoryGrantAsInt,
        RequestCpuTimeAsInt,
        RequestLogicalReadsAsInt,
        RequestRowCountAsInt,
        RequestPreviousErrorAsInt,
        RequestDegreeOfParallelismForQueryAsInt,
        RequestStatementStartOffsetAsInt,
        RequestStatementEndOffsetAsInt,
        CAST(planHandle.query_plan AS XML) AS QueryPlan
        FROM #TempSessionsRequestAndConnections AS r
		CROSS APPLY sys.dm_exec_sql_text(r.RequestSqlHandleAsBinary) AS sqlText
		CROSS APPLY sys.dm_exec_query_plan(r.RequestPlanHandleAsBinary) AS planHandle
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
    OBJECT_NAME(qsq.object_id) AS DatabaseObject,
    ca_aggregate_runtime_stats.FirstExecutionTime,
    ca_aggregate_runtime_stats.LastExecutionTime,
    ca_runtime_executions.TotalExections AS TotalExectionsAsInt,
    FORMAT(ca_runtime_executions.TotalExections, N'###,###,###0') AS TotalExectionsAsString,
    ca_runtime_executions.TotalDuration AS TotalDurationAsInt,
    FORMAT(ca_runtime_executions.TotalDuration, N'###,###,###0') + N' ms' AS TotalDurationString,

    
    CONVERT(VARCHAR(10), (ca_runtime_executions.TotalDuration/86400000)) + 'd ' +
    CONVERT(VARCHAR(10), ((ca_runtime_executions.TotalDuration%86400000)/3600000)) + 'h '+
    CONVERT(VARCHAR(10), (((ca_runtime_executions.TotalDuration%86400000)%3600000)/60000)) + 'm '+
    CONVERT(varchar(10), ((((ca_runtime_executions.TotalDuration%86400000)%3600000)%60000)/1000)) + 's ' +
    CONVERT(VARCHAR(10), (((ca_runtime_executions.TotalDuration%86400000)%3600000)%1000)) + 'ms' AS TotalDurationInFormatAsString,

    ca_aggregate_runtime_stats.AvgDuration AS AvgDurationAsInt,
    CONVERT(VARCHAR(10), CAST(ca_aggregate_runtime_stats.AvgDuration AS FLOAT) / 1000) + N' ms' AS AvgDurationAsString,
    ca_aggregate_runtime_stats.LastDuration AS LastDuration,
    CONVERT(VARCHAR(10), CAST(ca_aggregate_runtime_stats.LastDuration AS FLOAT) / 1000) + N' ms' AS LastDurationAsString,
    ca_aggregate_runtime_stats.MinDuration AS MinDuration,
    CONVERT(VARCHAR(10), CAST(ca_aggregate_runtime_stats.MinDuration AS FLOAT) / 1000) + N' ms' AS MinDurationAsString,
    ca_aggregate_runtime_stats.MaxDuration AS MaxDuration,
    CONVERT(VARCHAR(10), CAST(ca_aggregate_runtime_stats.MaxDuration AS FLOAT) / 1000) + N' ms' AS MaxDurationAsString,
    FORMAT(LEN(qsqt.query_sql_text), N'###,###,###0') AS SQLTextLength,
    qsqt.query_sql_text,
    ca_queries_for_plan.total_queries_for_plan AS QueriesForPlan,
    ca_aggregate_runtime_stats.AvgRowCount,
    ca_aggregate_runtime_stats.LastRowCount,
    ca_aggregate_runtime_stats.MaxRowCount,
    ca_aggregate_runtime_stats.MinRowCount,
    ca_aggregate_runtime_stats.AvgCpuTime AS AvgCpuTime,
    CONVERT(VARCHAR(10), CAST(ca_aggregate_runtime_stats.AvgCpuTime AS FLOAT) / 1000) + N' ms' AS AvgCpuTimeAsString,
    ca_aggregate_runtime_stats.LastCpuTime AS LastCpuTime,
    CONVERT(VARCHAR(10), CAST(ca_aggregate_runtime_stats.LastCpuTime AS FLOAT) / 1000) + N' ms' AS LastCpuTimeAsString,
    ca_aggregate_runtime_stats.MinCpuTime AS MinCpuTime,
    CONVERT(VARCHAR(10), CAST(ca_aggregate_runtime_stats.MinCpuTime AS FLOAT) / 1000) + N' ms' AS MinCpuTimeAsString,
    ca_aggregate_runtime_stats.MaxCpuTime AS MaxCpuTime,
    CONVERT(VARCHAR(10), CAST(ca_aggregate_runtime_stats.MaxCpuTime AS FLOAT) / 1000) + N' ms' AS MaxCpuTimeAsString,
    ca_aggregate_runtime_stats.AvgMaxUsedMemory * 0.001 AS AvgMemoryInMegabytesAsInt,
    ca_aggregate_runtime_stats.LastMaxUsedMemory * 0.001 AS LastMemoryInMegabytesAsInt,
    ca_aggregate_runtime_stats.MinMaxUsedMemory * 0.001 AS MinMemoryInMegabytesAsInt,
    ca_aggregate_runtime_stats.MaxMaxUsedMemory * 0.001 AS MaxMemoryInMegabytesAsInt,
    ca_aggregate_runtime_stats.AvgDop AS AvgDegreeOfParallelismAsInt,
    ca_aggregate_runtime_stats.LastDop AS LastDegreeOfParallelismAsInt,
    ca_aggregate_runtime_stats.MinDop AS MinDegreeOfParallelismAsInt,
    ca_aggregate_runtime_stats.MaxDop AS MaxDegreeOfParallelismAsInt,
    ca_aggregate_runtime_stats.AvgLogicalIoReads AS AvgLogicalIoReadsAsInt,
    ca_aggregate_runtime_stats.LastLogicalIoReads AS LastLogicalIoReadsAsInt,
    ca_aggregate_runtime_stats.MinLogicalIoReads AS MinLogicalIoReadAsInt,
    ca_aggregate_runtime_stats.MaxLogicalIoReads AS MaxLogicalIoReadsAsInt,
    ca_aggregate_runtime_stats.AvgLogicalIoWrites AS AvgLogicalIoWritesAsInt,
    ca_aggregate_runtime_stats.LastLogicalIoWrites AS LastLogicalIoWritesAsInt,
    ca_aggregate_runtime_stats.MinLogicalIoWrites AS MinLogicalIoWritesAsInt,
    ca_aggregate_runtime_stats.MaxLogicalIoWrites AS MaxLogicalIoWritesAsInt,
    ca_aggregate_runtime_stats.AvgPhysicalIoReads AS AvgPhysicalIoReadsAsInt,
    ca_aggregate_runtime_stats.LastPhysicalIoReads AS LastPhysicalIoReadsAsInt,
    ca_aggregate_runtime_stats.MinPhysicalIoReads AS MinPhysicalIoReadsAsInt,
    ca_aggregate_runtime_stats.MaxPhysicalIoReads AS MaxPhysicalIoReadsAsInt,
    ca_aggregate_runtime_stats.AvgNumPhysicalIoReads AS AvgNumPhysicalIoReadsAsInt,
    ca_aggregate_runtime_stats.LastNumPhysicalIoReads AS LastNumPhysicalIoReadsAsInt,
    ca_aggregate_runtime_stats.MinNumPhysicalIoReads AS MinNumPhysicalIoReadsAsInt,
    ca_aggregate_runtime_stats.MaxNumPhysicalIoReads AS MaxNumPhysicalIoReadsAsInt,
    CAST(qsp.query_plan AS XML) AS QueryPlan
    INTO #TempQueryStoreData
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
		SELECT CONVERT(INT, SUM(rs.avg_duration)) AS TotalDuration,
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
        TotalExectionsAsString,
        SQLTextLength,
        AvgDurationAsString,
        LastDurationAsString,
        MinDurationAsString,
        MaxDurationAsString,
        DatabaseObject,
        object_id,
        FirstExecutionTime,
        LastExecutionTime,
        query_sql_text,
        QueriesForPlan,
        QueryPlan
        FROM #TempQueryStoreData
        ORDER BY AvgDurationAsInt DESC

    END

    IF @showQueryStoreTotalDuration = 1 BEGIN

        SELECT TOP(@top)
        SPID,
        plan_id,
        query_id,
        TotalExectionsAsString,
        SQLTextLength,
        TotalDurationString AS TotalDurations,
        TotalDurationInFormatAsString AS TotalDurationFormatted,
        DatabaseObject,
        object_id,
        FirstExecutionTime,
        LastExecutionTime,
        query_sql_text AS QueryText,
        QueriesForPlan,
        QueryPlan
        FROM #TempQueryStoreData
        ORDER BY TotalDurationAsInt DESC

    END

    IF @showQueryStoreTotalExecutions = 1 BEGIN

        SELECT TOP(@top)
        SPID,
        plan_id,
        query_id,
        TotalExectionsAsString,
        TotalExectionsAsString,
        SQLTextLength,
        DatabaseObject,
        object_id,
        FirstExecutionTime,
        LastExecutionTime,
        query_sql_text,
        QueriesForPlan,
        QueryPlan
        FROM #TempQueryStoreData
        ORDER BY TotalExectionsAsInt DESC

    END


    IF @showQueryStoreCpu = 1 BEGIN

        SELECT TOP(@top)
        SPID,
        plan_id,
        query_id,
        TotalExectionsAsString,
        SQLTextLength,
        AvgCpuTimeAsString,
        LastCpuTimeAsString,
        MinCpuTimeAsString,
        MaxCpuTimeAsString,
        DatabaseObject,
        object_id,
        FirstExecutionTime,
        LastExecutionTime,
        query_sql_text,
        QueriesForPlan,
        QueryPlan
        FROM #TempQueryStoreData
        ORDER BY AvgCpuTime DESC

    END

    IF @showQueryStoreMemory = 1 BEGIN

        SELECT TOP(@top)
        SPID,
        plan_id,
        query_id,
        TotalExectionsAsString,
        SQLTextLength,
        AvgMemoryInMegabytesAsInt,
        LastMemoryInMegabytesAsInt,
        MinMemoryInMegabytesAsInt,
        MaxMemoryInMegabytesAsInt,
        DatabaseObject,
        object_id,
        FirstExecutionTime,
        LastExecutionTime,
        query_sql_text,
        QueriesForPlan,
        QueryPlan
        FROM #TempQueryStoreData
        ORDER BY AvgMemoryInMegabytesAsInt DESC

    END

    IF @showQueryStoreParallelism = 1 BEGIN

        SELECT TOP(@top)
        SPID,
        plan_id,
        query_id,
        TotalExectionsAsString,
        SQLTextLength,
        AvgDegreeOfParallelismAsInt,
        LastDegreeOfParallelismAsInt,
        MinDegreeOfParallelismAsInt,
        MaxDegreeOfParallelismAsInt,
        DatabaseObject,
        object_id,
        FirstExecutionTime,
        LastExecutionTime,
        query_sql_text,
        QueriesForPlan,
        QueryPlan
        FROM #TempQueryStoreData
        ORDER BY AvgDegreeOfParallelismAsInt DESC

    END

    IF @showQueryStoreIo = 1 BEGIN

        SELECT TOP(@top)
        SPID,
        plan_id,
        query_id,
        TotalExectionsAsString,
        SQLTextLength,
        AvgLogicalIoReadsAsInt,
        LastLogicalIoReadsAsInt,
        MinLogicalIoReadsAsInt,
        MaxLogicalIoReadsAsInt,
        AvgLogicalIoWritesAsInt,
        LastLogicalIoWritesAsInt,
        MinLogicalIoWritesAsInt,
        MaxLogicalIoWritesAsInt,
        AvgPhysicalIoReadsAsInt,
        LastPhysicalIoReadsAsInt,
        MinPhysicalIoReadsAsInt,
        MaxPhysicalIoReadsAsInt,
        AvgNumPhysicalIoReadsAsInt,
        LastNumPhysicalIoReadsAsInt,
        MinNumPhysicalIoReadsAsInt,
        MaxNumPhysicalIoReadsAsInt,
        DatabaseObject,
        object_id,
        FirstExecutionTime,
        LastExecutionTime,
        query_sql_text,
        QueriesForPlan,
        QueryPlan
        FROM #TempQueryStoreData
        ORDER BY AvgLogicalIoReadsAsInt DESC

    END

    DROP TABLE #TempQueryStoreData
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

        -- select scheduler_id, cpu_id, status, is_online 
        -- from sys.dm_os_schedulers 
        -- where status = 'VISIBLE ONLINE'

        -- select * from sysprocesses
        -- -- where status = 'runnable' --comment this out
        -- order by CPU
        -- desc