#### Скрирт для запуска на сервере SQL - !!!---Если установлен ---Касперский KES--- и настроены политики исключений на сервере управления ####
$NameDB="PSC"

$path_backup_files_Y="Y:\$NameDB\" #Путь до директории с файлами бэкапа
$path_backup_files_Z="Z:\$NameDB\"
$path_backup_files_W="W:\$NameDB\"
$path_backup_log = "C:\Scripts\Full_events.txt" #Расположения лога выполнения скрипта						   
$SQL_FULL="C:\scripts\SQL_Full.sql"
$SQL_LOG="C:\scripts\SQL_LOG.sql"
$date_backup = Get-Date
$ErrorActionPreference= "stop"


# Удаляем все файлы с диска W:\PSC
(Get-Date).ToString()+" операция: - удаление всех файлов с диска W:\$NameDB " | out-file -Filepath $path_backup_log -append

# Проверяем существует ли путь W:\PSC
if (test-path $path_backup_files_W)
{
    $Files_w = Get-ChildItem -Recurse -Path $path_backup_files_W -Include "*.trn"  #Получаем список файлов LOG-backup для удаления
    ForEach ($x in $Files_w)
    {    
        try{
	    $filefordelete_W=$path_backup_files_W +$x.Name
            
            Remove-Item -Path $filefordelete_W -ErrorAction Stop
	        (Get-Date).ToString()+" - операция: файл: " + $x.Name+ " - Удален" | out-file -Filepath $path_backup_log -append
            }
        catch{
            (Get-Date).ToString()+" - операция: файл: " + $x.Name+ " - Ошибка: " + $_.Exception.Message | out-file -Filepath $path_backup_log -append
            } 
    }
}

Else
{
    # Если не существует путь W:\PSC
    (Get-Date).ToString()+" - Директория W:\$NameDB : Не существует, будет создана" | out-file -Filepath $path_backup_log -append
    New-Item -Path $path_backup_files_W -ItemType Directory  
         
} 

#---------------------------------------------------------------------------------------------------------------------------------------------------

# Удаляем все файлы с диска Y:\PSC
(Get-Date).ToString()+" операция: - удаление всех файлов с диска Y:\$NameDB " | out-file -Filepath $path_backup_log -append

# Проверяем существует ли путь Y:\PSC
if (test-path $path_backup_files_Y)
{
    $Files_y = Get-ChildItem -Recurse -Path $path_backup_files_Y -Include "*.bak"  #Получаем список файлов LOG-backup для удаления
    ForEach ($x in $Files_y)
    {    
        try{
	    $filefordelete_Y=$path_backup_files_Y +$x.Name
            
            Remove-Item -Path $filefordelete_Y -ErrorAction Stop
	        (Get-Date).ToString()+" - операция: файл: " + $x.Name + " - Удален" | out-file -Filepath $path_backup_log -append
            }
        catch{
            (Get-Date).ToString()+" - операция: файл: " + $x.Name+ " - Ошибка: " + $_.Exception.Message | out-file -Filepath $path_backup_log -append
            } 
    }
}

Else
{
    # Если не существует путь Y:\PSC
    (Get-Date).ToString()+" - Директория Y:\$NameDB : Не существует, будет создана" | out-file -Filepath $path_backup_log -append
    New-Item -Path $path_backup_files_Y -ItemType Directory  
     
}

#---------------------------------------------------------------------------------------------------------------------------------------------------

# Удаляем все файлы с диска Z:\PSC
(Get-Date).ToString()+" операция: - удаление всех файлов с диска Z:\$NameDB " | out-file -Filepath $path_backup_log -append

# Проверяем существует ли путь Z:\PSC
if (test-path $path_backup_files_Z)
{
    $Files_z = Get-ChildItem -Recurse -Path $path_backup_files_Z -Include "*.bak"  #Получаем список файлов LOG-backup для удаления
    ForEach ($x in $Files_z)
    {    
        try{
	    $filefordelete_Z=$path_backup_files_Z +$x.Name
            
            Remove-Item -Path $filefordelete_Z -ErrorAction Stop
	        (Get-Date).ToString()+" - операция: файл: " + $x.Name + " - Удален" | out-file -Filepath $path_backup_log -append
            }
        catch{
            (Get-Date).ToString()+" - операция: файл: " + $x.Name+ " - Ошибка: " + $_.Exception.Message | out-file -Filepath $path_backup_log -append
            } 
    }
}

Else
{
    # Если не существует путь Z:\PSC
    (Get-Date).ToString()+" - Директория Z:\$NameDB : Не существует, будет создана" | out-file -Filepath $path_backup_log -append
    New-Item -Path $path_backup_files_Z -ItemType Directory     
}


$date_backup = (Get-Date).tostring()
(Get-Date).ToString()+" операция: начало выполнения SQL-скрипта: FULL-Backup" | out-file -Filepath $path_backup_log -append
Invoke-Sqlcmd -ServerInstance localhost -Querytimeout 0 -Database $NameDB -InputFile $SQL_FULL
$date_backup = (Get-Date).tostring()
(Get-Date).ToString()+" операция: окончание выполнения SQL-скрипта: FULL-Backup" | out-file -Filepath $path_backup_log -append