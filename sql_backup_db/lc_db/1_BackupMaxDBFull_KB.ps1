 #### Скрирт для запуска на ---LC-PRD---####
$NameDB="LCP"


$s_name= $NameDB+"-Backup"
$path_backup_full="Y:\$NameDB" #Путь до директории с файлами бэкапа full
$path_backup_log= "Z:\$NameDB" #Путь до директории с файлами бэкапа log
$path_backup_events= "C:\Scripts\Full_Events.txt" #Расположения лога выполнения скрипта
$tempfile="C:\Scripts\temp.txt"
$date_backup = Get-Date
$prog="C:\Program Files (x86)\SDB\DBM\dbmcli" #определение утилиты для выполнения бэкапа
# Конфигурация  FULL-backup
$backfilename_full=$path_backup_full+"\LCP_FULL_"+$date_backup.Year+$date_backup.Month.ToString().Padleft(2,"0")+$date_backup.Day.ToString().Padleft(2,"0")+$date_backup.Hour.ToString().padleft(2,"0")+$date_backup.Minute.ToString().padleft(2,"0")+$date_backup.Second.ToString().padleft(2,"0")+$date_backup.Millisecond.tostring().Substring(0,2).padleft(2,"0")+".bak"
$args1=@('-u','control,LCP$2WSX','-d','LCP','medium_put','LCP_BAKUP_FULL',$backfilename_full,'FILE','DATA','0','8','YES') #определение аргументов команды для настройки целевого устройства бэкапа 
$args2=@('-u','control,LCP$2WSX','-d','LCP','-uUTL','-c','backup_start','LCP_BAKUP_FULL','DATA') #определение аргументов команды запуска процесса бэкапа
# Конфигурация  LOG-backup
$backfilename_log=$path_backup_log +"\LCP_LOG" #Директория расположения бэкапов
$args3=@('-u','control,LCP$2WSX','-d','LCP','medium_put','LCP_BAKUP_LOG',$backfilename_log,'FILE','LOG') #определение аргументов команды для настройки целевого устройства бэкапа 
$args4=@('-u','control,LCP$2WSX','-d','LCP','-uUTL','-c','backup_start','LCP_BAKUP_LOG','LOG') #определение аргументов команды запуска процесса бэкапа
#Дата с которой сравнивать. В этом случае -24 часа от текущей даты
$actual_date = (Get-Date).AddMinutes(-1438)
$ErrorActionPreference= "stop"


# Начинаем backup
# Записываем действие в отладочный лог
" - ----------------------------------------------------------------------------------------------- " | out-file -Filepath $path_backup_events -append
(Get-Date).ToString()+" - -------------------- операция: создание РК: $s_name------------------------ "  | out-file -Filepath $path_backup_events -append
" - ----------------------------------------------------------------------------------------------- " +  "`n" | out-file -Filepath $path_backup_events -append

# Очистка файлов РК больше 24 часов
# Записываем действие начала очистки старых РК
(Get-Date).ToString()+" - операция: проверка актуальности файлов РК FULL " | out-file -Filepath $path_backup_events -append

# Проверяем старые файлы Full РК и удаляем соответствующие условиям.
if (test-path $path_backup_full)

{

                if ( Get-ChildItem -Recurse -Path $path_backup_full -Include "*.bak")
                {
					"Проверяем на соответствие прошедшего времени с момента создания файла"
					$Files = Get-ChildItem -Recurse -Path $path_backup_full -Include "*.bak" | Where-Object -Property CreationTime -lt $actual_date

                        if ($null -eq $Files)
                        {
                            (Get-Date).ToString()+" - состояние: копия файлов РК FULL: актуальна " | out-file -Filepath $path_backup_events -append
					        (Get-Date).ToString()+" - операция: создание цепочки РК LOG " | out-file -Filepath $path_backup_events -append

					        # Создаём резервную копию LOG
                            (Get-Date).ToString()+" операция: начало выполнения: LOG-Backup" | out-file -Filepath $path_backup_events -append
                            $path_backup_log="Z:\$NameDB"
                            if (-not(test-path $path_backup_log))
                            {
                             New-Item -Path $path_backup_log -ItemType Directory
                            & $prog $args3 | Out-File -Filepath $tempfile
                              $out1=(get-content $tempfile)
                              $out1 | Out-File -Filepath $path_backup_events -append
                              & $prog $args4 | Out-File -Filepath $tempfile
                              $out2=(get-content $tempfile)
                              $out2 | Out-File -Filepath $path_backup_events -append
                              (Get-Date).ToString()+" операция: окончание выполнения: LOG-Backup"  +  "`n" | out-file -Filepath $path_backup_events -append

                            }
                            else
                            {
                            & $prog $args3 | Out-File -Filepath $tempfile
                              $out1=(get-content $tempfile)
                              $out1 | Out-File -Filepath $path_backup_events -append
                              & $prog $args4 | Out-File -Filepath $tempfile
                              $out2=(get-content $tempfile)
                              $out2 | Out-File -Filepath $path_backup_events -append
                              (Get-Date).ToString()+" операция: окончание выполнения: LOG-Backup"  +  "`n" | out-file -Filepath $path_backup_events -append
                            }
                        }

                        else
                            {
                               & C:\scripts\2_Del_all_files_dsk_LC.ps1                            
                            }
                }
                else
                {
                  & C:\scripts\2_Del_all_files_dsk_LC.ps1
                }
}
else
{
    (Get-Date).ToString()+" - состояние: директория $path_backup_full : недоступна, будет автоматически создана" #| out-file -Filepath $path_backup_events -append
    New-Item -Path $path_backup_full -ItemType Directory
	(Get-Date).ToString()+" - операция: очистка каталогов на дисках: Y, Z перед созданием новой цепочки FULL и LOG Backup " | out-file -Filepath $path_backup_events -append
    & C:\scripts\2_Del_all_files_dsk_LC.ps1
}