DECLARE @version INT;
SET @version = (@@microsoftversion / 0x1000000)&0xff;
IF(@version = 10)
    BEGIN
        WITH SystemHealth
             AS (SELECT CAST(target_data AS XML) AS TargetData
                 FROM sys.dm_xe_session_targets AS st
                      JOIN sys.dm_xe_sessions AS s
                           ON s.address = st.event_session_address
                 WHERE name = 'system_health'
                       AND st.target_name = 'ring_buffer')
             SELECT XEventData.XEvent.value('@timestamp', 'datetime2(3)') AS CreationDate
				  , XEventData.XEvent.value('(data/value)[1]', 'VARCHAR(MAX)') AS DeadLockGraph
			 FROM SystemHealth
				  CROSS APPLY TargetData.nodes('//RingBufferTarget/event') AS XEventData(XEvent)
			 WHERE XEventData.XEvent.value('@name', 'varchar(4000)') = 'xml_deadlock_report'
			 ORDER BY CreationDate DESC;
END;
IF(@version > 10)
    BEGIN
        WITH SystemHealth
             AS (SELECT CAST(target_data AS XML) AS TargetData
                 FROM sys.dm_xe_session_targets AS st
                      JOIN sys.dm_xe_sessions AS s
                           ON s.address = st.event_session_address
                 WHERE name = 'system_health'
                       AND st.target_name = 'ring_buffer')
             SELECT XEventData.XEvent.query('(data/value/deadlock)[1]') AS DeadLockGraph
             FROM SystemHealth
                  CROSS APPLY TargetData.nodes('//RingBufferTarget/event') AS XEventData(XEvent)
             WHERE XEventData.XEvent.value('@name', 'varchar(4000)') = 'xml_deadlock_report';
END;