DECLARE @DatabaseCollation sysname = 'Latin1_General_CI_AS';
DECLARE @object_id int;


/************************************************************************************************************************************
*   Iterate over all the tables that have at least one colmun where collation doesn't match the database default.                   *
*   Also checks for PRIMARY KEY, UNIQUE, and (referencing) FOREIGN KEY constraints, indexes, and manually created statistics.       *
*   (Note that the counts are not accurate counts due to duplication, these should only be tested for zero or non-zero)             *
************************************************************************************************************************************/
SELECT      t.object_id,
            OBJECT_SCHEMA_NAME(t.object_id) AS schemaname,
            OBJECT_NAME(t.object_id)        AS tablename,
            COUNT(kc.object_id)             AS has_key_constraint,
            COUNT(ic.index_id)              AS has_index,
            COUNT(fk.constraint_object_id)  AS has_foreign_key,
            COUNT(st.stats_id)              AS has_stats,
            COUNT(uq.object_id)             AS has_unique_constraint,
			COUNT(cc.object_id)				AS has_check_constraints
FROM        sys.tables              AS t
	INNER JOIN  sys.columns             AS c
	   ON       c.object_id         = t.object_id
	   AND      (c.collation_name    <> @DatabaseCollation)-- Table needs to have columns with "wrong" collation
	INNER JOIN  sys.types               AS ty
	   ON       ty.system_type_id   = c.system_type_id
	   AND      ty.name             <> N'sysname' -- Exclusion retained from Philip C's original script
	LEFT JOIN   sys.index_columns       AS ic -- Find indexes on any of the affected columns
	  ON        ic.object_id        = c.object_id
	  AND       ic.column_id        = c.column_id
	LEFT JOIN   sys.key_constraints     AS kc -- Find primary key constraints related to an affected index
	  ON        kc.parent_object_id = c.object_id
	  AND       kc.unique_index_id  = ic.index_id
	  AND       kc.type             = 'PK'
	LEFT JOIN   sys.key_constraints     AS uq -- Find unique constraints related to an affected index
	  ON        uq.parent_object_id = c.object_id
	  AND       uq.unique_index_id  = ic.index_id
	  AND       uq.type             = 'UQ'
	LEFT JOIN   sys.foreign_key_columns AS fk -- Find foreign key constraints on any of the affected columns
	  ON        fk.parent_object_id = c.object_id
	  AND       fk.parent_column_id = c.column_id
	LEFT JOIN   sys.stats_columns       AS st -- Find statistics on any of the affected columns
	  ON        st.object_id        = c.object_id
	  AND       st.column_id        = c.column_id
	  AND       st.stats_column_id  <> 1 -- Retained from Philip C's original script, no idea why this is in the query
	LEFT JOIN sys.check_constraints AS cc -- Find check_constraints on any of the affected columns
	  ON cc.parent_object_id = c.object_id
	  AND cc.parent_column_id = c.column_id
WHERE       t.is_ms_shipped = 0 -- Exclude Microsoft-shipped tables
	and OBJECT_NAME(t.object_id) = 'CP_AM_SENDNOTES'
GROUP BY    t.object_id;

SET @object_id = 773577794;

DECLARE @SchemaName             sysname = 'dbo',
        @TableName              sysname = 'CP_AM_SENDNOTES',
        @IndexName              sysname,
        @ColumnName             sysname;
 SELECT      'AlterCollation',
	
	IIF(c.max_length>0, c.max_length/2, '-'),
	c.max_length,
    N'ALTER TABLE ' + QUOTENAME(@SchemaName) + N'.' + QUOTENAME(@TableName) + N' ALTER COLUMN '
    + QUOTENAME(c.name) + ' '
    + CASE WHEN ty.name = N'ntext' THEN ty.name + N' COLLATE ' + @DatabaseCollation + ' '
			WHEN ty.name = N'text' THEN ty.name + N' COLLATE ' + @DatabaseCollation + ' '
            ELSE ty.name + N'(' + CASE 
									WHEN c.max_length = -1 THEN N'MAX'
                                    ELSE CASE 
											WHEN ty.name in (N'nvarchar',N'nchar') THEN CAST(c.max_length / 2 AS nvarchar(20))
                                                ELSE CAST(c.max_length AS nvarchar(20))
                                            END
                                    END + N') COLLATE ' + @DatabaseCollation
        END + CASE WHEN c.is_nullable = 1 THEN N' NULL;' ELSE N' NOT NULL;' END
FROM        sys.columns AS c
	INNER JOIN  sys.types   AS ty
ON       ty.system_type_id = c.system_type_id
	AND      ty.name           <> N'sysname'
WHERE       c.object_id = @object_id
	--AND         c.collation_name    <> @DatabaseCollation;
	return

