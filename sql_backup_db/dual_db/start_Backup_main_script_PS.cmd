powershell.exe -executionpolicy bypass -file "C:\scripts\JIP\1_Backup_main_script.ps1" && TIMEOUT /T 10 /NOBREAK>nul && powershell.exe -executionpolicy bypass -file "C:\scripts\1_Backup_main_script.ps1"
if %errorlevel% gtr 0 exit

