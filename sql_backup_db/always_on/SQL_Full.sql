DECLARE @ServerName NVARCHAR(256)  = @@SERVERNAME 
DECLARE @RoleDesc NVARCHAR(60)
DECLARE @DBName NVARCHAR(200)= 'PER'
DECLARE @BackupPath1 NVARCHAR(200)='Y:\'+@DBName+'\'+ @DBName+'_FULL_1_' + REPLACE(convert(nvarchar(20),GetDate(),120),':','-') + '.bak'
DECLARE @BackupPath2 NVARCHAR(200)='Z:\'+@DBName+'\'+ @DBName+'_FULL_2_' + REPLACE(convert(nvarchar(20),GetDate(),120),':','-') + '.bak'
DECLARE @NameJob NVARCHAR(200)= @DBName+'-Full Database Backup'


SELECT @RoleDesc = a.role_desc
    FROM sys.dm_hadr_availability_replica_states AS a
    JOIN sys.availability_replicas AS b
        ON b.replica_id = a.replica_id
WHERE b.replica_server_name = UPPER(@ServerName)


IF @RoleDesc = 'PRIMARY'
BEGIN
		BACKUP DATABASE @DBName 
		TO  
		DISK = @BackupPath1,
		DISK = @BackupPath2  

		WITH 
		BLOCKSIZE=65536,BUFFERCOUNT=1000,MAXTRANSFERSIZE=4194304,
		NOFORMAT, INIT,  NAME = @NameJob, SKIP, NOREWIND, NOUNLOAD, COMPRESSION, STATS = 10
END