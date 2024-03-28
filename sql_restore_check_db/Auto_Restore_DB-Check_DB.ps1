$NameDB="PYL"

$rezult_FO = "C:\Scripts\PHYSICAL_ONLY_rezult.txt"
$rezult_EL = "C:\Scripts\EXTENDED_LOGICAL_rezult.txt"
$tmp_f = "C:\Scripts\tmp.txt"
$rest_db = "C:\Scripts\restore_db.sql"
$rezult = "C:\Scripts\SQL_Rezult.txt"
$path_backup_files_Y="Y:\$NameDB\"
$path_backup_files_Z="Z:\$NameDB\"
$path_backup_files_W="W:\$NameDB\"
$ErrorActionPreference= "stop"

#-------------------------------------------------------CREATE SQL-RESRORE SCRIPT---------------------------------------------------------------------------------------------------

$Files_y = Get-ChildItem -Recurse -Path $path_backup_files_Y -Include "*.bak" 
$Files_z = Get-ChildItem -Recurse -Path $path_backup_files_Z -Include "*.bak" 
$Files_w = Get-ChildItem -Recurse -Path $path_backup_files_W -Include "*.trn" 

'USE [master]' | out-file -Filepath $tmp_f -append
'RESTORE DATABASE ' + '['+ $NameDB +']' +' FROM ' | out-file -Filepath $tmp_f -append
'DISK=' + "`'" + $Files_y.fullName +  "`'," | out-file -Filepath $tmp_f -append
'DISK=' + "`'" + $Files_z.fullName +  "`'" + ' WITH  FILE = 1, NORECOVERY, NOUNLOAD, STATS = 5'+ "`n" | out-file -Filepath $tmp_f -append
ForEach ($x in $Files_w)
{
'RESTORE LOG ' + '['+ $NameDB +'] FROM DISK=' + "`'" + $x.fullName +  "`' WITH FILE = 1, NORECOVERY, NOUNLOAD, STATS = 5" | out-file -Filepath $tmp_f -append
}
$srt_chg=(Get-Item -Path $tmp_f | Get-Content -Tail 1).replace(" NORECOVERY,","")
$str_del=(Get-Item -Path $tmp_f | Get-Content -Tail 1)
((Get-Content -path $tmp_f).replace($str_del, $srt_chg)) | Out-File $rest_db
"`n"+'GO' | Out-File $rest_db  -append
del $tmp_f
#-------------------------------------------------------RESTORE DATABASE------------------------------------------------------------------------------------------------------------

$time_res_start = (Get-Date)
Invoke-Sqlcmd -ServerInstance localhost -Querytimeout 0 -Database "master" -InputFile $rest_db -Verbose 4>&1 | out-file -Filepath $rezult
$time_res_stop = (Get-Date)
$time_res_total=($time_res_stop-$time_res_start).ToString().Split('.')[0]
'Время восстановления БД + : '+ $time_res_total +  "`n" | out-file -Filepath $rezult -append
del $rest_db

#-------------------------------------------------------CHECKDB_WITH_PHYSICAL_ONLY--------------------------------------------------------------------------------------------------

$watch = [System.Diagnostics.Stopwatch]::StartNew()
$watch.Start() #Запуск таймера

