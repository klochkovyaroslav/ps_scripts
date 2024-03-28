$NameDB="PYL"

$rezult_FO = "C:\Scripts\PHYSICAL_ONLY_rezult.txt"
$rezult_EL = "C:\Scripts\EXTENDED_LOGICAL_rezult.txt"
$tmp_f = "C:\Scripts\tmp.txt"
$rest_db = "C:\Scripts\restore_db.sql"
$rezult = "C:\Scripts\SQL_Rezult"
$path_backup_files_Y="Y:\$NameDB\"
$path_backup_files_Z="Z:\$NameDB\"
$path_backup_files_W="W:\$NameDB\"
$ErrorActionPreference= "stop"


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

#Start-Transcript -Append C:\Scripts\PSScriptLog.txt
#---------------------------------------------------------------------------------------------------------------------------------------------------------------------
#Восстанавливаем БД
Invoke-Sqlcmd -ServerInstance localhost -Querytimeout 0 -Database "master" -InputFile $rest_db -Verbose 4>&1 | out-file -Filepath $rezult
del $rest_db
#Stop-Transcript


#-------------------------------------------------------CHECKDB_WITH_PHYSICAL_ONLY------------------------------------------------------------------------------------

$time_po_start = (Get-Date)
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
$time_po_stop = (Get-Date)
$time_po_total=($time_po_stop-$time_po_start).ToString().Split('.')[0]
'Время выполнения: '+ $time_po_total | out-file -Filepath $rezult_FO -append


#-------------------------------------------------------CHECKDB_WITH_EXTENDED_LOGICAL------------------------------------------------------------------------------------

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