DECLARE @Search VARCHAR(255)
SET @Search='QueueProcessor'

SELECT DISTINCT
    o.name AS Object_Name,o.type_desc
    FROM sys.sql_modules        m 
        INNER JOIN sys.objects  o ON m.object_id=o.object_id
    WHERE m.definition LIKE '%'+@Search+'%'
    ORDER BY 2,1

