

;with SpaceInfo(ObjectId, IndexId, TableName, IndexName,Rows, TotalSpaceMB, UsedSpaceMB)
as
( 
    select  
        t.object_id as [ObjectId]
        ,i.index_id as [IndexId]
        ,s.name + '.' + t.Name as [TableName]
        ,i.name as [Index Name]
        ,sum(p.[Rows]) as [Rows]
        ,sum(au.total_pages) * 8 / 1024 as [Total Space MB]
        ,sum(au.used_pages) * 8 / 1024 as [Used Space MB]
    from    
        sys.tables t with (nolock) join 
            sys.schemas s with (nolock) on 
                s.schema_id = t.schema_id
            join sys.indexes i with (nolock) on 
                t.object_id = i.object_id
            join sys.partitions p with (nolock) on 
                i.object_id = p.object_id and 
                i.index_id = p.index_id
            cross apply
            (
                select 
                    sum(a.total_pages) as total_pages
                    ,sum(a.used_pages) as used_pages
                from sys.allocation_units a with (nolock)
                where p.partition_id = a.container_id 
            ) au
    where   
        i.object_id > 255
    group by
        t.object_id, i.index_id, s.name, t.name, i.name
),
IndexUse_CTE AS (
	select 
		s.Name + N'.' + t.name as [TableName]
		,i.name as [Index] 
		,i.is_disabled
		,i.is_unique as [IsUnique]
		
		,ius.user_seeks as [Seeks], 
		ius.user_scans as [Scans]
		,ius.user_lookups as [Lookups]

		,ius.user_seeks + ius.user_scans + ius.user_lookups as [Reads]

		,ius.user_updates as [Updates], ius.last_user_seek as LastSeek
		,ius.last_user_scan as LastScan, ius.last_user_lookup as LastLookup
		,ius.last_user_update as [Last Update]

	from 
		sys.tables t with (nolock) join sys.indexes i with (nolock) on
			t.object_id = i.object_id
		join sys.schemas s with (nolock) on 
			t.schema_id = s.schema_id
		left outer join sys.dm_db_index_usage_stats ius on
			ius.database_id = db_id() and
			ius.object_id = i.object_id and 
			ius.index_id = i.index_id
	--WHERE ius.user_seeks + ius.user_scans + ius.user_lookups=0
)
select 
    info.ObjectId, info.IndexId, info.TableName, info.IndexName, info.Rows, info.TotalSpaceMB, 	1.0*info.TotalSpaceMB/1024 TotalSpaceGB,info.UsedSpaceMB,info.TotalSpaceMB - info.UsedSpaceMB as [ReservedSpaceMB]
	, usage.Reads, usage.Updates, usage.LastSeek, usage.LastScan, usage.LastLookup

from 
    SpaceInfo info 
		inner join IndexUse_CTE usage on usage.TableName = info.TableName
WHERE usage.[Index] = 'BIS Brabant Mobiel$Cust_ Ledger Entry'
order by
    TotalSpaceMB desc
option (recompile)