@echo off

echo ---UHURUMON-CPU_TIME
typeperf -sc 1 "\processor(_total)\%% processor time"


echo ---UHURUMON-SYSTEM_INFO
systeminfo

echo ---UHURUMON-COMPONENT_INFO


if exist "C:\Program Files\Uhuru Software\Uhuru .NET Droplet Execution Agent\dea.exe" goto dea

if exist "C:\inetpub\wwwroot\uhuru.cloudinfo\bin\Uhuru.Cloud.API.Info.dll" goto dataanalysis

if exist "C:\Program Files\Uhuru Software\Uhuru Services for Microsoft SQL Server\mssqlnode.exe" goto mssql

if exist "C:\Program Files\Uhuru Software\Uhuru FileService\FileServiceNode.exe" goto uhurufs

if exist "C:\inetpub\wwwroot\uhuru.api\bin\Uhuru.Cloud.API.dll" goto api

:dea
echo Windows DEA
echo ---UHURUMON-DROPLETCOUNTFOLDER
dir C:\Droplets\apps
echo ---UHURUMON-WORKERPROCESSESIISCOUNT
tasklist | find "w3wp"
echo ---UHURUMON-WORKERPROCESSESMEMORY
typeperf -sc 1 "\process(w3wp)\working set - private"
echo ---UHURUMON-DEAPROCESSMEMORY
typeperf -sc 1 "\process(dea)\working set - private"
echo ---UHURUMON-DISKUSAGEC
fsutil volume diskfree c:
echo ---UHURUMON-IISWEBSITECOUNT
%systemroot%\system32\inetsrv\appcmd list app
echo ---UHURUMON-CONFIG
type "C:\Program Files\Uhuru Software\Uhuru .NET Droplet Execution Agent\uhuru.config"
goto exit

:mssql
echo MS SQL Node
echo ---UHURUMON-DATABASESONDRIVE
dir C:\mssql\data
echo ---UHURUMON-SQLSERVERMEMORY
typeperf -sc 1 "\process(sqlservr)\working set - private"
echo ---UHURUMON-SQLNODEPROCESSMEMORY
typeperf -sc 1 "\process(mssqlnode)\working set - private"
echo ---UHURUMON-DISKUSAGEC
fsutil volume diskfree c:
echo ---UHURUMON-CONFIG
type "C:\Program Files\Uhuru Software\Uhuru Services for Microsoft SQL Server\uhuru.config"

goto exit

:api
echo Uhuru API
echo ---UHURUMON-WORKERPROCESSESMEMORY
typeperf -sc 1 "\process(w3wp)\working set - private"
echo ---UHURUMON-SQLSERVERMEMORY
typeperf -sc 1 "\process(sqlservr)\working set - private"
echo ---UHURUMON-DISKUSAGEC
fsutil volume diskfree c:

goto exit

:dataanalysis
echo Data Analysis Box
echo ---UHURUMON-WORKERPROCESSESMEMORY
typeperf -sc 1 "\process(w3wp)\working set - private"
echo ---UHURUMON-SQLSERVERMEMORY
typeperf -sc 1 "\process(sqlservr)\working set - private"
echo ---UHURUMON-DISKUSAGEC
fsutil volume diskfree c:
goto exit

:uhurufs
echo Uhuru File System
echo ---UHURUMON-DATAFOLDERS
dir C:\Data
echo ---UHURUMON-WORKERPROCESSESIISCOUNT
tasklist | find "w3wp"
echo ---UHURUMON-WORKERPROCESSESMEMORY
typeperf -sc 1 "\process(w3wp)\working set - private"
echo ---UHURUMON-DISKUSAGEC
fsutil volume diskfree c:
echo ---UHURUMON-IISWEBSITECOUNT
%systemroot%\system32\inetsrv\appcmd list app
echo ---UHURUMON-CONFIG
type "C:\Program Files\Uhuru Software\Uhuru FileService\uhuru.config"

goto exit

:exit