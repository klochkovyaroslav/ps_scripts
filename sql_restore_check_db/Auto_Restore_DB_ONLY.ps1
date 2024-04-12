######################################################## RESTORE DATABASE And CHECK DB ##############################################################################################
$NameDB="PSE"

$tmp_f = $PSScriptRoot+"\tmp.txt"
$rest_db = $PSScriptRoot+"\restore_db.sql"
$rezult = $PSScriptRoot+"\RESTORE_SQL_REZULT.txt"
$path_backup_files_Y="Y:\$NameDB\"
$path_backup_files_Z="Z:\$NameDB\"
$path_backup_files_W="W:\$NameDB\"
$ErrorActionPreference= "Continue"
$Error.Clear()
Write-Output "The value is[$Error]"

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



                $query_state_db="SELECT state_desc
                FROM    sys.databases
                WHERE Name = '$NameDB'
                GO"

                $db_status=Invoke-Sqlcmd -ServerInstance localhost -Database master -SuppressProviderContextWarning $query_state_db
                #$db_status=($db_status[0] | Out-String).Trim()

                if (($db_status[0] | Out-String).Trim() -eq "ONLINE")

                {
                "БД восстановлена, в состоянии: $db_status"
                'Время восстановления БД + цепочки файлов транзакций : '+ $time_res_total| out-file -Filepath $rezult -append
                Remove-Item $rest_db
                }

                else
                {
                "БД не восстановлена, в состоянии: $db_status"
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
                Invoke-Sqlcmd -ServerInstance localhost -Querytimeout 0 -Database "master" -InputFile $rest_db -Verbose 4>&1 | out-file -Filepath $rezult
                $time_res_stop = (Get-Date)
                $time_res_total=($time_res_stop-$time_res_start).ToString().Split('.')[0]
                "`n"+'Время восстановления БД : '+ $time_res_total| out-file -Filepath $rezult -append
                Remove-Item $rest_db
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
#-------------------------------------------------------DELETE TEMP LOG--------------------------------------------------------------------------------------------------
del $rezult


#-------------------------------------------------------DELETE TEMP LOG FILES IF ERROR--------------------------------------------------------------------------------------------------
if ($Error)
{
"В процессе выполнения скрипта возникла ошибка"
WriteLog "Удаление временных файлов завершено - Успешно"
"----------------------------------------------------------" | out-file -Filepath $Logfile -append
    if (test-path $rezult_EL)
    {
    del $rezult_EL
    }
    if (test-path $rezult_FO)
    {
    del $rezult_FO
    }
    if (test-path $rezult)
    {
    del $rezult
    }
}
else
{
"В процессе выполнения скрипта ошибок не обнаружено "
WriteLog "Удаление временных файлов завершено - Успешно"
"----------------------------------------------------------" | out-file -Filepath $Logfile -append
}

Write-Output "The value is[$Error]"