$NameDB="RLM"


Clear-Variable -Name "db_status"
#-------------------------------------------------------CREATE SQL-CHECK-STATUS SCRIPT---------------------------------------------------------------------------------------------------
$query_state_db="SELECT state_desc
FROM sys.databases
WHERE Name = '$NameDB'
GO"
#----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------


$query_del_db="EXEC msdb.dbo.sp_delete_database_backuphistory @database_name = '$NameDB'
GO
use [$NameDB];
GO
use [master];
GO
USE [master]
GO
ALTER DATABASE [$NameDB] SET  SINGLE_USER WITH ROLLBACK IMMEDIATE
GO
USE [master]
GO
DROP DATABASE [$NameDB]
GO"

#----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

$query_del_db_restoring="EXEC msdb.dbo.sp_delete_database_backuphistory @database_name = '$NameDB'
GO
USE [master]
GO
DROP DATABASE [$NameDB]
GO"

#----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

#-------------------------------------------------------CREATE SQL-CHECK-STATUS SCRIPT---------------------------------------------------------------------------------------------------
$query_state_db="SELECT state_desc
FROM sys.databases
WHERE Name = '$NameDB'
GO"

$db_status=Invoke-Sqlcmd -ServerInstance localhost -Database master -SuppressProviderContextWarning $query_state_db
$db_status=($db_status[0] | Out-String).Trim()

if ($db_status -eq "ONLINE")
{
"Состояниие БД: $db_status"
Invoke-Sqlcmd -ServerInstance localhost -Database $NameDB -SuppressProviderContextWarning $query_del_db
"Удаление БД: $NameDB завершено - Успешно"
}

else
{
"Состояниие БД: $db_status"
Invoke-Sqlcmd -ServerInstance localhost -Database master -SuppressProviderContextWarning $query_del_db_restoring
"Удаление БД: $NameDB завершено - Успешно"
}