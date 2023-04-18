@echo off 

set DIR_SERVER_SOURCEMOD=H:\games\csgo_ds\csgo\addons\sourcemod
set DIR_SERVER_SCRIPTING=%DIR_SERVER_SOURCEMOD%\scripting
set DIR_SERVER_PLUGINS=%DIR_SERVER_SOURCEMOD%\plugins

set DIR_SOURCES_SOURCEMOD=C:\home\altex\git\css_plugins\sm_csgobotquotafix\addons\sourcemod
set DIR_SOURCES_SCRIPTING=%DIR_SOURCES_SOURCEMOD%\scripting
set DIR_SOURCES_PLUGINS=%DIR_SOURCES_SOURCEMOD%\plugins

set LOG_COMPILE=%DIR_SOURCES_SCRIPTING%\compile.log

xcopy /e /f /y %DIR_SOURCES_SCRIPTING%\*.* %DIR_SERVER_SCRIPTING%\

cd /d %DIR_SERVER_SCRIPTING%

echo %DATE% %TIME% > %LOG_COMPILE%

%DIR_SERVER_SCRIPTING%\spcomp sm_csgobotquotafix.sp                    >> %LOG_COMPILE%
copy %DIR_SERVER_SCRIPTING%\sm_csgobotquotafix.smx                     %DIR_SOURCES_PLUGINS%\
copy %DIR_SERVER_SCRIPTING%\sm_csgobotquotafix.smx                     %DIR_SERVER_PLUGINS%\

cd /d %DIR_SOURCES_SCRIPTING%
