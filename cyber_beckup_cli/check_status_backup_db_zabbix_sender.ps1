$name_srv="my-server"
#$p_loc="\\192.168.2.20\SQL-PRD-SRC1-r60\"
$p_loc="bsp://SRC01/SQLTST-SRC01"
$day_week="Saturday"

$mon_host=$name_srv +".mydomain.org"
$cred="user_backup,xh/jPO8NNCde71oQLxFgHNj1MOs3zHj9v96kUx0TDaLxLjbQHtA==,encrypted"
$zabbix_server="192.168.2.200"
$actual_date = Get-Date -Format d
$date_week=(((Get-Date -Format "dd")-7)..(Get-Date -Format "dd") | %{[datetime]::new((Get-Date -Format "yyyy"),(Get-Date -Format "MM"),$_)} |
 select @{n='Date';e={$_}}, @{n='DayOfWeek'; e={$_.DayOfWeek}} | where DayOfWeek -eq $day_week  | Select-Object -expandproperty Date).Tostring('dd.MM.yyyy')
$ZS = "C:\Program Files\Zabbix Agent\zabbix_sender.exe"
#---------------------------------------------------------------------------------------------------------------------------------------------------------

$list_archives=((& acrocmd.exe list archives --loc=$p_loc --credentials=$cred --output=raw).Split('	') | Select-String -Pattern $name_srv)[0]

$list_all_backups=(& acrocmd.exe list backups --loc=$p_loc --credentials=$cred --arc=$list_archives --filter_date=$actual_date --output=raw)
$list_all_full_backups=(& acrocmd.exe list backups --loc=$p_loc --credentials=$cred --arc=$list_archives --filter_date=$actual_date --filter_type=full --output=raw)
$list_inc_backup=(& acrocmd.exe list backups --loc=$p_loc --credentials=$cred --arc=$list_archives --filter_type=incremental --filter_date=$actual_date --output=raw)
$list_week_full_backups=(& acrocmd.exe list backups --loc=$p_loc --credentials=$cred --arc=$list_archives --filter_type=full --filter_date=$date_week --output=raw)
$last_full_backup=$list_all_full_backups[-3]
$list_week_full_backups
$last_full_backup
$date_last_backup=($list_all_backups[-3].Split('	')[3]).Split(' ')[0]

if ($date_last_backup -eq $actual_date)
{
& $ZS @('-z', $zabbix_server, '-p', '10051', '-s', $mon_host, '-k', 'backup_state', '-o', "1")
    if (-not($null -eq $last_full_backup))
    {
    #$date_last_FULL_backup=($list_all_full_backups.Split('	')[3]).Split(' ')[0]

    $size_full_backup=($last_full_backup.Split('	')[4].Split(' ')[0]) -replace '[^0-9]+', ""
    & $ZS @('-z', $zabbix_server, '-p', '10051', '-s', $mon_host, '-k', 'backup_db_full_size', '-o', $size_full_backup)
    $size_inc_backup=($list_inc_backup[-3].Split('	')[4].Split(' ')[0]) -replace '[^0-9]+', ""
    & $ZS @('-z', $zabbix_server, '-p', '10051', '-s', $mon_host, '-k', 'backup_db_increment_size', '-o', $size_inc_backup)
    }
    else
    {
    #$date_last_FULL_backup=($list_yesterday_full_backups.Split('	')[3]).Split(' ')[0]
    $size_full_backup=($list_week_full_backups.Split('	')[4].Split(' ')[0]) -replace '[^0-9]+', ""
    & $ZS @('-z', $zabbix_server, '-p', '10051', '-s', $mon_host, '-k', 'backup_db_full_size', '-o', $size_full_backup)
    $size_inc_backup=($list_inc_backup[-3].Split('	')[4].Split(' ')[0]) -replace '[^0-9]+', ""
    & $ZS @('-z', $zabbix_server, '-p', '10051', '-s', $mon_host, '-k', 'backup_db_increment_size', '-o', $size_inc_backup)
    }
}
else
{
"Нет резервной копии за текущюю дату"
& $ZS @('-z', $zabbix_server, '-p', '10051', '-s', $mon_host, '-k', 'backup_state', '-o', "0")
}