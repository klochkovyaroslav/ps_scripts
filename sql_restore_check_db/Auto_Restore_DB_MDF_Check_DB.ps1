######################################################## RESTORE DATABASE And CHECK DB ##############################################################################################
$timer_script = [System.Diagnostics.Stopwatch]::StartNew()
$timer_script.Start() #Запуск таймера


$NameDB="100_TEST_DB"
$name_srv="gth-prd-dbc-ag"
$items_rec=$name_srv + "\"+$NameDB
$p_loc="bsp://SRC01/SRC01-SQLAG"

$dest_host_rec="192.168.2.162"
$cred="user_backup,xh/jPO8NNCde71oQLxFgHNj1MOs3zHj9v96kUx0TDaLxLjbQHtA==,encrypted"


$rezult_FO = $PSScriptRoot+"\PHYSICAL_ONLY_rezult.txt"
$rezult_EL = $PSScriptRoot+"\EXTENDED_LOGICAL_rezult.txt"
$rest_db = $PSScriptRoot+"\restore_db.sql"
$rezult = $PSScriptRoot+"\RESTORE_SQL_REZULT.txt"
$path_backup_files_Z="Z:\"+$items_rec
$ErrorActionPreference= "Continue"
$Error.Clear()


#-------------------------------------------------------Function "WriteLog"---------------------------------------------------------------------------------------------------------
$Logfile = $PSScriptRoot+"\DB_RESTORE_CHECKDB_LOG.txt"
function WriteLog
{
    Param ([string]$LogString)
    $Stamp = (Get-Date).toString("dd/MM/yyyy HH:mm:ss")
    $LogMessage = "$Stamp $LogString"
    Add-content $LogFile -value $LogMessage
}
if (test-path $Logfile)
{
Remove-Item $Logfile
}

#-------------------------------------------------------RECOVERY FILES FROM CYBER BACKUP SCRIPT------------------------------------------------------------------------------------------
$time_res_start = (Get-Date)
$list_archives= ((& acrocmd.exe list archives --loc=$p_loc --credentials=$cred --output=raw).Split('	') | Select-String -Pattern $name_srv)
$list_all_full_backups=(& acrocmd.exe list backups --loc=$p_loc --credentials=$cred --arc=$list_archives --filter_type=full --output=raw)
$last_full_backup=$list_all_full_backups[-3]
$last_full_backup=($list_all_full_backups[-3].Split('	')[0])
& acrocmd.exe recover mssql_database --loc=$p_loc --credentials=$cred --arc=$list_archives --backup=$last_full_backup --items=$items_rec --target=disk --disk_location=Z:\ --host=$dest_host_rec --credentials=$cred --progress
$time_res_stop = (Get-Date)
$time_res_total=($time_res_stop-$time_res_start).ToString().Split('.')[0]

"Пауза 1 мин"
Start-Sleep -Seconds 60
#>
$Files_mdf = Get-ChildItem -Recurse -Path $path_backup_files_Z -Include "*.mdf"
$Files_ldf = Get-ChildItem -Recurse -Path $path_backup_files_Z -Include "*.ldf"

#-------------------------------------------------------CREATE SQL-CHECK-STATUS SCRIPT---------------------------------------------------------------------------------------------------
$query_state_db="SELECT state_desc
    FROM sys.databases
    WHERE Name = '$NameDB'
    GO"

#-------------------------------------------------------CREATE SQL-RESTORE SCRIPT---------------------------------------------------------------------------------------------------

