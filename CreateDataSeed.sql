
DECLARE @TableName NVARCHAR(max) = 'TableName'
DECLARE @columns NVARCHAR(max)
DECLARE @columnsWithCast AS NVARCHAR(max)
DECLARE @idColumn AS NVARCHAR(max)

;WITH columnNames AS
(
	SELECT TOP(100000) column_id, c.name
	FROM sys.columns c
	INNER JOIN sys.tables t on c.object_id = t.object_id
	WHERE t.name = @TableName
	order by t.object_id, column_id
)
SELECT @columns =
    STUFF((SELECT ', ' + name
           FROM columnNames b order by b.column_id
          FOR XML PATH('')), 1, 2, '')

	  ,@columnsWithCast =
    STUFF((SELECT ', ' + 'CAST(' + name + ' AS NVARCHAR(MAX)) AS ' + name
           FROM columnNames b order by b.column_id 
          FOR XML PATH('')), 1, 2, '')



SELECT @idColumn = c.name
FROM sys.columns c
INNER JOIN sys.tables t on c.object_id = t.object_id
WHERE t.name = @TableName AND c.column_id = 1

DECLARE @sql NVARCHAR(max) = N'

WITH RawData AS
(
	SELECT ' + @idColumn + ' AS id, ' + @columnsWithCast + '
	FROM ' + @TableName + '
)
, ColumnTypes AS
(
	SELECT TOP(100000) column_id, c.name, c.system_type_id
	FROM sys.columns c
	INNER JOIN sys.tables t on c.object_id = t.object_id
	WHERE t.name = ''' + @TableName + '''
	order by t.object_id, column_id
)
, PivotData AS
(
	select id, columnName, columnValue
	from RawData
	unpivot
	(
		columnValue
		for columnName in (' + @columns + ')
	) u
)

, ConcatinateData AS
(
	SELECT row_number() over(order by id) as rowNum, id, PivotData.columnName + '' = '' + 
	
		CASE WHEN D.system_type_id = 56 OR D.system_type_id = 127 THEN PivotData.columnValue -- INT and BIGINT
		WHEN d.system_type_id = 104 THEN CASE WHEN PivotData.columnValue = 1 THEN ''true'' ELSE ''false'' END  -- Bool
		WHEN D.system_type_id = 106 THEN PivotData.columnValue + ''M'' -- DECIMAL
		ELSE ''"'' + REPLACE(PivotData.columnValue,''"'', ''\"'') + ''"''
		END AS Data
	FROM PivotData
	INNER JOIN ColumnTypes D ON d.name = PivotData.columnName
)


SELECT 
    STUFF((SELECT '', '' + data
           FROM ConcatinateData b
           WHERE b.id = a.id 
		   order by rowNum 
          FOR XML PATH('''')), 1, 2, '''')
FROM ConcatinateData a
GROUP BY id
'

exec sp_executesql @sql



