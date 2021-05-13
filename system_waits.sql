DECLARE @selectedTypes BIT = 1;
DECLARE @sortByAverageWaitTime BIT = 1;
DECLARE @waitTasksCount BIT = 0;

-- DBCC SQLPERF('sys.dm_os_wait_stats', CLEAR);
SELECT
up_time.approximate_restart_date AS ApproximateRestartDate,
wait_type AS Wait_Type,
CONVERT(VARCHAR(100), FLOOR(wait_time_ms/1000.0/60/60/24)) + 'd'
+ ':' + CONVERT(VARCHAR(100), FLOOR(wait_time_ms/1000.0/60/60%24)) + 'h'
+ ':' + CONVERT(VARCHAR(100), FLOOR(wait_time_ms/1000.0/60%60)) + 'm'
+ ':' + CONVERT(VARCHAR(100), FLOOR(wait_time_ms/1000.0)%60)+ 's'
AS 'Total Duration',
CONVERT(VARCHAR(100), FLOOR(wait_time_ms/waiting_tasks_count/1000.0/60/60/24)) + 'd'
+ ':' + CONVERT(VARCHAR(100), FLOOR(wait_time_ms/waiting_tasks_count/1000.0/60/60%24)) + 'h'
+ ':' + CONVERT(VARCHAR(100), FLOOR(wait_time_ms/waiting_tasks_count/1000.0/60%60)) + 'm'
+ ':' + CONVERT(VARCHAR(100), FLOOR(wait_time_ms/waiting_tasks_count/1000.0%60)) + 's'
AS 'Average Wait Time',
CASE
	WHEN wait_type = 'RESOURCE_SEMAPHORE' THEN 'Memory Grant'
	WHEN wait_type = 'BACKUPBUFFER' THEN 'Backup Operation Waiting'
	WHEN wait_type = 'BACKUPIO' THEN 'Backup reading/writing from database data files'
	WHEN wait_type = 'LCK_M_RS_U' THEN 'Waiting for Shared-Range Update lock'
	WHEN wait_type = 'ASYNC_IO_COMPLETION' THEN 'Waiting for non-data-file disk I/O to complete(could be backups)'
	WHEN wait_type = 'CXPACKET' THEN 'Parallel Plans Running'
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
    ISNULL(@selectedTypes, 0) = 0
    OR
    wait_type NOT IN
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
AND wait_time_ms >= 1
-- ORDER BY wait_time_ms DESC
ORDER BY
CASE WHEN ISNULL(@sortByAverageWaitTime, 0) = 1 THEN wait_time_ms/waiting_tasks_count END DESC,
CASE WHEN ISNULL(@waitTasksCount, 0) = 1 THEN waiting_tasks_count END DESC,
wait_time_ms DESC