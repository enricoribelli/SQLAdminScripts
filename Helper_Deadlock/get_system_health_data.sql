-- FILL TEMP TABLE https://github.com/Apress/healthy-sql
-- https://www.sqlshack.com/understanding-the-xml-description-of-the-deadlock-graph-in-sql-server/
DECLARE @ResetTempTable AS BIT = 0

IF(@ResetTempTable=1)
BEGIN
	IF OBJECT_ID('tempdb..#deadlock') IS NOT NULL DROP TABLE #deadlock
	CREATE TABLE #deadlock
	(
		  DeadlockID    INT IDENTITY PRIMARY KEY CLUSTERED
		, DeadlockDateTime  datetime
		, DeadlockGraph XML
	);

	/* Using the following T-SQL, you can examine the  Deadlock Graph  , and you can also return details of the statements involved in the deadlock. */
	WITH SystemHealth
		 AS (SELECT CAST(target_data AS XML) AS SessionXML
			 FROM sys.dm_xe_session_targets AS st
				  INNER JOIN sys.dm_xe_sessions AS s
					   ON s.address = st.event_session_address
			 WHERE name = 'system_health')
	INSERT #deadlock (DeadlockDateTime,DeadlockGraph)
	SELECT Deadlock.value('@timestamp', 'datetime') AS DeadlockDateTime , CAST(Deadlock.value('(data/value)[1]', 'varchar(max)') AS XML) AS DeadlockGraph
	FROM SystemHealth AS s
		CROSS APPLY SessionXML.nodes('//RingBufferTarget/event') AS t(Deadlock)
	WHERE Deadlock.value('@name', 'nvarchar(128)') = 'xml_deadlock_report';

END;


WITH 
Victims AS (
	SELECT ID = Victims.List.value('@id', 'varchar(50)')
	FROM #deadlock tbl
	CROSS APPLY tbl.DeadlockGraph.nodes('//deadlock/victim-list/victimProcess') AS Victims(List)
	),
Process AS (
	SELECT tbl.DeadlockID
		,CONVERT(BIT, CASE
						WHEN Deadlock.Process.value('@id', 'varchar(50)') = ISNULL(Deadlock.Process.value('../../@victim', 'varchar(50)'), victimsTbl.ID) THEN 1
						ELSE 0
					END) AS [Victim]
		, [LockMode] = Deadlock.Process.value('@lockMode', 'varchar(10)')
		, [ProcessID] = Process.ID --Deadlock.Process.value('@id', 'varchar(50)'), 
		, [Status] = Deadlock.Process.value('@Status', 'varchar(200)') -- The status of the process. I.e.:Suspended,Dormant,Running,Background,Rollback,Pending,Runnable,Spinloop
		, [KPID] = Deadlock.Process.value('@kpid', 'int') -- kernel-process id / thread ID number
		, [SPID] = Deadlock.Process.value('@spid', 'int') -- system process id (connection to sql) 
		, [SBID] = Deadlock.Process.value('@sbid', 'int') -- system batch id / request_id (a query that a SPID is running) 
		, [ECID] = Deadlock.Process.value('@ecid', 'int') -- execution context ID (a worker thread running part of a query) 
		, [IsolationLevel] = Deadlock.Process.value('@isolationlevel', 'varchar(200)')
		, [WaitResource] = Deadlock.Process.value('@waitresource', 'varchar(200)')
		, [LogUsed] = Deadlock.Process.value('@logused', 'int')
		, [ClientApp] = Deadlock.Process.value('@clientapp', 'varchar(100)')
		, [HostName] = Deadlock.Process.value('@hostname', 'varchar(20)')
		, [LoginName] = Deadlock.Process.value('@loginname', 'varchar(20)')
		, [TransactionTime] = Deadlock.Process.value('@lasttranstarted', 'datetime')
		, [BatchStarted] = Deadlock.Process.value('@lastbatchstarted', 'datetime')
		, [BatchCompleted] = Deadlock.Process.value('@lastbatchcompleted', 'datetime')
		, [InputBuffer] = Input.Buffer.query('.')
		, es.ExecutionStack
		, Execution.Frame.value('.', 'varchar(max)') AS [QueryStatement]
		, ProcessQty = SUM(1) OVER(PARTITION BY tbl.DeadlockID)
		, TranCount = Deadlock.Process.value('@trancount', 'int')
		, tbl.[DeadlockGraph]
		, [Currentdb] = Deadlock.Process.value('@currentdb', 'int') -- execution context ID (a worker thread running part of a query)		, 
	FROM #deadlock tbl
		CROSS APPLY tbl.DeadlockGraph.nodes('//deadlock/process-list/process') AS Deadlock(Process)
		CROSS APPLY (SELECT Deadlock.Process.value('@id', 'varchar(50)')) AS Process(ID)
		LEFT JOIN Victims AS victimsTbl ON Process.ID = victimsTbl.ID
		CROSS APPLY Deadlock.Process.nodes('inputbuf') AS Input(Buffer)
		CROSS APPLY Deadlock.Process.nodes('executionStack') AS Execution(Frame) 
		CROSS APPLY (-- get the data from the executionStack node as XML 
			SELECT ExecutionStack = (
				SELECT ProcNumber = ROW_NUMBER() OVER(PARTITION BY tbl.DeadlockID
																, Deadlock.Process.value('@id', 'varchar(50)')
																, Execution.Stack.value('@procname', 'sysname')
																, Execution.Stack.value('@code', 'varchar(MAX)')
			ORDER BY
				(
					SELECT 1
				))
					, ProcName = Execution.Stack.value('@procname', 'sysname')
					, Line = Execution.Stack.value('@line', 'int')
					, SQLHandle = Execution.Stack.value('@sqlhandle', 'varchar(64)')
					, Code = LTRIM(RTRIM(Execution.Stack.value('.', 'varchar(MAX)')))
				FROM Execution.Frame.nodes('frame') AS Execution(Stack)
				ORDER BY ProcNumber FOR XML PATH('frame'), ROOT('executionStack'), TYPE
			)
		) AS es
),
Locks AS 
( 
	-- Merge all of the lock information together. 
	SELECT  tbl.DeadlockID, 
		MainLock.Process.value('@id', 'varchar(100)') AS LockID, 
		OwnerList.Owner.value('@id', 'varchar(200)') AS LockProcessId, 
		REPLACE(MainLock.Process.value('local-name(.)', 'varchar(100)'), 'lock', '') AS 
		LockEvent, 
		MainLock.Process.value('@objectname', 'sysname') AS ObjectName, 
		OwnerList.Owner.value('@mode', 'varchar(10)') AS LockMode, 
		MainLock.Process.value('@dbid', 'INTEGER') AS Database_id, 
		MainLock.Process.value('@associatedObjectId', 'BIGINT') AS AssociatedObjectId, 
		MainLock.Process.value('@WaitType', 'varchar(100)') AS WaitType, 
		WaiterList.Owner.value('@id', 'varchar(200)') AS WaitProcessId, 
		WaiterList.Owner.value('@mode', 'varchar(10)') AS WaitMode 
	FROM #deadlock tbl
		CROSS APPLY tbl.DeadlockGraph.nodes('//deadlock/resource-list') AS Lock (list) 
		CROSS APPLY Lock.list.nodes('*') AS MainLock (Process) 
		OUTER APPLY MainLock.Process.nodes('owner-list/owner') AS OwnerList (Owner) 
		CROSS APPLY MainLock.Process.nodes('waiter-list/waiter') AS WaiterList (Owner) 
	),
