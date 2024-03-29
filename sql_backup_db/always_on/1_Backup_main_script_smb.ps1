#### Скрирт для запуска на ноде кластера Always On ---SQL-TST-DB1---####
$remote_host="SQL-TST-DB2"
$NameDB="PSC"



$a=$env:compuPSCname.split("-")[-0]
$b=$env:compuPSCname.split("-")[-2]
$s_name= $a+"-"+$b
$path_backup_files_Y="Y:\$NameDB" #Путь до директории с файлами бэкапа
$path_backup_log = "C:\Scripts\Full_events.txt" #Расположения лога выполнения скрипта
$smb_path_backup_files_Y="\\$remote_host\Y$\$NameDB\"
$SQL_FULL="C:\scripts\SQL_Full.sql"
$SQL_LOG="C:\scripts\SQL_LOG.sql"
#Дата с которой сравнивать. В этом случае -24 часа от текущей даты
$actual_date = (Get-Date).AddMinutes(-1438)
$ErrorActionPreference= "stop"



# Начинаем backup
# Записываем действие в отладочный лог
" - ----------------------------------------------------------------------------------------------- " | out-file -Filepath $path_backup_log -append
(Get-Date).ToString()+" - -------------------- операция: создание РК: $s_name------------------------ "  | out-file -Filepath $path_backup_log -append
" - ----------------------------------------------------------------------------------------------- " +  "`n" | out-file -Filepath $path_backup_log -append

$query = "SELECT a.role_desc
FROM sys.dm_hadr_availability_replica_states AS a
JOIN sys.availability_replicas AS b
ON b.replica_id = a.replica_id
WHERE b.replica_server_name = UPPER(@@ServerName)"

$availability_replica = Invoke-Sqlcmd -ServerInstance localhost -Database "master" -SuppressProviderContextWarning $query

