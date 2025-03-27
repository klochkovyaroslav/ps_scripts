<#
.SYNOPSIS
Automates MSSQL database backup.
.DESCRIPTION
This script backup database "KAMAZ".
.VERSION
1.4 - Release -  Mar 2025 - Yaroslav Klochkov
#>
######################################################## RESTORE DATABASE And CHECK DB ##################################################################################################
#### Скрирт для запуска сервере SQL ---TC12-DB01---####

param(
    [string]$DatabaseName = "KAMAZ",
    [string]$BackupRoot = "R:\Backup",
    [string]$LogPath = (Join-Path (Split-Path -Parent $MyInvocation.MyCommand.Path) "All_Events.log")
)

$s_name = $env:COMPUTERNAME.Split("-")[0,1] -join "-"
$fullBackupPath = "$BackupRoot\$DatabaseName\Full"#Путь до директории с файлами бэкапа
$logBackupPath = "$BackupRoot\$DatabaseName\LOG"
#Дата с которой сравнивать. В этом случае -24 часа от текущей даты
$actual_date = (Get-Date).AddMinutes(-1438)
$ErrorActionPreference= "stop"

#-------------------------------------------------------Function for Write-Log-----------------------------------------------------------------------------------------------------------
function Write-Log {
    param(
    [string]$message,
    [switch]$NewLine
    )
    if ($NewLine) {
        $message += "`n"
    }
    "$((Get-Date).ToString('dd/MM/yyyy HH:mm:ss')) - $message" | Out-File -FilePath $LogPath -Append
}
$LogPath
#-------------------------------------------------------SQL QUERY LOG--------------------------------------------------------------------------------------------------------------------
$query_log = @"
DECLARE @DBName NVARCHAR(200)= '$DatabaseName'
DECLARE @RoleDesc NVARCHAR(60)
DECLARE @BackupPath NVARCHAR(200)='$logBackupPath\' + @DBName+'_LOG_' + REPLACE(convert(nvarchar(20),GetDate(),120),':','-') + '.trn'
DECLARE @NameJob NVARCHAR(200)= @DBName+'-log Database Backup'

BACKUP LOG @DBName TO  DISK = @BackupPath  WITH NOFORMAT, NOINIT,  NAME= @NameJob, SKIP, NOREWIND, NOUNLOAD,COMPRESSION,  STATS = 10
"@

# Начинаем backup
# Записываем действие в отладочный лог

Write-Log "-------------------------------------------------------------------------------------------------- "
Write-Log "--------------------- операция: создание РК: $s_name------------------------- "
Write-Log "-------------------------------------------------------------------------------------------------- " -NewLine

# Очистка файлов РК больше 24 часов
# Записываем действие начала очистки старых РК
Write-Log "операция: проверка актуальности файлов РК FULL"
# Проверяем старые файлы Full РК и удаляем соответствующие условиям.

if (test-path $fullBackupPath)
{
                if ( Get-ChildItem -Recurse -Path $fullBackupPath -Include "*.bak")
                {
					"Проверяем на соответствие прошедшего времени с момента создания файла"
					$Files = Get-ChildItem -Recurse -Path $fullBackupPath -Include "*.bak" | Where-Object -Property CreationTime -lt $actual_date
                        if ($null -eq $Files)
                        {
                            Write-Log "состояние: копия файлов РК FULL: актуальна "
                            Write-Log "операция: создание цепочки РК LOG "

					        # Создаём резервную копию LOG
                            Write-Log "начало выполнения SQL-скрипта: LOG-Backup "
                            if (-not(test-path $logBackupPath))
                            {
                             New-Item -Path $logBackupPath -ItemType Directory
							 Invoke-SqlQuery -Query $query_log
                             Write-Log "окончание выполнения SQL-скрипта: LOG-Backup " -NewLine
                            }
                            else
                            {
							Invoke-SqlQuery -Query $query_log
                            Write-Log "окончание выполнения SQL-скрипта: LOG-Backup " -NewLine
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
    Write-Log "состояние: директория $fullBackupPath : недоступна, будет автоматически создана"
    New-Item -Path $fullBackupPath -ItemType Directory
    Write-Log "операция: очистка каталогов на дисках: R, перед созданием новой цепочки FULL и LOG Backup "
    & C:\scripts\2_Del_all_files_dsk.ps1
}