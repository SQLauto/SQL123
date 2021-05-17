--1. Value of error log file you want to read: 0 = current, 1 = Archive #1, 2 = Archive #2, etc...
--2. Log file type: 1 or NULL = error log, 2 = SQL Agent log
--3. Search string 1: String one you want to search for
--4. Search string 2: String two you want to search for to further refine the results
--5. Search from start time
--6. Search to end time
--7. Sort order for results: N'asc' = ascending, N'desc' = descending

DECLARE @instanceName NVARCHAR(4000) = NULL,
@archiveID INT = 0,
@typeOfLogs INT = 1, /* 1 = error log, 2 = SQL Agent log */
@filter1Text NVARCHAR(4000) = NULL,
@filter2Text NVARCHAR(4000) = NULL,
@firstEntry DATETIME = NULL,
@sortOrder NVARCHAR(4000) = N'desc',
@lastEntry DATETIME = NULL;
EXEC xp_readerrorlog @archiveID, @typeOfLogs, @filter1Text, @filter2Text, @firstEntry, @lastEntry, @sortOrder, @instanceName 

  