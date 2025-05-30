﻿#### Скрирт для запуска на ---LC-PRD---####
$NameDB="LCP"

$path_backup_full="Y:\$NameDB" #Путь до директории с файлами бэкапа full
$path_backup_log= "Z:\$NameDB" #Путь до директории с файлами бэкапа log
$path_backup_events= "C:\Scripts\Full_Events.txt" #Расположения лога выполнения скрипта
$tempfile="C:\Scripts\temp.txt"
# Конфигурация  FULL-backup
$prog="C:\Program Files (x86)\SDB\DBM\dbmcli" #определение утилиты для выполнения бэкапа
$backfilename_full=$path_backup_full+"\LCP_FULL_"+$date_backup.Year+$date_backup.Month.ToString().Padleft(2,"0")+$date_backup.Day.ToString().Padleft(2,"0")+$date_backup.Hour.ToString().padleft(2,"0")+$date_backup.Minute.ToString().padleft(2,"0")+$date_backup.Second.ToString().padleft(2,"0")+$date_backup.Millisecond.tostring().Substring(0,2).padleft(2,"0")+".bak"
$args1=@('-u','control,LCP$2WSX','-d','LCP','medium_put','LCP_BAKUP_FULL',$backfilename_full,'FILE','DATA','0','8','YES') #определение аргументов команды для настройки целевого устройства бэкапа 
$args2=@('-u','control,LCP$2WSX','-d','LCP','-uUTL','-c','backup_start','LCP_BAKUP_FULL','DATA') #определение аргументов команды запуска процесса бэкапа
$date_backup = Get-Date
$ErrorActionPreference= "stop"


# Удаляем все файлы с диска Y:\LCP
(Get-Date).ToString()+" - Удаление всех файлов с диска Y:\" +$NameDB | out-file -Filepath $path_backup_events -append

# Проверяем существует ли путь Y:\LCP
if (test-path $path_backup_full)
{          
            $Files_y = Get-ChildItem -Recurse -Path $path_backup_full -file | % { $_.FullName } | Out-String  #Получаем список файлов LOG-backup для удаления
            "-------------------------------------- "+ "`n" + (Get-Date).ToString()+" - список файлов которые были удалены " +  "`n"+ $Files_y +"-------------------------------------- " | out-file -Filepath $path_backup_events -append
            Start-Process -FilePath "$env:comspec" -ArgumentList "/c del /q $path_backup_full"
            }

Else
{
    # Если не существует путь Y:\LCP
    (Get-Date).ToString()+" - Директория Y:\LCP : Не существует, будет создана" | out-file -Filepath $path_backup_events -append
 
     
}

#---------------------------------------------------------------------------------------------------------------------------------------------------

# Удаляем все файлы с диска Z:\LCP
(Get-Date).ToString()+" - Удаление всех файлов с диска Z:\" +$NameDB | out-file -Filepath $path_backup_events -append

# Проверяем существует ли путь Z:\LCP
if (test-path $path_backup_log)
{          
            $Files_z = Get-ChildItem -Recurse -Path $path_backup_log -file | % { $_.FullName } | Out-String  #Получаем список файлов LOG-backup для удаления
            "-------------------------------------- "+ "`n" + (Get-Date).ToString()+" - список файлов которые были удалены " +  "`n"+ $Files_z +"-------------------------------------- " | out-file -Filepath $path_backup_events -append
            Start-Process -FilePath "$env:comspec" -ArgumentList "/c del /q $path_backup_log"
            }

Else
{
    # Если не существует путь Z:\LCP
    (Get-Date).ToString()+" - Директория Z:\LCP : Не существует, будет создана" | out-file -Filepath $path_backup_events -append
    
}
# Создаём резервную копию на диск Y
$date_backup = (Get-Date).tostring()
(Get-Date).ToString()+" операция: начало выполнения: FULL-Backup" | out-file -Filepath $path_backup_events -append
$out1 = & $prog $args1 | Out-File -Filepath $path_backup_events -append
& $prog $args2 | Out-File -Filepath $tempfile
$out2=(get-content $tempfile)
$out2 | Out-File -Filepath $path_backup_events -append
$date_backup = (Get-Date).tostring()
(Get-Date).ToString()+" операция: окончание выполнения: FULL-Backup" | out-file -Filepath $path_backup_events -append
