$name_srv="prd"
$p_loc="\\192.168.1.52\SQL-PRD-SRC2-r60\"


$cred="user_backup,@EHHhgjdfghjgfj"
$zabbix_server="192.168.1.23"
$actual_date = Get-Date -Format d
$yesterday= (Get-Date).AddDays(-1).ToString('dd.MM.yyyy')
$ZS = "C:\Program Files\Zabbix Agent\zabbix_sender.exe"


$list_archives=((& acrocmd.exe list archives --loc=$p_loc --credentials=$cred --output=raw).Split('	') | Select-String -Pattern $name_srv)
$name_srv_list = @($list_archives)
foreach ($srv_name in $name_srv_list)
{
    $x,$null=($srv_name.ToString()).Split('.')
    $mon_host=[string]::Join("-",$x)+ '.test.local'

    $list_all_backups=(& acrocmd.exe list backups --loc=$p_loc --credentials=$cred --arc=$srv_name --output=raw)
    $list_all_full_backups=$list_all_backups | Select-String -Pattern "full"
    $list_inc_backup=$list_all_backups | Select-String -Pattern "incremental"
	$list_yesterday_full_backups=$list_all_full_backups | Select-String -Pattern $yesterday
    $last_full_backup=$list_all_full_backups[-2]
    $date_last_backup=($list_all_backups[-3].Split('	')[3]).Split(' ')[0]

    if ($date_last_backup -eq $actual_date)
    {
        & $ZS @('-z', $zabbix_server, '-p', '10051', '-s', $mon_host, '-k', 'backup_state', '-o', "1")
        if (-not($null -eq $last_full_backup))
        {
            $size_full_backup=($last_full_backup.ToString().Split('	')[4].Split(' ')[0]) -replace '[^0-9]+', ""
            & $ZS @('-z', $zabbix_server, '-p', '10051', '-s', $mon_host, '-k', 'backup_db_full_size', '-o', $size_full_backup)
            $size_inc_backup=($list_inc_backup[-3].ToString().Split('	')[4].Split(' ')[0]) -replace '[^0-9]+', ""
            & $ZS @('-z', $zabbix_server, '-p', '10051', '-s', $mon_host, '-k', 'backup_db_increment_size', '-o', $size_inc_backup)
            }
        else
            {
            $size_full_backup=($list_yesterday_full_backups.ToString().Split('	')[4].Split(' ')[0]) -replace '[^0-9]+', ""
            & $ZS @('-z', $zabbix_server, '-p', '10051', '-s', $mon_host, '-k', 'backup_db_full_size', '-o', $size_full_backup)
            $size_inc_backup=($list_inc_backup[-3].ToString().Split('	')[4].Split(' ')[0]) -replace '[^0-9]+', ""
            & $ZS @('-z', $zabbix_server, '-p', '10051', '-s', $mon_host, '-k', 'backup_db_increment_size', '-o', $size_inc_backup)
            }
        }
        else
        {
        "No any backups for actual day"
        & $ZS @('-z', $zabbix_server, '-p', '10051', '-s', $mon_host, '-k', 'backup_state', '-o', "0")
        }
}