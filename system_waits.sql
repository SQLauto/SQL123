-- MAAIgnore
DECLARE @selectedTypes BIT = 1;
DECLARE @sortByAverageWaitTime BIT = 1;
DECLARE @waitTasksCount BIT = 0;
DECLARE @findWaits NVARCHAR(MAX) = NULL;

-- DBCC SQLPERF('sys.dm_os_wait_stats', CLEAR);
SELECT
up_time.approximate_restart_date AS ApproximateRestartDate,
wait_type AS Wait_Type,
CONVERT(VARCHAR(100), FLOOR(wait_time_ms/1000.0/60/60/24)) + 'd'
+ ':' + CONVERT(VARCHAR(100), FLOOR(wait_time_ms/1000.0/60/60%24)) + 'h'
+ ':' + CONVERT(VARCHAR(100), FLOOR(wait_time_ms/1000.0/60%60)) + 'm'
+ ':' + CONVERT(VARCHAR(100), FLOOR(wait_time_ms/1000.0)%60)+ 's'
+ ':' + CONVERT(VARCHAR(100), wait_time_ms/10000 % 1000) + 'ms'
AS 'Total Duration',
CONVERT(VARCHAR(100), FLOOR(wait_time_ms/waiting_tasks_count/1000.0/60/60/24)) + 'd'
+ ':' + CONVERT(VARCHAR(100), FLOOR(wait_time_ms/waiting_tasks_count/1000.0/60/60%24)) + 'h'
+ ':' + CONVERT(VARCHAR(100), FLOOR(wait_time_ms/waiting_tasks_count/1000.0/60%60)) + 'm'
+ ':' + CONVERT(VARCHAR(100), FLOOR(wait_time_ms/waiting_tasks_count/1000.0%60)) + 's'
+ ':' + CONVERT(VARCHAR(100), wait_time_ms/waiting_tasks_count/10000 % 1000) + 'ms'
AS 'Average Wait Time',
CASE
	WHEN wait_type = 'RESOURCE_SEMAPHORE' THEN 'Memory Grant'
	WHEN wait_type = 'BACKUPBUFFER' THEN 'Backup Operation Waiting'
	WHEN wait_type = 'BACKUPIO' THEN 'Backup reading/writing from database data files'
	WHEN wait_type = 'LCK_M_RS_U' THEN 'Waiting for Shared-Range Update lock'
	WHEN wait_type = 'ASYNC_IO_COMPLETION' THEN 'Waiting for non-data-file disk I/O to complete(could be backups)'
	WHEN wait_type = 'CXPACKET' THEN 'Parallel Plans Running'
	WHEN wait_type = 'PAGELATCH_UP' THEN 'This wait type is when a thread is waiting for access to a data file page in memory (could be an allocation bitmap page, or tempdb contention) so that it can update the page structure (UP = UPdate mode).'
	WHEN wait_type = 'PAGELATCH_SH' THEN 'This wait type is when a thread is waiting for access to a data file page in memory so that it can read the page structure (SH = SHare mode).'
	WHEN wait_type = 'PAGELATCH_EX' THEN 'This wait type is when a thread is waiting for access to a data file page in memory (usually a page from a table/index, tempdb contention.) so that it can modify the page structure (EX = EXclusive mode).'
	WHEN wait_type = 'LCK_M_SCH_S' THEN 'This wait type is when a thread is waiting to acquire a Schema Stability (also called Schema Share) lock on a resource and there is at least one other lock in an incompatible mode granted on the resource to a different thread.'
	WHEN wait_type = 'LCK_M_X' THEN 'This wait type is when a thread is waiting to acquire an Exclusive lock on a resource and there is at least one other lock in an incompatible mode granted on the resource to a different thread.'
	WHEN wait_type = 'LCK_M_U' THEN 'This wait type is when a thread is waiting to acquire an Update lock on a resource and there is at least one other lock in an incompatible mode granted on the resource to a different thread.'
	WHEN wait_type = 'LCK_M_SCH_M' THEN 'This wait type is when a thread is waiting to acquire a Schema Modification (also called Schema Modify) lock on a resource and there is at least one other lock in an incompatible mode granted on the resource to a different thread.'
	WHEN wait_type = 'RESOURCE_SEMAPHORE_QUERY_COMPILE' THEN 'Occurs when the number of concurrent query compilations reaches a throttling limit. High waits and wait times may indicate excessive compilations, recompiles, or uncachable plans.'
	WHEN wait_type = 'LCK_M_S' THEN 'This wait type is when a thread is waiting to acquire a Shared lock on a resource and there is at least one other lock in an incompatible mode granted on the resource to a different thread.'
	WHEN wait_type = 'PREEMPTIVE_OS_LOADLIBRARY' THEN 'This wait type is when a thread is calling the Windows LoadLibrary function.'
	WHEN wait_type = 'ASYNC_NETWORK_IO' THEN 'Accumulates while requests are waiting on network I/O to complete. A common cause of this wait type is when client applications cannot process data as fast as SQL Server can provide it. When this occurs SQL Server must wait until the client is ready. Other causes include network bottlenecks and sending large volumes of data across the network'
	WHEN wait_type = 'WAIT_ON_SYNC_STATISTICS_REFRESH' THEN 'Synchronous statistics updates.'
	WHEN wait_type = 'DAC_INIT' THEN 'This wait type is when a thread is waiting for the TDS communication protocol to initialize for the Dedicated Admin Connection (DAC) listener.'
	WHEN wait_type = 'MSQL_XP' THEN 'Occurs when a task is waiting for an extended stored procedure to end. SQL Server uses this wait state to detect potential MARS application deadlocks. The wait stops when the extended stored procedure call ends.”)'
	WHEN wait_type = 'PREEMPTIVE_OS_WRITEFILE' THEN 'This wait type is when a thread is calling the Windows WriteFile function.'
	WHEN wait_type = 'PREEMPTIVE_OS_LOOKUPACCOUNTSID' THEN 'This wait type is when a thread is calling the Windows LookupAccountSid function.'
	WHEN wait_type = 'CMEMTHREAD' THEN 'Occurs when a task is waiting on a thread-safe memory object. The wait time might increase when there is contention caused by multiple tasks trying to allocate memory from the same memory object.”)'
	WHEN wait_type = 'PREEMPTIVE_OS_FINDFILE' THEN 'This wait type is a generic wait for when a thread is calling one of several Windows functions related to finding files.'
	WHEN wait_type = 'SQLTRACE_FILE_WRITE_IO_COMPLETION' THEN 'This wait type is when a thread is waiting for a write to a trace file to complete.'
	WHEN wait_type = 'SNI_CRITICAL_SECTION' THEN 'Occurs during internal synchronization within SQL Server networking components.).'
	WHEN wait_type = 'PREEMPTIVE_OS_GETFILEATTRIBUTES' THEN 'This wait type is when a thread is calling the Windows GetFileAttributes function.).'
	WHEN wait_type = 'PERFORMANCE_COUNTERS_RWLOCK' THEN 'This wait type is when a thread is waiting for synchronization on the performance counter structures when adding or removing an instance of a performance counter.'
	WHEN wait_type = 'PREEMPTIVE_FILESIZEGET' THEN 'This wait type is when a thread is calling the Windows GetFileSizeEx function.'
	WHEN wait_type = 'LATCH_SH' THEN 'Occurs when waiting for a SH (share) latch. This does not include buffer latches or transaction mark latches.'
	WHEN wait_type = 'LCK_M_IX' THEN 'Occurs when a task is waiting to acquire an Intent Exclusive (IX) lock.'
	WHEN wait_type = 'LCK_M_IU' THEN 'Occurs when a task is waiting to acquire an Intent Update (IU) lock.'
	WHEN wait_type = 'PAGEIOLATCH_SH' THEN 'Occurs when a task is waiting on a latch for a buffer that is in an I/O request. The latch request is in Shared mode. Long waits may indicate problems with the disk subsystem.”).'
	WHEN wait_type = 'PAGEIOLATCH_EX' THEN 'Occurs when a task is waiting on a latch for a buffer that is in an I/O request. The latch request is in Exclusive mode. Long waits may indicate problems with the disk subsystem.”).'
	ELSE 'Unknown'
