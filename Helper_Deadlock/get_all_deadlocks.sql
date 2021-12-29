DECLARE @xml XML;
DECLARE @time DATETIME;

SELECT @xml = targ.target_data
     , @time = ses.create_time
FROM sys.dm_xe_session_targets AS targ
     JOIN sys.dm_xe_sessions AS ses
          ON targ.event_session_address = ses.address
WHERE ses.name = 'system_health'
      AND targ.target_name = 'ring_buffer';
SELECT CAST(XEventData.XEvent.value('(data/value)[1]', 'varchar(max)') AS XML)
     , @time
	 , @xml
FROM
(
    SELECT @xml AS TargetData
) AS Data
CROSS APPLY TargetData.nodes('RingBufferTarget/event[@name="xml_deadlock_report"]') AS XEventData(XEvent);


GO;