/************************************************************************************************************************************
*   If the table has affected indexes, this creates the drop and recreate index scripts                                             *
************************************************************************************************************************************/
-- @has_index > 0
SELECT  ix.index_id,
        ix.name,
        CASE WHEN ix.is_unique = 1 THEN N'UNIQUE ' ELSE N'' END,
        ix.type_desc,
        CASE WHEN ix.is_padded = 1
                    THEN N'PAD_INDEX = ON, '
                ELSE N'PAD_INDEX = OFF, '
        END + CASE WHEN ix.allow_page_locks = 1
                        THEN N'ALLOW_PAGE_LOCKS = ON, '
                    ELSE N'ALLOW_PAGE_LOCKS = OFF, '
                END + CASE WHEN ix.allow_row_locks = 1
                                THEN N'ALLOW_ROW_LOCKS = ON, '
                            ELSE N'ALLOW_ROW_LOCKS = OFF, '
                    END + CASE WHEN INDEXPROPERTY(ix.object_id, ix.name, 'IsStatistics') = 1
                                    THEN N'STATISTICS_NORECOMPUTE = ON, '
                                ELSE N'STATISTICS_NORECOMPUTE = OFF, '
                            END + CASE WHEN ix.ignore_dup_key = 1
                                            THEN N'IGNORE_DUP_KEY = ON, '
                                        ELSE N'IGNORE_DUP_KEY = OFF, '
                                END + N'SORT_IN_TEMPDB = OFF, FILLFACTOR ='
        + CASE WHEN ix.fill_factor = 0
                    THEN CAST(100 AS nvarchar(3))
                ELSE CAST(ix.fill_factor AS nvarchar(3))
            END                            AS IndexOptions,
        ix.is_disabled,
        FILEGROUP_NAME(ix.data_space_id) AS FileGroupName
FROM    sys.indexes AS ix
WHERE   ix.object_id        = @object_id
	AND     ix.type                 <> 0 -- Exclude heaps
	AND     ix.is_primary_key       = 0 -- Exclude primary key constraints (handled separately)
	AND     ix.is_unique_constraint = 0 -- Exclude unique constraints (handled separately)
	AND     EXISTS (SELECT      *   -- Has to constrain at least one column with wrong collation
					FROM        sys.index_columns AS ic
					INNER JOIN  sys.columns       AS c
						ON       c.object_id       = ic.object_id
						AND      c.column_id       = ic.column_id
						AND      c.collation_name  <> @DatabaseCollation
					INNER JOIN  sys.types         AS ty
						ON       ty.system_type_id = c.system_type_id
						AND      ty.name           <> N'sysname'
					WHERE       ic.index_id = ix.index_id
					AND         ic.object_id        = ix.object_id);


/************************************************************************************************************************************
*   If the table has an affected primary key constraint, this creates the drop and recreate constraint script                       *
*   this has been taken and adapted from a script found online created by Jayakumaur R                                              *
************************************************************************************************************************************/
-- @has_key_constraint > 0
--'DropPrimaryKey',
--'AddPrimaryKey',
SELECT      	
	'@has_key_constraint > 0',
	kc.object_id                                                                          AS constid,
    kc.name                                                                               AS constraint_name,   -- PK name
    QUOTENAME(c.name) + CASE WHEN ic.is_descending_key = 1 THEN N' DESC' ELSE N' ASC' END AS pk_col,
    ic.key_ordinal,
    i.name                                                                                AS index_name,
    i.type_desc                                                                           AS index_type,
    QUOTENAME(fg.name)                                                                    AS filegroup_name,
    N' WITH (PAD_INDEX = ' + CASE WHEN i.is_padded = 0 THEN N'OFF' ELSE N'ON' END + N', IGNORE_DUP_KEY = '
    + CASE WHEN i.ignore_dup_key = 0 THEN N'OFF' ELSE N'ON' END + N', ALLOW_ROW_LOCKS = '
    + CASE WHEN i.allow_row_locks = 0 THEN N'OFF' ELSE N'ON' END + ', ALLOW_PAGE_LOCKS = '
    + CASE WHEN i.allow_page_locks = 0 THEN N'OFF)' ELSE N'ON)' END                       AS index_property
FROM sys.key_constraints AS kc
	INNER JOIN  sys.indexes         AS i
		ON       i.object_id      = kc.parent_object_id
		AND      i.is_primary_key = 1
	INNER JOIN  sys.index_columns   AS ic
		ON       ic.object_id     = i.object_id
		AND      ic.index_id      = i.index_id
	INNER JOIN  sys.columns         AS c
		ON       c.object_id      = ic.object_id
		AND      c.column_id      = ic.column_id
	INNER JOIN  sys.filegroups      AS fg
		ON       fg.data_space_id = i.data_space_id
	WHERE       kc.type     = 'PK' AND         kc.parent_object_id = @object_id;

