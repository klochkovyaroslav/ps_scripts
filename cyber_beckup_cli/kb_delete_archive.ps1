####################################### !!! DELETE !!! #######################################
$name_srv="ads-prd"
$pd_loc="\\10.250.2.53\share_test\export\"
#---------------------------------------------------------
$cred="user_backup,xh/jPO8NNCde71oQLxFgHNj1MOs3zHj9v96kUx0TDaLxLjbQHtA==,encrypted"
$path_delete_log= $PSScriptRoot+"\delete_log.txt" #Расположения лога выполнения скрипта
#---------------------------------------------------------


$list_last_archives=(& acrocmd.exe list archives --loc=$pd_loc --credentials=$cred --output=raw)[-3]
$list_archives=($list_last_archives.Split('	')) | Select-String -Pattern $name_srv
& acrocmd delete archive --loc=$pd_loc --credentials=$cred --arc=$list_archives
(Get-Date).ToString()+" ---------- Удален архив: " + $list_last_archives | out-file -Filepath $path_delete_log