
SELECT
ws.WaitType,  
FORMAT(ws.WaitTimeMS/1000, N'N0') AS WaitTimeInSeconds,
FORMAT(FLOOR(CAST(ws.WaitTimeMS AS FLOAT)/CAST(wst.TotalWaitTimeMS AS FLOAT)*100), N'N0') + '%' AS '%'
FROM 
(
	SELECT ws.wait_type AS WaitType, SUM(ws.wait_time_ms) AS WaitTimeMS
	FROM sys.dm_os_wait_stats ws -- Azure it's FROM sys.dm_db_wait_stats os
	WHERE ws.wait_type NOT IN
	(
		'CLR_SEMAPHORE', 'LAZYWRITER_SLEEP', 'RESOURCE_QUEUE', 
		'SLEEP_TASK', 'SLEEP_SYSTEMTASK', 'SQLTRACE_BUFFER_FLUSH', 'WAITFOR', 
		'CLR_AUTO_EVENT', 'CLR_MANUAL_EVENT'
	) 
	GROUP BY ws.wait_type
) ws
CROSS APPLY (SELECT SUM(wait_time_ms) AS TotalWaitTimeMS FROM sys.dm_os_wait_stats) wst
WHERE ws.WaitTimeMS / 1000 > 0
ORDER BY ws.WaitTimeMS DESC
