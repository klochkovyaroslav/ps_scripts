﻿$dirlist=('E:\PSCDATA1','E:\PSCDATA10','E:\PSCDATA11',
'E:\PSCDATA12','E:\PSCDATA13','E:\PSCDATA14',
'E:\PSCDATA15','E:\PSCDATA16','E:\PSCDATA2','E:\PSCDATA3',
'E:\PSCDATA4','E:\PSCDATA5','E:\PSCDATA6','E:\PSCDATA7',
'E:\PSCDATA8','E:\PSCDATA9','L:\PSCLOG1','T:\TEMPDB')
foreach ($i in $dirlist)
{
    New-Item -Path $i -ItemType Directory
}