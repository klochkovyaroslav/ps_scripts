#### Скрирт для запуска сервере SQL ---BW-PRD---####
$NameDB="BIP"

$a=$env:computername.split("-")[-0]
$b=$env:computername.split("-")[-1]
$s_name= $a+"-"+$b
$path_backup_files_Y="Y:\$NameDB" #Путь до директории с файлами бэкапа
$path_backup_log = "C:\Scripts\Full_events.txt" #Расположения лога выполнения скрипта
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

# Очистка файлов РК больше 24 часов
# Записываем действие начала очистки старых РК
(Get-Date).ToString()+" - операция: проверка актуальности файлов РК FULL " | out-file -Filepath $path_backup_log -append

# Проверяем старые файлы Full РК и удаляем соответствующие условиям.
if (test-path $path_backup_files_Y)

{

                if ( Get-ChildItem -Recurse -Path $path_backup_files_Y -Include "*.bak")
                {
					"Проверяем на соответствие прошедшего времени с момента создания файла"
					$Files = Get-ChildItem -Recurse -Path $path_backup_files_Y -Include "*.bak" | Where-Object -Property CreationTime -lt $actual_date

                        if ($null -eq $Files)
                        {
                            (Get-Date).ToString()+" - состояние: копия файлов РК FULL: актуальна " | out-file -Filepath $path_backup_log -append
					        (Get-Date).ToString()+" - операция: создание цепочки РК LOG " | out-file -Filepath $path_backup_log -append

					        # Создаём резервную копию LOG
					        (Get-Date).ToString()+" - начало выполнения SQL-скрипта: LOG-Backup  " | out-file -Filepath $path_backup_log -append
                            $path_backup_files_W="W:\$NameDB"
                            if (-not(test-path $path_backup_files_W))
                            {
                             New-Item -Path $path_backup_files_W -ItemType Directory
                             Invoke-Sqlcmd -ServerInstance localhost -Querytimeout 0 -Database $NameDB -InputFile $SQL_LOG
					         (Get-Date).ToString()+" - окончание выполнения SQL-скрипта: LOG-Backup  " +  "`n" | out-file -Filepath $path_backup_log -append
                            }
                            else
                            {
                            Invoke-Sqlcmd -ServerInstance localhost -Querytimeout 0 -Database $NameDB -InputFile $SQL_LOG
					        (Get-Date).ToString()+" - окончание выполнения SQL-скрипта: LOG-Backup  " +  "`n" | out-file -Filepath $path_backup_log -append
                            }
                        }

                        else
                            {
                               & C:\scripts\2_Del_all_files_dsk.ps1                            
                            }
                }
                else
                {
                  & C:\scripts\2_Del_all_files_dsk.ps1
                }
}
else
{
    (Get-Date).ToString()+" - состояние: директория $path_backup_files_Y : недоступна, будет автоматически создана" #| out-file -Filepath $path_backup_log -append
    New-Item -Path $path_backup_files_Y -ItemType Directory
	(Get-Date).ToString()+" - операция: очистка каталогов на дисках: Y, Z, W перед созданием новой цепочки FULL и LOG Backup " | out-file -Filepath $path_backup_log -append
    & C:\scripts\2_Del_all_files_dsk.ps1
}