powershell.exe -executionpolicy bypass -file "C:\Scripts\1_BackupMaxDBFull_KB.ps1"
if %errorlevel% gtr 0 exit
