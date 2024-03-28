﻿$watch = [System.Diagnostics.Stopwatch]::StartNew()
$watch.Start() #Запуск таймера

$NameDB="PYL"
$rezult_FO = "C:\Scripts\PHYSICAL_ONLY_rezult.txt"
$ErrorActionPreference= "stop"


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
#Write-Host 'Время выполнения: '(($watch.Elapsed).ToString()).Split('.')[0] #Вывод на экран