######################################################## RESTORE DATABASE And CHECK DB ##############################################################################################
$NameDB="PSE"

$rezult_FO = $PSScriptRoot+"\PHYSICAL_ONLY_rezult.txt"
$rezult_EL = $PSScriptRoot+"\EXTENDED_LOGICAL_rezult.txt"
$tmp_f = $PSScriptRoot+"\tmp.txt"
$rest_db = $PSScriptRoot+"\restore_db.sql"
$rezult = $PSScriptRoot+"\RESTORE_SQL_REZULT.txt"
$path_backup_files_Y="Y:\$NameDB\"
$path_backup_files_Z="Z:\$NameDB\"
$path_backup_files_W="W:\$NameDB\"
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

#-------------------------------------------------------CREATE SQL-CHECK-STATUS SCRIPT---------------------------------------------------------------------------------------------------
$query_state_db="SELECT state_desc
    FROM sys.databases
    WHERE Name = '$NameDB'
    GO"
#-------------------------------------------------------CREATE SQL-RESTORE SCRIPT---------------------------------------------------------------------------------------------------
if ((test-path $path_backup_files_Y) -and (test-path $path_backup_files_Z))
{#1
    #WriteLog "да папки существуют"
    if (-not( Get-ChildItem -Recurse -Path $path_backup_files_Y -Include "*.bak") -and ( Get-ChildItem -Recurse -Path $path_backup_files_Z -Include "*.bak"))
    {#2
        WriteLog "файлы *bak НЕ найдены на диске Y или Z"
    }#2

    else
    {#2_1
       if (test-path $path_backup_files_W)
       {#3
            if (-not( Get-ChildItem -Recurse -Path $path_backup_files_W -Include "*.trn"))
            {#4
                WriteLog "файлы *trn НЕ найдены на диске W"

            }#4
            else
            {#4_1 Генерирование скрипта SQL С цепочкой файлов логов транзакций
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
                Remove-Item $tmp_f
                #-------------------------------------------------------RESTORE DATABASE + TRANSACTION LOG--------------------------------------------------------------------------------------------

                $time_res_start = (Get-Date)
                Invoke-Sqlcmd -ServerInstance localhost -Querytimeout 0 -Database "master" -InputFile $rest_db -Verbose 2>&1 4>&1 | out-file -Filepath $rezult
                $time_res_stop = (Get-Date)
                $time_res_total=($time_res_stop-$time_res_start).ToString().Split('.')[0]

                #-------------------------------------------------------CHECKING RESTORED DATABASE + TRANSACTION LOG CORRECTLY------------------------------------------------------------------------

                $db_status=Invoke-Sqlcmd -ServerInstance localhost -Database master -SuppressProviderContextWarning $query_state_db
                $db_status=($db_status[0] | Out-String).Trim()
                #if (($db_status[0] | Out-String).Trim() -eq "ONLINE")
                if ($db_status -eq "ONLINE")
                {
                Write-Output "БД восстановлена, в состоянии: $db_status"
                'Время восстановления БД + цепочки файлов транзакций :'+ $time_res_total| out-file -Filepath $rezult -append
                Remove-Item $rest_db
                }

                else
                {
                Write-Output "БД НЕ восстановлена, в состоянии: $db_status"
                "БД не восстановлена, в состоянии: $db_status"| out-file -Filepath $rezult -append
                Remove-Item $rest_db
                exit
                }

            }#4_1
       }#3
       else
       {#3_1
                "Создать SQL скрипт БЕЗ цепочки файлов лога транзакций"
                $Files_y = Get-ChildItem -Recurse -Path $path_backup_files_Y -Include "*.bak"
                $Files_z = Get-ChildItem -Recurse -Path $path_backup_files_Z -Include "*.bak"

                'USE [master]' | out-file -Filepath $rest_db -append
                'RESTORE DATABASE ' + '['+ $NameDB +']' +' FROM ' | out-file -Filepath $rest_db -append
                'DISK=' + "`'" + $Files_y.fullName +  "`'," | out-file -Filepath $rest_db -append
                'DISK=' + "`'" + $Files_z.fullName +  "`'" + ' WITH  FILE = 1, NOUNLOAD, STATS = 5'+ "`n" | out-file -Filepath $rest_db -append
                'GO' | Out-File $rest_db  -append
                #-------------------------------------------------------RESTORE DATABASE WITHOUT TRANSACTION LOG--------------------------------------------------------------------------------------------

                $time_res_start = (Get-Date)
                Invoke-Sqlcmd -ServerInstance localhost -Querytimeout 0 -Database "master" -InputFile $rest_db -Verbose 2>&1 4>&1 | out-file -Filepath $rezult
                $time_res_stop = (Get-Date)
                $time_res_total=($time_res_stop-$time_res_start).ToString().Split('.')[0]

                #-------------------------------------------------------CHECKING RESTORED DATABASE ONLY CORRECTLY------------------------------------------------------------------------

                $db_status=Invoke-Sqlcmd -ServerInstance localhost -Database master -SuppressProviderContextWarning $query_state_db
                if (($db_status[0] | Out-String).Trim() -eq "ONLINE")
                {
                Write-Output "БД восстановлена, в состоянии: $db_status"
                'Время восстановления БД + цепочки файлов транзакций :'+ $time_res_total| out-file -Filepath $rezult -append
                Remove-Item $rest_db
                }

                else
                {
                Write-Output "БД НЕ восстановлена, в состоянии: $db_status"
                "БД не восстановлена, в состоянии: $db_status"| out-file -Filepath $rezult -append
                Remove-Item $rest_db
                exit
                }
       }#3_1

    }#2_1

}#1

