$NameDB="PYL"
$rezult_EL = "C:\Scripts\EXTENDED_LOGICAL_rezult.txt"
$ErrorActionPreference= "stop"


$time_el_start = (Get-Date)
if (test-path $rezult_EL)
{
del $rezult_EL
$QUERY_EXTENDED_LOGICAL = "DBCC CHECKDB ($NameDB) with EXTENDED_LOGICAL_CHECKS, MAXDOP =8"
(Get-Date).ToString()+" - начало выполнения SQL-скрипта: CHECK PHYSICAL ONLY" +  "`n" | out-file -Filepath $rezult_EL -append
Invoke-Sqlcmd -ServerInstance localhost -Querytimeout 0 -Database $NameDB -SuppressProviderContextWarning $QUERY_EXTENDED_LOGICAL -Verbose 4>&1 | out-file -Filepath $rezult_EL -append
''| out-file -Filepath $rezult_EL -append
(Get-Date).ToString()+" - окончание выполнения скрипта: CHECK PHYSICAL ONLY"| out-file -Filepath $rezult_EL -append
}
else
{
$QUERY_EXTENDED_LOGICAL = "DBCC CHECKDB ($NameDB) with EXTENDED_LOGICAL_CHECKS, MAXDOP =8"
(Get-Date).ToString()+" - начало выполнения SQL-скрипта: CHECK PHYSICAL ONLY" +  "`n" | out-file -Filepath $rezult_EL -append
Invoke-Sqlcmd -ServerInstance localhost -Querytimeout 0 -Database $NameDB -SuppressProviderContextWarning $QUERY_EXTENDED_LOGICAL -Verbose 4>&1 | out-file -Filepath $rezult_EL -append
''| out-file -Filepath $rezult_EL -append
(Get-Date).ToString()+" - окончание выполнения скрипта: CHECK PHYSICAL ONLY"| out-file -Filepath $rezult_EL -append
}
$time_el_stop = (Get-Date)
$time_el_total=($time_el_stop-$time_el_start).ToString().Split('.')[0]
'Время выполнения: '+ $time_el_total | out-file -Filepath $rezult_EL -append