####################################### !!! EXPORT !!! #######################################
$timer_script = [System.Diagnostics.Stopwatch]::StartNew()
$timer_script.Start()
#---------------------------------------------------------


$name_srv="ads-prd"#Требуется указать
$p_loc="\\10.250.2.51\SQL-PRD-SRC1-r60\" #Требуется указать
$p_target="\\10.250.2.53\share_test\export\" #Требуется указать
#---------------------------------------------------------

$yesterday= (Get-Date).AddDays(-2).ToString('dd.MM.yyyy')
$cred="user_backup,xh/jPO8NNCde71oQLxFgHNj1MOs3zHj9v96kUx0TDaLxLjbQHtA==,encrypted"
$path_backup_log= $PSScriptRoot+"\export_log.txt" #Расположения лога выполнения скрипта
#---------------------------------------------------------
$list_archives=((& acrocmd.exe list archives --loc=$p_loc --credentials=$cred --output=raw).Split('	') | Select-String -Pattern $name_srv)[0]
$list_all_backups=(& acrocmd.exe list backups --loc=$p_loc --credentials=$cred --arc=$list_archives --filter_date=$yesterday --output=raw)
$list_last_backups=($list_all_backups[-3])
$list_backups=($list_last_backups).Split('	')[0]
(& acrocmd.exe export backup --loc=$p_loc --credentials=$cred --arc=$list_archives --backup=$list_backups --target=$p_target --credentials=$cred --target_arc=$list_archives)

#---------------------------------------------------------
$timer_script.Stop()
(Get-Date).ToString()+" ---------- Создан синтетический полный бэкап из последный инкрементальной копии : " + $list_last_backups | out-file -Filepath $path_backup_log
(Get-Date).ToString()+" ---------- Общее время выполнения скрипта: "+ (($timer_script.Elapsed).ToString()).Split('.')[0] | out-file -Filepath $path_backup_log -append