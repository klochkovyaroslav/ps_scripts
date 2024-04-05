######################################################## CHECKDB_WITH_EXTENDED_LOGICAL #################################################################################################
$NameDB="E03"


$rezult_EL = $PSScriptRoot+"\EXTENDED_LOGICAL_rezult.txt"
$ErrorActionPreference= "stop"
Clear-Variable -Name "Error"




    $time_el_start = (Get-Date)
    if (test-path $rezult_EL)
    {
    del $rezult_EL
    $QUERY_EXTENDED_LOGICAL = "DBCC CHECKDB ($NameDB) with EXTENDED_LOGICAL_CHECKS, MAXDOP =8"
    #(Get-Date).ToString()+" - начало выполнения SQL-скрипта: CHECK EXTENDED_LOGICAL" +  "`n" | out-file -Filepath $rezult_EL -append
    Invoke-Sqlcmd -ServerInstance localhost -Querytimeout 0 -Database $NameDB -SuppressProviderContextWarning $QUERY_EXTENDED_LOGICAL -Verbose 4>&1 | out-file -Filepath $rezult_EL -append
    ''| out-file -Filepath $rezult_EL -append
    #(Get-Date).ToString()+" - окончание выполнения скрипта: CHECK EXTENDED_LOGICAL"| out-file -Filepath $rezult_EL -append
    }
    else
    {
    $QUERY_EXTENDED_LOGICAL = "DBCC CHECKDB ($NameDB) with EXTENDED_LOGICAL_CHECKS, MAXDOP =8"
    #(Get-Date).ToString()+" - начало выполнения SQL-скрипта: CHECK EXTENDED_LOGICAL" +  "`n" | out-file -Filepath $rezult_EL -append
    Invoke-Sqlcmd -ServerInstance localhost -Querytimeout 0 -Database $NameDB -SuppressProviderContextWarning $QUERY_EXTENDED_LOGICAL -Verbose 4>&1 | out-file -Filepath $rezult_EL -append
    ''| out-file -Filepath $rezult_EL -append
    #(Get-Date).ToString()+" - окончание выполнения скрипта: CHECK EXTENDED_LOGICAL"| out-file -Filepath $rezult_EL -append
    }
    $time_el_stop = (Get-Date)
    $time_el_total=($time_el_stop-$time_el_start).ToString().Split('.')[0]
    'Время выполнения: '+ $time_el_total | out-file -Filepath $rezult_EL -append


    $str_search_EL=(Get-Item -Path $rezult_EL | Get-Content -Tail 4)
    $str_search_EL= $str_search_EL | Out-String
    $pattern = "DBCC execution completed"
    if ($str_search_EL -match $pattern) 
    {
        WriteLog 'Проверка: CHECKDB_WITH_EXTENDED_LOGICAL завершена - Успешно'
        WriteLog $str_search_EL
        "----------------------------------------------------------"| out-file -Filepath $Logfile -append
    }
    else
    {
        WriteLog "Проверка: CHECKDB_WITH_EXTENDED_LOGICAL завершена - с Ошибками"
        WriteLog $str_search_EL
        "----------------------------------------------------------"| out-file -Filepath $Logfile -append        
    }