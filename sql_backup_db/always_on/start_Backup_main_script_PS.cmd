powershell.exe -executionpolicy bypass -file "C:\scripts\1_Backup_main_script_smb.ps1"
if %errorlevel% gtr 0 exit

