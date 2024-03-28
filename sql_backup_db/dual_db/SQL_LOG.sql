DECLARE @DBName NVARCHAR(200)= 'BIP'
DECLARE @RoleDesc NVARCHAR(60)
DECLARE @BackupPath NVARCHAR(200)='W:\'+@DBName+'\'+ @DBName+'_LOG_' + REPLACE(convert(nvarchar(20),GetDate(),120),':','-') + '.trn'
DECLARE @NameJob NVARCHAR(200)= @DBName+'-log Database Backup'

BACKUP LOG @DBName TO  DISK = @BackupPath  WITH NOFORMAT, NOINIT,  NAME= @NameJob, SKIP, NOREWIND, NOUNLOAD,COMPRESSION,  STATS = 10