Jobs AS (
	SELECT 'SQLAgent - TSQL JobStep (Job 0x' + CONVERT(CHAR(32), CAST(job.job_id AS BINARY(16)), 2) + ' : Step ' + CAST(jobstep.step_id AS VARCHAR(3)) + ')' AS ProgramName
         , CAST(job.job_id AS BINARY(16)) binary_job_id
         , job.job_id
         , job.name
		 , jobstep.step_name
    FROM msdb.dbo.sysjobs AS job
         INNER JOIN msdb.dbo.sysjobsteps AS jobstep ON job.job_id = jobstep.job_id
)
-- EOF WITH 
-- get the columns in the desired order 
SELECT p.DeadlockID
     , p.Victim
     , p.BatchStarted
     , p.BatchCompleted
	 , p.Status
     , p.ProcessQty
     , ProcessNbr = DENSE_RANK() OVER(PARTITION BY p.DeadlockId ORDER BY p.ProcessID)
     , p.LockMode
     , LockedObject = NULLIF(l.ObjectName, '')
     , l.database_id
     , l.AssociatedObjectId
     , LockProcess = p.ProcessID
     , p.KPID
     , p.SPID
     , p.SBID
     , p.ECID
     , p.TranCount
     , l.LockEvent
     , LockedMode = l.LockMode
     , l.WaitProcessID
     , l.WaitMode
     , p.WaitResource
     , l.WaitType
     , p.IsolationLevel
     , p.LogUsed
     , p.ClientApp
	 , j.name JobName
	 , j.step_name JobStepName
     , p.HostName
     , p.LoginName
	 , ISNULL(NULL,DB_NAME(p.Currentdb)) AS CurrentdbName
     , p.TransactionTime
     , p.QueryStatement
     , p.InputBuffer
     , p.DeadlockGraph
     , p.ExecutionStack
FROM Process AS p
     LEFT JOIN Locks AS l
          ON p.DeadlockID = l.DeadlockID
             AND p.ProcessID = l.LockProcessID
	 LEFT JOIN Jobs AS j ON j.ProgramName = p.ClientApp
ORDER BY 
		  p.BatchStarted DESC
		, p.DeadlockId
		, p.Victim DESC
		, p.ProcessId;