/************************************************************************************************************************************
*   If the table has a foreign key constraint on an affected column, this creates the drop and recreate constraint script           *
*   this has been taken and adapted from a script found online cretaed by Jayakumaur R                                              *
************************************************************************************************************************************/
-- @has_foreign_key > 0
SELECT  fk.object_id,
        fk.name
FROM    sys.foreign_keys AS fk
WHERE   fk.parent_object_id = @object_id
	AND     EXISTS (SELECT      *   -- Has to constrain at least one column with wrong collation
					FROM        sys.foreign_key_columns AS fkc
					INNER JOIN  sys.columns             AS c
						ON       c.object_id       = fkc.parent_object_id
						AND      c.column_id       = fkc.parent_column_id
						AND      c.collation_name  <> @DatabaseCollation
					INNER JOIN  sys.types               AS ty
						ON       ty.system_type_id = c.system_type_id
						AND      ty.name           <> N'sysname'
					WHERE       fkc.parent_object_id = fk.parent_object_id
					AND         fkc.constraint_object_id     = fk.object_id);

/************************************************************************************************************************************
*   If the table has unique constraints on affected columns, this creates the drop and recreate scripts                             *
************************************************************************************************************************************/
-- @has_unique_constraint > 0
SELECT  '@has_unique_constraint > 0',
		kc.object_id,
        kc.name,
        kc.unique_index_id
FROM    sys.key_constraints AS kc
WHERE   kc.parent_object_id = @object_id
AND     kc.type                 = 'UQ'
AND     EXISTS (SELECT      *   -- Has to constrain at least one column with wrong collation
                FROM        sys.index_columns AS ic
                INNER JOIN  sys.columns       AS c
                    ON       c.object_id       = ic.object_id
                    AND      c.column_id       = ic.column_id
                    AND      c.collation_name  <> @DatabaseCollation
                INNER JOIN  sys.types         AS ty
                    ON       ty.system_type_id = c.system_type_id
                    AND      ty.name           <> N'sysname'
                WHERE       ic.object_id = kc.parent_object_id
                AND         ic.index_id          = kc.unique_index_id);


WITH cte_contraints AS (
	SELECT 
		o.schema_id,
		o.name objectname,
		cc.name,
		c.object_id,
		CASE WHEN cc.uses_database_collation=1 THEN CAST(DATABASEPROPERTYEX(DB_NAME(DB_ID()), 'Collation') AS nvarchar(255)) COLLATE Latin1_General_CI_AS
			ELSE CAST(c.collation_name AS NVARCHAR(100)) COLLATE Latin1_General_CI_AS
		END collation_name
	FROM sys.columns AS c
		INNER JOIN sys.check_constraints cc
			ON c.object_id = cc.parent_object_id
			AND cc.parent_column_id = c.column_id
		INNER JOIN sys.types AS ty
			ON ty.system_type_id = c.system_type_id
			AND ty.name <> N'sysname'
		INNER JOIN sys.objects o on o.object_id = c.object_id
)
SELECT 
	'DropCheck' AS ScriptType,
	N'ALTER TABLE ' + QUOTENAME(SCHEMA_NAME(schema_id)) + N'.' + QUOTENAME(objectname) + N' DROP CONSTRAINT ' + QUOTENAME(name) + ' '  AS Script
FROM cte_contraints
WHERE collation_name <> @DatabaseCollation;


WITH cte_contraints AS (
	SELECT 
		o.schema_id,
		o.name objectname,
		cc.name,
		cc.definition,
		c.object_id,
		cc.uses_database_collation,
		CASE WHEN cc.uses_database_collation=1 THEN CAST(DATABASEPROPERTYEX(DB_NAME(DB_ID()), 'Collation') AS nvarchar(255)) COLLATE Latin1_General_CI_AS
			ELSE CAST(c.collation_name AS NVARCHAR(100)) COLLATE Latin1_General_CI_AS
		END collation_name
	FROM sys.columns AS c
		INNER JOIN sys.check_constraints cc
			ON c.object_id = cc.parent_object_id
			AND cc.parent_column_id = c.column_id
		INNER JOIN sys.types AS ty
			ON ty.system_type_id = c.system_type_id
			AND ty.name <> N'sysname'
		INNER JOIN sys.objects o on o.object_id = c.object_id
)
SELECT N'CreateCheck' AS ScriptType, 
	   N'ALTER TABLE ' + QUOTENAME(SCHEMA_NAME(cte.schema_id)) + N'.' + QUOTENAME(cte.objectname) + N' WITH CHECK ADD CONSTRAINT ' + QUOTENAME(cte.name)+ ' CHECK ' + cte.definition AS script
FROM cte_contraints cte
WHERE cte.collation_name <> @DatabaseCollation
GROUP BY cte.name, cte.definition, cte.schema_id,cte.objectname;