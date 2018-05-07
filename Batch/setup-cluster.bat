@echo off
@echo
@echo ### Setting up cluster
@echo ### - Creating folders...

set STARTDIR=%cd%

IF NOT EXIST cluster (
	md cluster
)
cd cluster

IF NOT EXIST cork (
	md cork
)
cd cork
md cork0
md cork1
md cork2
echo ###   - Created node folders: Cork    [x]
cd %STARTDIR%\cluster

IF NOT EXIST dublin (
	md dublin
)
cd dublin
md dublin0
md dublin1
md dublin2
echo ###   - Created node folders: Dublin  [x]
cd %STARTDIR%\cluster


IF NOT EXIST configServers (
	md configServers
)
cd configServers
md config0
md config1
md config2

cd %STARTDIR%

set /p input= Launch cluster? y/n: 

if "%input%"=="y" (
	CALL start-cluster.bat
)

