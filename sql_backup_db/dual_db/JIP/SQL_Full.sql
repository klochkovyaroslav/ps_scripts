DECLARE @DBName NVARCHAR(200)= 'JIP'
DECLARE @BackupPath1 NVARCHAR(200)='Y:\'+@DBName+'\'+ @DBName+'_FULL_1_' + REPLACE(convert(nvarchar(20),GetDate(),120),':','-') + '.bak'
DECLARE @BackupPath2 NVARCHAR(200)='Z:\'+@DBName+'\'+ @DBName+'_FULL_2_' + REPLACE(convert(nvarchar(20),GetDate(),120),':','-') + '.bak'
DECLARE @NameJob NVARCHAR(200)= @DBName+'-Full Database Backup'

BACKUP DATABASE @DBName 
TO  
DISK = @BackupPath1,
DISK = @BackupPath2  
WITH 
BLOCKSIZE=65536,BUFFERCOUNT=500,MAXTRANSFERSIZE=4194304, NOFORMAT, INIT, NAME = @NameJob, SKIP, NOREWIND, NOUNLOAD, COMPRESSION, STATS = 10
