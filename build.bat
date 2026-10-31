@echo off
rem Build everything and put the finished disk in disk\K-HANGEUL.DSK.
rem   build.bat          build
rem   build.bat clean    same as clean.bat: remove the build folders and the contents of DIST
rem It runs src\make_all.bat (the driver, TYPE, TYPEC, STYPE, STYPEC, then DIST\K-HANGEUL.DSK),
rem then copies the disk to disk\. Set the cc65 and AppleCommander paths at the top of src\make_all.bat.
setlocal
cd /d "%~dp0"

if /i "%1"=="clean" (
  call clean.bat
  goto done
)
call src\make_all.bat || goto fail

if not exist DIST\K-HANGEUL.DSK goto fail
copy /y DIST\K-HANGEUL.DSK disk\K-HANGEUL.DSK >nul || goto fail
echo disk\K-HANGEUL.DSK is ready

:done
endlocal
exit /b 0

:fail
echo BUILD FAILED
endlocal
exit /b 1