else
{#1_1
    WriteLog "Папки Y или Z не существует"
}#1_1


$str_search_RES=(Get-Item -Path $rezult | Get-Content -Tail 3)
$str_search_RES= $str_search_RES | Out-String
$pattern_DB = "RESTORE DATABASE successfully"
$pattern_LOG = "RESTORE LOG successfully"
if (($str_search_RES -match $pattern_DB) -or ($str_search_RES -match $pattern_LOG))
#if ($str_search_RES -match $pattern_LOG)
{
    WriteLog "Восстановление БД: $NameDB завершено - Успешно"
    WriteLog $str_search_RES
    "----------------------------------------------------------"| out-file -Filepath $Logfile -append
}
else
{
    WriteLog "Восстановление БД: $NameDB завершено - с Ошибками"
    WriteLog $str_search_RES
    "----------------------------------------------------------"| out-file -Filepath $Logfile -append
}

$str_search=(Get-Item -Path $rezult | Get-Content -Tail 3)[-1]
$str_search
$pattern = $time_res_total
if ($str_search -match $pattern)
{

    #-------------------------------------------------------CHECKDB_WITH_PHYSICAL_ONLY--------------------------------------------------------------------------------------------------

    $watch = [System.Diagnostics.Stopwatch]::StartNew()
    $watch.Start() #Запуск таймера

    if (test-path $rezult_FO)
    {
    Remove-Item $rezult_FO
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

    #-------------------------------------------------------CHECKDB_WITH_EXTENDED_LOGICAL--------------------------------------------------------------------------------------------------

    $time_el_start = (Get-Date)
    if (test-path $rezult_EL)
    {
    Remove-Item $rezult_EL
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
}

else
{
Write-Output "Совпадение не найдено."
WriteLog "БД НЕ восстановлена, невозможно запустить SQL скрипты для проверки БД"
}

#-------------------------------------------------------DELETE TEMP LOG--------------------------------------------------------------------------------------------------
Remove-Item $rezult_EL
Remove-Item $rezult_FO
Remove-Item $rezult

#Write-Output "The value is[$Error]"

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


#Write-Output "The value is[$Error]"

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
    WriteLog "Удаление временных файлов завершено - Успешно"
}
else
{
"В процессе выполнения скрипта ошибок не обнаружено "
WriteLog "Удаление временных файлов завершено - Успешно"
"----------------------------------------------------------" | out-file -Filepath $Logfile -append
}
#Write-Output "The value is[$Error]"