$NameDB="PSE"

<#
$query = "EXEC msdb.dbo.sp_delete_database_backuphistory @database_name = $NameDB
GO
USE [master]
GO
DROP DATABASE [$NameDB]
GO"
$query
Invoke-Sqlcmd -ServerInstance localhost -Database $NameDB -SuppressProviderContextWarning $query
#>



$query="EXEC msdb.dbo.sp_delete_database_backuphistory @database_name = '$NameDB'
GO
use [$NameDB];
GO
use [master];
GO
USE [master]
GO
ALTER DATABASE [$NameDB] SET SINGLE_USER WITH ROLLBACK IMMEDIATE
GO
USE [master]
GO
DROP DATABASE [$NameDB]
GO"
Invoke-Sqlcmd -ServerInstance localhost -Database master -SuppressProviderContextWarning $query
