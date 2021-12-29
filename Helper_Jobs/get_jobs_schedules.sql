SELECT jobs.job_id
     , jobs.name AS job_name
     , jobs.description AS job_desc
	 , CASE	
			WHEN  jobs.enabled=1 THEN 'True'
			ELSE 'FALSE'
	   END AS job_enabled
	 , jobschedules.next_run_date
	 , jobschedules.next_run_time
	 
FROM msdb.dbo.sysjobs jobs
     JOIN msdb.dbo.sysjobschedules jobschedules
          ON jobs.job_id = jobschedules.job_id
ORDER BY jobs.enabled DESC;

SELECT jobs.job_id
     , jobs.name AS job_name
     , jobs.description AS job_desc
	 , CASE	
			WHEN  jobs.enabled=1 THEN 'True'
			ELSE 'FALSE'
	   END AS job_enabled
	 , jobschedules.next_run_date
	 , jobschedules.next_run_time
	 , schedules.name AS schedule_name
	 , jobs.owner_sid  AS owner_id
     --, *
FROM msdb.dbo.sysjobs AS jobs
     JOIN msdb.dbo.sysjobschedules AS jobschedules
          ON jobs.job_id = jobschedules.job_id
     JOIN msdb.dbo.sysschedules schedules
          ON jobschedules.schedule_id = schedules.schedule_id
ORDER BY jobs.enabled DESC;