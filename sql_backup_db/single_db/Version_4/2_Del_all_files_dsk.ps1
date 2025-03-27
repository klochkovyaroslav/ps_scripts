<#
.SYNOPSIS
Automates MSSQL database backup.
.DESCRIPTION
This script delete old backup files and start new backup operation for database "KAMAZ".
.VERSION
1.4 - Release -  Mar 2025 - Yaroslav Klochkov
#>
#### Скрирт для запуска на сервере SQL - !!!---Если установлен ---Касперский KES--- и настроены политики исключений на сервере управления ####

param(
    [string]$LogPath = "C:\Scripts\Full_events.txt",
    [string]$DatabaseName = "KAMAZ",
    [string]$BackupRoot = "R:\Backup"
)

$ErrorActionPreference = "Stop"
$currentDate = Get-Date
$fullBackupPath = "$BackupRoot\$DatabaseName\FULL"
$logBackupPath = "$BackupRoot\$DatabaseName\LOG"

#-------------------------------------------------------Function for Write-Log-----------------------------------------------------------------------------------------------------------
function Write-Log {
    param([string]$message)
    "$((Get-Date).ToString('dd/MM/yyyy HH:mm:ss')) - $message" | Out-File -FilePath $LogPath -Append
}

#-------------------------------------------------------Function for Initialize-BackupDirector-------------------------------------------------------------------------------------------
function Initialize-BackupDirectory {
    param([string]$path)
    if (-not (Test-Path $path)) {
        try {
            New-Item -Path $path -ItemType Directory -ErrorAction Stop | Out-Null
            Write-Log "Created directory: $path"
            return $true
        }
        catch {
            Write-Log "ERROR: Failed to create directory $path - $_"
            return $false
        }
    }
    return $true
}

#-------------------------------------------------------Function for Remove Old Backups--------------------------------------------------------------------------------------------------
function Remove-OldBackups {
    param([string]$path, [string]$filter)
    try {
        $files = Get-ChildItem -Path $path -Filter $filter -Recurse -ErrorAction Stop
        if ($files) {
            ForEach ($file in $files)
            {
                $file | Remove-Item -Force -ErrorAction Stop
                $currentDate = Get-Date
                Write-Log "операция: файл:  $($file.name) - Удален"
            }
        }
        else {
            Write-Log "No $filter files found in $path"
        }
        return $true
    }
    catch {
        Write-Log "ERROR: Failed to remove $filter files from $path - $_"
        return $false
    }
}
#-------------------------------------------------------Remove Files---------------------------------------------------------------------------------------------------------------------
    if (Initialize-BackupDirectory $fullBackupPath) {
        Remove-OldBackups -path $fullBackupPath -filter "*.bak"
    }
    if (Initialize-BackupDirectory $logBackupPath) {
        Remove-OldBackups -path $logBackupPath -filter "*.trn"
    }
#-------------------------------------------------------SQL QUERY FULL-------------------------------------------------------------------------------------------------------------------
$query_full = @"
DECLARE @DBName NVARCHAR(200)= '$DatabaseName'
DECLARE @BackupPath NVARCHAR(200)='$fullBackupPath\' + @DBName+'_FULL_' + REPLACE(CONVERT(NVARCHAR(20),GETDATE(),120),':','-') + '.bak'
DECLARE @NameJob NVARCHAR(200)= @DBName+'-Full Database Backup'

BACKUP DATABASE @DBName TO DISK = @BackupPath
WITH 
BLOCKSIZE=65536,BUFFERCOUNT=1000,MAXTRANSFERSIZE=4194304, NOFORMAT, INIT, NAME = @NameJob, SKIP, NOREWIND, NOUNLOAD, COMPRESSION, STATS = 10
"@
Write-Log "операция: начало выполнения SQL-скрипта: FULL-Backup"
Invoke-SqlQuery -Query $query_full
Write-Log "операция: окончание выполнения SQL-скрипта: FULL-Backup"