if (($availability_replica[0]) -eq "PRIMARY")
{


# Очистка файлов РК больше 24 часов
# Записываем действие начала очистки старых РК
(Get-Date).ToString()+" - операция: проверка актуальности файлов РК FULL " | out-file -Filepath $path_backup_log -append


# Проверяем старые файлы Full РК и удаляем соответствующие условиям.
if (test-path $path_backup_files_Y)

{
        if((Get-ChildItem -Path $path_backup_files_Y | Measure-Object).Count -eq 0) #проверка пуста ли папка?

            {
                (Get-Date).ToString()+" - состояние: директория на сервере " + $env:computername.ToString() + "$path_backup_files_Y - пуста" | out-file -Filepath $path_backup_log -append
                # Монтируем временно диск Q
                New-PSDrive -name Q -psprovider FileSystem -root $smb_path_backup_files_Y
                (Get-Date).ToString()+" - операция: смонтирован диск: Q" | out-file -Filepath $path_backup_log -append

                # Проверяем файлы Full РК на сетевой папке диска: Y другого сервера кластера АО.
                if (test-path Q:\) #проверка существует ли сетевая папка на диске Y: на сервере
                    {
                    if((Get-ChildItem -Path Q:\ | Measure-Object).Count -eq 0) #Пуста ли папка на SMB$ второго сервера
                        {
                        (Get-Date).ToString()+" - состояние: директория на сервере $remote_host - пуста" | out-file -Filepath $path_backup_log -append
						(Get-Date).ToString()+" - начало выполнения SQL-скрипта: FULL-Backup  " | out-file -Filepath $path_backup_log -append

                        Invoke-Sqlcmd -ServerInstance localhost -Querytimeout 0 -Database $NameDB -InputFile $SQL_FULL
						(Get-Date).ToString()+" - окончание выполнения FULL-скрипта: LOG-Backup  " | out-file -Filepath $path_backup_log -append
                        }
                   else
                        {
                         # Проверяем на соответствие прошедшего времени с момента создания файла"
                         $Files_smb = Get-ChildItem -Recurse -Path Q:\ -Include "*.bak" | Where-Object -Property CreationTime -lt $actual_date

                            if (-not($null -eq $Files_smb))
                            {
					        (Get-Date).ToString()+" - состояние: копия файлов РК FULL на сервере: " + $env:computername.ToString() + " устарела: $Files" | out-file -Filepath $path_backup_log -append
					        (Get-Date).ToString()+" - операция: очистка каталогов на дисках: Y, Z, W перед созданием новой цепочки FULL и LOG Backup " | out-file -Filepath $path_backup_log -append
                            & C:\scripts\2_Del_all_files_dsk.ps1
                            }
                            else
                            {
                            # Создаём резервную копию LOG
                            $path_backup_files_W="W:\$NameDB"
                            if (-not(test-path $path_backup_files_W))
                            {
                             New-Item -Path $path_backup_files_W -ItemType Directory
                            }
							(Get-Date).ToString()+" - начало выполнения SQL-скрипта: LOG-Backup  " | out-file -Filepath $path_backup_log -append
							Invoke-Sqlcmd -ServerInstance localhost -Querytimeout 0 -Database $NameDB -InputFile $SQL_LOG
							(Get-Date).ToString()+" - окончание выполнения SQL-скрипта: LOG-Backup " +  "`n" | out-file -Filepath $path_backup_log -append
                            }
                        }
               }

               Start-Sleep -Seconds 10
               Remove-PSDrive -Name Q
               (Get-Date).ToString()+" - операция: отмонтирован диск: Q" +  "`n" | out-file -Filepath $path_backup_log -append            
            }

        else
            {
             "Проверяем на соответствие прошедшего времени с момента создания файла"
            # "Проверяем на соответствие прошедшего времени с момента создания файла"
            $Files = Get-ChildItem -Recurse -Path $path_backup_files_Y -Include "*.bak" | Where-Object -Property CreationTime -lt $actual_date
            $Files

                if (-not($null -eq $Files))
                    {
					(Get-Date).ToString()+" - состояние: копия файлов РК FULL: устарела: $Files" | out-file -Filepath $path_backup_log -append
					(Get-Date).ToString()+" - операция: очистка каталогов на дисках: Y, Z, W перед созданием новой цепочки FULL и LOG Backup " | out-file -Filepath $path_backup_log -append
                    & C:\scripts\2_Del_all_files_dsk.ps1

                    }
                    else
                    {
					(Get-Date).ToString()+" - состояние: копия файлов РК FULL: актуальна " | out-file -Filepath $path_backup_log -append
					(Get-Date).ToString()+" - операция: создание цепочки РК LOG " | out-file -Filepath $path_backup_log -append

					# Создаём резервную копию LOG
                    $path_backup_files_Y="Y:\$NameDB"
                    $NameDB=$path_backup_files_Y.Split("\")[-1]
					(Get-Date).ToString()+" - начало выполнения SQL-скрипта: LOG-Backup  " | out-file -Filepath $path_backup_log -append
                    $path_backup_files_W="W:\$NameDB"
                    if (-not(test-path $path_backup_files_W))
                    {
                     New-Item -Path $path_backup_files_W -ItemType Directory
                    }
                    else
                    {
                    Invoke-Sqlcmd -ServerInstance localhost -Querytimeout 0 -Database $NameDB -InputFile $SQL_LOG
					(Get-Date).ToString()+" - окончание выполнения SQL-скрипта: LOG-Backup  " +  "`n" | out-file -Filepath $path_backup_log -append
                    }
                    }
        }
}
else
{
    (Get-Date).ToString()+" - состояние: директория $path_backup_files_Y : недоступна, будет автоматически создана" | out-file -Filepath $path_backup_log -append
    New-Item -Path $path_backup_files_Y -ItemType Directory
	(Get-Date).ToString()+" - операция: очистка каталогов на дисках: Y, Z, W перед созданием новой цепочки FULL и LOG Backup " | out-file -Filepath $path_backup_log -append
    & C:\scripts\2_Del_all_files_dsk.ps1
}

}
else
{
(Get-Date).ToString()+" - состояние: создание копии РК не производилось - Always On AG реплика: "+ ($availability_replica[0]) | out-file -Filepath $path_backup_log -append
}