if (test-path $path_backup_files_Z)
{#1
        #"да папки существуют"
        if (-not( Get-ChildItem -Recurse -Path $path_backup_files_Z -Include "*.mdf"))
        {#2
            WriteLog "файлы *mdf НЕ найдены на диске Z"
        }#2
        else
        {#2_1
        #-------------------------------------------------------CREATE SQL_DB-ATTACH SCRIPT---------------------------------------------------------------------------------------------------

        "Восстановление файлов: " + $Files_mdf.Name, $Files_ldf.Name+", прошло успешно." | out-file -Filepath $Logfile -append
        'Время выполнения: '+ $time_res_total | out-file -Filepath $Logfile -append
        "----------------------------------------------------------" | out-file -Filepath $Logfile -append

        $query_rec_db="CREATE DATABASE [$NameDB] ON 
        ( FILENAME = '$Files_mdf' ),
        ( FILENAME = '$Files_ldf' )
         FOR ATTACH
         GO"

        $time_res_start = (Get-Date)
        "Запущено подключение БД в SQL: " + (Get-Date).toString("dd/MM/yyyy HH:mm:ss")
        Invoke-Sqlcmd -ServerInstance localhost -Querytimeout 0 -Database "master" -SuppressProviderContextWarning $query_rec_db -Verbose 2>&1 4>&1 | out-file -Filepath $rezult -append
        $time_res_stop = (Get-Date)
        $time_res_total=($time_res_stop-$time_res_start).ToString().Split('.')[0]

        "Пауза 30 sec"
        Start-Sleep -Seconds 30

#-------------------------------------------------------CHECKING ATTACHED DATABASE + TRANSACTION LOG CORRECTLY------------------------------------------------------------------------

        $db_status=Invoke-Sqlcmd -ServerInstance localhost -Querytimeout 0 -Database "master" -SuppressProviderContextWarning $query_state_db -Verbose 2>&1 4>&1
        $db_status=($db_status[0] | Out-String).Trim()
        if ($db_status -eq "ONLINE")
        {
        Write-Output "БД подключена, в состоянии: $db_status"
        'Время восстановления БД + цепочки файлов транзакций :'+ $time_res_total| out-file -Filepath $rezult -append
        "БД:"+ $NameDB+" успешно подключена в SSMS. Статус: "+ $db_status  | out-file -Filepath $Logfile -append
        "----------------------------------------------------------"| out-file -Filepath $Logfile -append
       
        #-------------------------------------------------------CHECKDB_WITH_PHYSICAL_ONLY--------------------------------------------------------------------------------------------------

        $watch = [System.Diagnostics.Stopwatch]::StartNew()
        $watch.Start() #Запуск таймера


        $QUERY_PHYSICAL_ONLY = "Use "+""""+ $NameDB +""""+" 
         GO 
         DBCC CHECKDB WITH PHYSICAL_ONLY, MAXDOP =8
         GO"

        if (test-path $rezult_FO)
        {
        Remove-Item $rezult_FO
        "Запущена проверка 'CHECKDB_WITH_PHYSICAL_ONLY':" + (Get-Date).toString("dd/MM/yyyy HH:mm:ss")
        Invoke-Sqlcmd -ServerInstance localhost -Querytimeout 0 -Database "master" -SuppressProviderContextWarning $QUERY_PHYSICAL_ONLY -Verbose 4>&1 | out-file -Filepath $rezult_FO -append
        ''| out-file -Filepath $rezult_FO -append
        }
        else
        {
        "Запущена проверка 'CHECKDB_WITH_PHYSICAL_ONLY':" + (Get-Date).toString("dd/MM/yyyy HH:mm:ss")
        Invoke-Sqlcmd -ServerInstance localhost -Querytimeout 0 -Database "master" -SuppressProviderContextWarning $QUERY_PHYSICAL_ONLY -Verbose 4>&1 | out-file -Filepath $rezult_FO -append
        ''| out-file -Filepath $rezult_FO -append
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

        #-------------------------------------------------------CHECKDB_WITH_EXTENDED_LOGICAL--------------------------------------------------------------------------------------------------

        $time_el_start = (Get-Date)

        $QUERY_EXTENDED_LOGICAL = "Use "+""""+ $NameDB +""""+" 
         GO 
         DBCC CHECKDB with EXTENDED_LOGICAL_CHECKS, MAXDOP =8
         GO"

        if (test-path $rezult_EL)
        {
        Remove-Item $rezult_EL
        "Запущена проверка 'CHECKDB_WITH_EXTENDED_LOGICAL':" + (Get-Date).toString("dd/MM/yyyy HH:mm:ss")
        Invoke-Sqlcmd -ServerInstance localhost -Querytimeout 0 -Database "master" -SuppressProviderContextWarning $QUERY_EXTENDED_LOGICAL -Verbose 4>&1 | out-file -Filepath $rezult_EL -append
        ''| out-file -Filepath $rezult_EL -append
        }
        else
        {
        "Запущена проверка 'CHECKDB_WITH_EXTENDED_LOGICAL':" + (Get-Date).toString("dd/MM/yyyy HH:mm:ss")
        Invoke-Sqlcmd -ServerInstance localhost -Querytimeout 0 -Database "master" -SuppressProviderContextWarning $QUERY_EXTENDED_LOGICAL -Verbose 4>&1 | out-file -Filepath $rezult_EL -append
        ''| out-file -Filepath $rezult_EL -append
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
        }

        else
        {
        Write-Output "БД НЕ восстановлена, в состоянии: $db_status"
        "БД не подключена, в состоянии: $db_status"| out-file -Filepath $rezult -append
        exit
        }
    }#2_1

}#1

else
{#1_1
    WriteLog "Папки Z не существует"
}#1_1

#-------------------------------------------------------DELETE TEMP LOG--------------------------------------------------------------------------------------------------
Remove-Item $rezult_EL
Remove-Item $rezult_FO
Remove-Item $rezult
#-------------------------------------------------------DELETE DATABASE--------------------------------------------------------------------------------------------------
Start-Sleep -Seconds 10

$query_del_db="EXEC msdb.dbo.sp_delete_database_backuphistory @database_name = '$NameDB'
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
Invoke-Sqlcmd -ServerInstance localhost -Database $NameDB -SuppressProviderContextWarning $query_del_db
WriteLog "Удаление БД: $NameDB завершено - Успешно"
"----------------------------------------------------------" | out-file -Filepath $Logfile -append

#-------------------------------------------------------DELETE TEMP LOG FILES IF ERROR--------------------------------------------------------------------------------------------------
if ($Error)
{
"В процессе выполнения скрипта возникла ошибка"
"----------------------------------------------------------" | out-file -Filepath $Logfile -append
    if (test-path $rezult_EL)
    {
    Remove-Item $rezult_EL
    }
    if (test-path $rezult_FO)
    {
    Remove-Item $rezult_FO
    }
    if (test-path $rezult)
    {
    Remove-Item $rezult
    }
    if (test-path ("Z:\"+ $name_srv))
    {
    Remove-Item -Recurse -Force ("Z:\"+ $name_srv)
    }
    WriteLog "Удаление временных файлов завершено - Успешно"
}
else
{
"В процессе выполнения скрипта ошибок не обнаружено "
    if (test-path ("Z:\"+ $name_srv))
    {
    Remove-Item -Recurse -Force ("Z:\"+ $name_srv)
    }
WriteLog "Удаление временных файлов завершено - Успешно"
"----------------------------------------------------------" | out-file -Filepath $Logfile -append
}
$timer_script.Stop()
'Общее время выполнения скрипта: '+ (($timer_script.Elapsed).ToString()).Split('.')[0]