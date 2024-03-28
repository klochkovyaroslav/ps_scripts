#### Скрирт для запуска на сервере SQL - !!!---Если установлен ---Касперский KES--- и настроены политики исключений на сервере управления ####
$NameDB_JIP="JIP"

$path_backup_files_Y_JIP="Y:\$NameDB_JIP\" #Путь до директории с файлами бэкапа
$path_backup_files_Z_JIP="Z:\$NameDB_JIP\"
$path_backup_files_W_JIP="W:\$NameDB_JIP\"
$path_backup_log = "C:\Scripts\Full_events.txt" #Расположения лога выполнения скрипта						   
$SQL_FULL="C:\scripts\JIP\SQL_Full.sql"
$SQL_LOG="C:\scripts\JIP\SQL_LOG.sql"
$date_backup = Get-Date
$ErrorActionPreference= "stop"


# Удаляем все файлы с диска W:\JIP
(Get-Date).ToString()+" операция: - удаление всех файлов с диска W:\$NameDB_JIP " | out-file -Filepath $path_backup_log -append

# Проверяем существует ли путь W:\JIP
if (test-path $path_backup_files_W_JIP)
{
    $Files_w_JIP = Get-ChildItem -Recurse -Path $path_backup_files_W_JIP -Include "*.trn"  #Получаем список файлов LOG-backup для удаления
    ForEach ($x in $Files_w_JIP)
    {    
        try{
	    $filefordelete_W_JIP=$path_backup_files_W_JIP +$x.Name
            
            Remove-Item -Path $filefordelete_W_JIP -ErrorAction Stop
	        (Get-Date).ToString()+" - операция: файл: " + $x.Name+ " - Удален" | out-file -Filepath $path_backup_log -append
            }
        catch{
            (Get-Date).ToString()+" - операция: файл: " + $x.Name+ " - Ошибка: " + $_.Exception.Message | out-file -Filepath $path_backup_log -append
            } 
    }
}

Else
{
    # Если не существует путь W:\JIP
    (Get-Date).ToString()+" - Директория W:\$NameDB_JIP : Не существует, будет создана" | out-file -Filepath $path_backup_log -append
    New-Item -Path $path_backup_files_W_JIP -ItemType Directory  
         
} 

#---------------------------------------------------------------------------------------------------------------------------------------------------

# Удаляем все файлы с диска Y:\JIP
(Get-Date).ToString()+" операция: - удаление всех файлов с диска Y:\$NameDB_JIP " | out-file -Filepath $path_backup_log -append

# Проверяем существует ли путь Y:\JIP
if (test-path $path_backup_files_Y_JIP)
{
    $Files_y_JIP = Get-ChildItem -Recurse -Path $path_backup_files_Y_JIP -Include "*.bak"  #Получаем список файлов LOG-backup для удаления
    ForEach ($x in $Files_y_JIP)
    {    
        try{
	    $filefordelete_Y_JIP=$path_backup_files_Y_JIP +$x.Name
            
            Remove-Item -Path $filefordelete_Y_JIP -ErrorAction Stop
	        (Get-Date).ToString()+" - операция: файл: " + $x.Name + " - Удален" | out-file -Filepath $path_backup_log -append
            }
        catch{
            (Get-Date).ToString()+" - операция: файл: " + $x.Name+ " - Ошибка: " + $_.Exception.Message | out-file -Filepath $path_backup_log -append
            } 
    }
}

Else
{
    # Если не существует путь Y:\JIP
    (Get-Date).ToString()+" - Директория Y:\$NameDB_JIP : Не существует, будет создана" | out-file -Filepath $path_backup_log -append
    New-Item -Path $path_backup_files_Y_JIP -ItemType Directory  
     
}

#---------------------------------------------------------------------------------------------------------------------------------------------------

# Удаляем все файлы с диска Z:\JIP
(Get-Date).ToString()+" операция: - удаление всех файлов с диска Z:\$NameDB_JIP " | out-file -Filepath $path_backup_log -append

# Проверяем существует ли путь Z:\JIP
if (test-path $path_backup_files_Z_JIP)
{
    $Files_z_JIP = Get-ChildItem -Recurse -Path $path_backup_files_Z_JIP -Include "*.bak"  #Получаем список файлов LOG-backup для удаления
    ForEach ($x in $Files_z_JIP)
    {    
        try{
	    $filefordelete_Z_JIP=$path_backup_files_Z_JIP +$x.Name
            
            Remove-Item -Path $filefordelete_Z_JIP -ErrorAction Stop
	        (Get-Date).ToString()+" - операция: файл: " + $x.Name + " - Удален" | out-file -Filepath $path_backup_log -append
            }
        catch{
            (Get-Date).ToString()+" - операция: файл: " + $x.Name+ " - Ошибка: " + $_.Exception.Message | out-file -Filepath $path_backup_log -append
            } 
    }
}

Else
{
    # Если не существует путь Z:\JIP
    (Get-Date).ToString()+" - Директория Z:\$NameDB_JIP : Не существует, будет создана" | out-file -Filepath $path_backup_log -append
    New-Item -Path $path_backup_files_Z_JIP -ItemType Directory     
}


$date_backup = (Get-Date).tostring()
(Get-Date).ToString()+" операция: начало выполнения SQL-скрипта: FULL-Backup" | out-file -Filepath $path_backup_log -append
Invoke-Sqlcmd -ServerInstance localhost -Querytimeout 0 -Database $NameDB_JIP -InputFile $SQL_FULL
$date_backup = (Get-Date).tostring()
(Get-Date).ToString()+" операция: окончание выполнения SQL-скрипта: FULL-Backup" | out-file -Filepath $path_backup_log -append