END As WaitDescription,
FORMAT(waiting_tasks_count, N'N0') AS WaitingTasksCount,
TRIM(CAST(CAST(wait_time_ms * 100.0/SUM(wait_time_ms) OVER() AS DECIMAL(10,2)) AS NCHAR(6))) + '%' AS Percentage_WaitTime
FROM sys.dm_os_wait_stats
CROSS APPLY 
(
	SELECT DATEADD(ms, AVG(-ws.wait_time_ms), GETDATE()) AS approximate_restart_date
	FROM sys.dm_os_wait_stats ws
	WHERE wait_type IN ('DIRTY_PAGE_POLL','HADR_FILESTREAM_IOMGR_IOCOMPLETION','LAZYWRITER_SLEEP','LOGMGR_QUEUE','REQUEST_FOR_DEADLOCK_SEARCH','XE_DISPATCHER_WAIT','XE_TIMER_EVENT')
) up_time
WHERE 
(
    (@findWaits IS NOT NULL AND wait_type IN(SELECT Value FROM STRING_SPLIT (@findWaits, ';' )))
    OR 
    (
        @findWaits IS NULL
        AND 
        (
            ISNULL(@selectedTypes, 0) = 0
            OR wait_type NOT IN
            (
                N'BROKER_EVENTHANDLER',
                N'BROKER_RECEIVE_WAITFOR',
                N'BROKER_TASK_STOP',
                N'BROKER_TO_FLUSH',
                N'BROKER_TRANSMITTER',
                N'CHECKPOINT_QUEUE',
                N'CHKPT',
                N'CLR_AUTO_EVENT',
                N'CLR_MANUAL_EVENT',
                N'CLR_SEMAPHORE',
                N'CXCONSUMER',
                N'DBMIRROR_DBM_EVENT',
                N'DBMIRROR_DBM_MUTEX',
                N'DBMIRROR_EVENTS_QUEUE',
                N'DBMIRROR_WORKER_QUEUE',
                N'DBMIRRORING_CMD',
                N'DIRTY_PAGE_POLL',
                N'DISPATCHER_QUEUE_SEMAPHORE',
                N'EXECSYNC',
                N'FSAGENT',
                N'FT_IFTS_SCHEDULER_IDLE_WAIT',
                N'FT_IFTSHC_MUTEX',
                N'HADR_CLUSAPI_CALL',
                N'HADR_FILESTREAM_IOMGR_IOCOMPLETION',
                N'HADR_LOGCAPTURE_WAIT',
                N'HADR_NOTIFICATION_DEQUEUE',
                N'HADR_TIMER_TASK',
                N'HADR_WORK_QUEUE',
                N'LAZYWRITER_SLEEP',
                N'LOGMGR_QUEUE',
                N'MEMORY_ALLOCATION_EXT',
                N'ONDEMAND_TASK_QUEUE',
                N'PARALLEL_REDO_DRAIN_WORKER',
                N'PARALLEL_REDO_LOG_CACHE',
                N'PARALLEL_REDO_TRAN_LIST',
                N'PARALLEL_REDO_WORKER_SYNC',
                N'PARALLEL_REDO_WORKER_WAIT_WORK',
                N'PREEMPTIVE_HADR_LEASE_MECHANISM',
                N'PREEMPTIVE_OS_FLUSHFILEBUFFERS',
                N'PREEMPTIVE_OS_AUTHENTICATIONOPS',
                N'PREEMPTIVE_OS_AUTHORIZATIONOPS',
                N'PREEMPTIVE_OS_COMOPS',
                N'PREEMPTIVE_OS_CREATEFILE',
                N'PREEMPTIVE_OS_CRYPTOPS',
                N'PREEMPTIVE_OS_DEVICEOPS',
                N'PREEMPTIVE_OS_FILEOPS',
                N'PREEMPTIVE_OS_GENERICOPS',
                N'PREEMPTIVE_OS_LIBRARYOPS',
                N'PREEMPTIVE_OS_PIPEOPS',
                N'PREEMPTIVE_OS_QUERYREGISTRY',
                N'PREEMPTIVE_OS_VERIFYTRUST',
                N'PREEMPTIVE_OS_WAITFORSINGLEOBJECT',
                N'PREEMPTIVE_OS_WRITEFILEGATHER',
                N'PREEMPTIVE_SP_SERVER_DIAGNOSTICS',
                N'PREEMPTIVE_XE_CALLBACKEXECUTE',
                N'PREEMPTIVE_XE_DISPATCHER',
                N'PREEMPTIVE_XE_GETTARGETSTATE',
                N'PREEMPTIVE_XE_SESSIONCOMMIT',
                N'PREEMPTIVE_XE_TARGETFINALIZE',
                N'PREEMPTIVE_XE_TARGETINIT',
                N'PWAIT_ALL_COMPONENTS_INITIALIZED',
                N'PWAIT_EXTENSIBILITY_CLEANUP_TASK',
                N'PWAIT_DIRECTLOGCONSUMER_GETNEXT',
                N'QDS_ASYNC_QUEUE',
                N'QDS_CLEANUP_STALE_QUERIES_TASK_MAIN_LOOP_SLEEP',
                N'QDS_PERSIST_TASK_MAIN_LOOP_SLEEP',
                N'QDS_SHUTDOWN_QUEUE',
                N'REDO_THREAD_PENDING_WORK',
                N'REQUEST_FOR_DEADLOCK_SEARCH',
                N'RESOURCE_QUEUE',
                N'SERVER_IDLE_CHECK',
                N'SOS_WORK_DISPATCHER',
                N'SLEEP_BPOOL_FLUSH',
                N'SLEEP_DBSTARTUP',
                N'SLEEP_DCOMSTARTUP',
                N'SLEEP_MASTERDBREADY',
                N'SLEEP_MASTERMDREADY',
                N'SLEEP_MASTERUPGRADED',
                N'SLEEP_MSDBSTARTUP',
                N'SLEEP_SYSTEMTASK',
                N'SLEEP_TASK',
                N'SLEEP_TEMPDBSTARTUP',
                N'SNI_HTTP_ACCEPT',
                N'SP_SERVER_DIAGNOSTICS_SLEEP',
                N'SQLTRACE_BUFFER_FLUSH',
                N'SQLTRACE_INCREMENTAL_FLUSH_SLEEP',
                N'SQLTRACE_WAIT_ENTRIES',
                N'STARTUP_DEPENDENCY_MANAGER',
                N'UCS_SESSION_REGISTRATION',
                N'VDI_CLIENT_OTHER',
                N'WAIT_FOR_RESULTS',
                N'WAIT_XTP_CKPT_CLOSE',
                N'WAIT_XTP_HOST_WAIT',
                N'WAIT_XTP_OFFLINE_CKPT_NEW_LOG',
                N'WAIT_XTP_RECOVERY',
                N'WAITFOR',
                N'WAITFOR_TASKSHUTDOWN',
                N'XE_BUFFERMGR_ALLPROCESSED_EVENT',
                N'XE_DISPATCHER_JOIN',
                N'XE_TIMER_EVENT',
                N'XE_DISPATCHER_WAIT',
                N'XE_LIVE_TARGET_TVF'
            ) 
        )
    )
)
AND wait_time_ms >= 1
-- ORDER BY wait_time_ms DESC
ORDER BY
CASE WHEN ISNULL(@sortByAverageWaitTime, 0) = 1 THEN wait_time_ms/waiting_tasks_count END DESC,
CASE WHEN ISNULL(@waitTasksCount, 0) = 1 THEN waiting_tasks_count END DESC,
wait_time_ms DESC