DECLARE @DBName NVARCHAR(200)= 'PER'
DECLARE @ServerName NVARCHAR(256)  = @@SERVERNAME 
DECLARE @RoleDesc NVARCHAR(60)
DECLARE @BackupPath NVARCHAR(200)='W:\'+@DBName+'\'+ @DBName+'_LOG_' + REPLACE(convert(nvarchar(20),GetDate(),120),':','-') + '.trn'
DECLARE @NameJob NVARCHAR(200)= @DBName+'-log Database Backup'

SELECT @RoleDesc = a.role_desc
FROM sys.dm_hadr_availability_replica_states AS a
JOIN sys.availability_replicas AS b
ON b.replica_id = a.replica_id
WHERE b.replica_server_name = UPPER(@ServerName)

IF @RoleDesc = 'PRIMARY'
BEGIN
		BACKUP LOG @DBName TO  DISK = @BackupPath  WITH NOFORMAT, NOINIT,  NAME= @NameJob, SKIP, NOREWIND, NOUNLOAD,COMPRESSION,  STATS = 10
END