if (test-path $rezult_FO)
{
del $rezult_FO
$QUERY_PHYSICAL_ONLY = "DBCC CHECKDB ($NameDB) WITH PHYSICAL_ONLY, MAXDOP =8"
(Get-Date).ToString()+" - начало выполнения SQL-скрипта: CHECK PHYSICAL ONLY" +  "`n" | out-file -Filepath $rezult_FO -append
Invoke-Sqlcmd -ServerInstance localhost -Querytimeout 0 -Database $NameDB -SuppressProviderContextWarning $QUERY_PHYSICAL_ONLY -Verbose 4>&1 | out-file -Filepath $rezult_FO -append
''| out-file -Filepath $rezult_FO -append
(Get-Date).ToString()+" - окончание выполнения FULL-скрипта: CHECK PHYSICAL ONLY"| out-file -Filepath $rezult_FO -append
}
else
{
$QUERY_PHYSICAL_ONLY = "DBCC CHECKDB ($NameDB) WITH PHYSICAL_ONLY, MAXDOP =8"
(Get-Date).ToString()+" - начало выполнения SQL-скрипта: CHECK PHYSICAL ONLY" +  "`n" | out-file -Filepath $rezult_FO -append
Invoke-Sqlcmd -ServerInstance localhost -Querytimeout 0 -Database $NameDB -SuppressProviderContextWarning $QUERY_PHYSICAL_ONLY -Verbose 4>&1 | out-file -Filepath $rezult_FO -append
''| out-file -Filepath $rezult_FO -append
(Get-Date).ToString()+" - окончание выполнения FULL-скрипта: CHECK PHYSICAL ONLY"| out-file -Filepath $rezult_FO -append
}
$watch.Stop() #Остановка таймера
'Время выполнения: '+ (($watch.Elapsed).ToString()).Split('.')[0] | out-file -Filepath $rezult_FO -append


#-------------------------------------------------------CHECKDB_WITH_EXTENDED_LOGICAL--------------------------------------------------------------------------------------------------

$time_el_start = (Get-Date)
if (test-path $rezult_EL)
{
del $rezult_EL
$QUERY_EXTENDED_LOGICAL = "DBCC CHECKDB ($NameDB) with EXTENDED_LOGICAL_CHECKS, MAXDOP =8"
(Get-Date).ToString()+" - начало выполнения SQL-скрипта: CHECK EXTENDED_LOGICAL" +  "`n" | out-file -Filepath $rezult_EL -append
Invoke-Sqlcmd -ServerInstance localhost -Querytimeout 0 -Database $NameDB -SuppressProviderContextWarning $QUERY_EXTENDED_LOGICAL -Verbose 4>&1 | out-file -Filepath $rezult_EL -append
''| out-file -Filepath $rezult_EL -append
(Get-Date).ToString()+" - окончание выполнения скрипта: CHECK EXTENDED_LOGICAL"| out-file -Filepath $rezult_EL -append
}
else
{
$QUERY_EXTENDED_LOGICAL = "DBCC CHECKDB ($NameDB) with EXTENDED_LOGICAL_CHECKS, MAXDOP =8"
(Get-Date).ToString()+" - начало выполнения SQL-скрипта: CHECK EXTENDED_LOGICAL" +  "`n" | out-file -Filepath $rezult_EL -append
Invoke-Sqlcmd -ServerInstance localhost -Querytimeout 0 -Database $NameDB -SuppressProviderContextWarning $QUERY_EXTENDED_LOGICAL -Verbose 4>&1 | out-file -Filepath $rezult_EL -append
''| out-file -Filepath $rezult_EL -append
(Get-Date).ToString()+" - окончание выполнения скрипта: CHECK EXTENDED_LOGICAL"| out-file -Filepath $rezult_EL -append
}
$time_el_stop = (Get-Date)
$time_el_total=($time_el_stop-$time_el_start).ToString().Split('.')[0]
'Время выполнения: '+ $time_el_total | out-file -Filepath $rezult_EL -append


#-------------------------------------------------------DELETE DATABASE----------------------------------------------------------------------------------------------------------------

$DELETE_DB="EXEC msdb.dbo.sp_delete_database_backuphistory @database_name = '$NameDB'
GO
use [$NameDB];
GO
use [master];
GO
USE [master]
GO
ALTER DATABASE [$NameDB] SET  SINGLE_USER WITH ROLLBACK IMMEDIATE
GO
USE [master]
GO
DROP DATABASE [$NameDB]
GO"
Invoke-Sqlcmd -ServerInstance localhost -Database $NameDB -SuppressProviderContextWarning $DELETE_DB