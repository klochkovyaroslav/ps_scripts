#### Скрирт для запуска на сервере SQL - !!!---Если установлен ---Касперский KES--- ####
$NameDB="PSE"

$path_backup_files_Y="Y:\$NameDB\" #Путь до директории с файлами бэкапа
$path_backup_files_Z="Z:\$NameDB\"
$path_backup_files_W="W:\$NameDB\"
$path_backup_log = "C:\Scripts\Full_events.txt" #Расположения лога выполнения скрипта						   
$SQL_FULL="C:\scripts\SQL_Full.sql"
$SQL_LOG="C:\scripts\SQL_LOG.sql"
$date_backup = Get-Date
$ErrorActionPreference= "stop"

# Удаляем все файлы с диска W:\PSE
(Get-Date).ToString()+" операция: - удаление всех файлов с диска W:\$NameDB " | out-file -Filepath $path_backup_log -append

# Проверяем существует ли путь W:\PSE
if (test-path $path_backup_files_W)
{          

            $Files_w = Get-ChildItem -Recurse -Path $path_backup_files_W -file | % { $_.FullName } | Out-String  #Получаем список файлов LOG-backup для удаления
            "-------------------------------------- "+ "`n" + (Get-Date).ToString()+" - список файлов которые были удалены " +  "`n"+ $Files_w +"-------------------------------------- " | out-file -Filepath $path_backup_log -append
            Start-Process -FilePath "$env:comspec" -ArgumentList "/c del /q $path_backup_files_W"
            }

Else
{
    # Если не существует путь W:\PSE
    (Get-Date).ToString()+" - Директория W:\$NameDB : Не существует, будет создана" | out-file -Filepath $path_backup_log -append
    New-Item -Path $path_backup_files_W -ItemType Directory | Out-Null  
         
} 

#---------------------------------------------------------------------------------------------------------------------------------------------------

# Удаляем все файлы с диска Y:\PSE
(Get-Date).ToString()+" операция: - удаление всех файлов с диска Y:\$NameDB " | out-file -Filepath $path_backup_log -append

# Проверяем существует ли путь Y:\PSE
if (test-path $path_backup_files_Y)
{          
            $Files_y = Get-ChildItem -Recurse -Path $path_backup_files_Y -file | % { $_.FullName } | Out-String  #Получаем список файлов LOG-backup для удаления
            "-------------------------------------- "+ "`n" + (Get-Date).ToString()+" - список файлов которые были удалены " +  "`n"+ $Files_y +"-------------------------------------- " | out-file -Filepath $path_backup_log -append
            Start-Process -FilePath "$env:comspec" -ArgumentList "/c del /q $path_backup_files_Y"
            }

Else
{
    # Если не существует путь Y:\PSE
    (Get-Date).ToString()+" - Директория Y:\$NameDB : Не существует, будет создана" | out-file -Filepath $path_backup_log -append
    New-Item -Path $path_backup_files_Y -ItemType Directory | Out-Null  
     
}

#---------------------------------------------------------------------------------------------------------------------------------------------------

# Удаляем все файлы с диска Z:\PSE
(Get-Date).ToString()+" операция: - удаление всех файлов с диска Z:\$NameDB " | out-file -Filepath $path_backup_log -append

# Проверяем существует ли путь Z:\PSE
if (test-path $path_backup_files_Z)
{          
            $Files_z = Get-ChildItem -Recurse -Path $path_backup_files_Z -file | % { $_.FullName } | Out-String  #Получаем список файлов LOG-backup для удаления
            "-------------------------------------- "+ "`n" + (Get-Date).ToString()+" - список файлов которые были удалены " +  "`n"+ $Files_z +"-------------------------------------- " | out-file -Filepath $path_backup_log -append
            Start-Process -FilePath "$env:comspec" -ArgumentList "/c del /q $path_backup_files_Z"
            }

Else
{
    # Если не существует путь Z:\PSE
    (Get-Date).ToString()+" - Директория Z:\$NameDB : Не существует, будет создана" | out-file -Filepath $path_backup_log -append
    New-Item -Path $path_backup_files_Z -ItemType Directory | Out-Null     
}


$date_backup = (Get-Date).tostring()
(Get-Date).ToString()+" операция: начало выполнения SQL-скрипта: FULL-Backup" | out-file -Filepath $path_backup_log -append
Invoke-Sqlcmd -ServerInstance localhost -Querytimeout 0 -Database $NameDB -InputFile $SQL_FULL
$date_backup = (Get-Date).tostring()
(Get-Date).ToString()+" операция: окончание выполнения SQL-скрипта: FULL-Backup" | out-file -Filepath $path_backup_log -append