####################################################################### CHECKDB_WITH_PHYSICAL_ONLY #####################################################################################
$NameDB="E03"

$rezult_FO = $PSScriptRoot+"\PHYSICAL_ONLY_rezult.txt"
$ErrorActionPreference= "stop"
Clear-Variable -Name "Error"


    $watch = [System.Diagnostics.Stopwatch]::StartNew()
    $watch.Start() #Запуск таймера

    if (test-path $rezult_FO)
    {
    del $rezult_FO
    $QUERY_PHYSICAL_ONLY = "DBCC CHECKDB ($NameDB) WITH PHYSICAL_ONLY, MAXDOP =8"
    #(Get-Date).ToString()+" - начало выполнения SQL-скрипта: CHECK PHYSICAL ONLY" +  "`n" | out-file -Filepath $rezult_FO -append
    Invoke-Sqlcmd -ServerInstance localhost -Querytimeout 0 -Database $NameDB -SuppressProviderContextWarning $QUERY_PHYSICAL_ONLY -Verbose 4>&1 | out-file -Filepath $rezult_FO -append
    ''| out-file -Filepath $rezult_FO -append
    #(Get-Date).ToString()+" - окончание выполнения FULL-скрипта: CHECK PHYSICAL ONLY"| out-file -Filepath $rezult_FO -append
    }
    else
    {
    $QUERY_PHYSICAL_ONLY = "DBCC CHECKDB ($NameDB) WITH PHYSICAL_ONLY, MAXDOP =8"
    #(Get-Date).ToString()+" - начало выполнения SQL-скрипта: CHECK PHYSICAL ONLY" +  "`n" | out-file -Filepath $rezult_FO -append
    Invoke-Sqlcmd -ServerInstance localhost -Querytimeout 0 -Database $NameDB -SuppressProviderContextWarning $QUERY_PHYSICAL_ONLY -Verbose 4>&1 | out-file -Filepath $rezult_FO -append
    ''| out-file -Filepath $rezult_FO -append
    #(Get-Date).ToString()+" - окончание выполнения FULL-скрипта: CHECK PHYSICAL ONLY"| out-file -Filepath $rezult_FO -append
    }
    $watch.Stop() #Остановка таймера
    'Время выполнения: '+ (($watch.Elapsed).ToString()).Split('.')[0] | out-file -Filepath $rezult_FO -append
    $str_search_FO=(Get-Item -Path $rezult_FO | Get-Content -Tail 5)
    $str_search_FO= $str_search_FO | Out-String
    $pattern = "DBCC execution completed"
    if ($str_search_FO -match $pattern) 
    {
        WriteLog 'Проверка: CHECKDB_WITH_PHYSICAL_ONLY завершена - Успешно'
        WriteLog $str_search_FO
        "----------------------------------------------------------"| out-file -Filepath $Logfile -append
    }
    else
    {
        WriteLog "Проверка: CHECKDB_WITH_PHYSICAL_ONLY завершена - с Ошибками"
        WriteLog $str_search_FO
        "----------------------------------------------------------"| out-file -Filepath $Logfile -append
    }