@echo off
rem Build everything into ..\DIST: the five programs, the disk image, and the user documents.
rem   make_all.bat          build
rem   make_all.bat clean    remove the build folders and ..\DIST
rem Uses GNU make if it is on PATH, otherwise calls the build.bat files directly.
setlocal
set CC65=D:/opt/devtools/asm/cc65/bin
set ACX=C:/bin/acx.exe
cd /d "%~dp0"

where make >nul 2>&1
if errorlevel 1 goto nomake
if /i "%1"=="clean" ( make clean ) else ( make )
if errorlevel 1 goto fail
goto done

:nomake
if /i "%1"=="clean" goto fail
call driver\build.bat || goto fail
call type\build.bat || goto fail
call typec\build.bat || goto fail
call stype\build.bat || goto fail
call stypec\build.bat || goto fail
cd /d "%~dp0"
py -3 tools\mkdist.py .. || goto fail

:done
endlocal
exit /b 0

:fail
echo BUILD FAILED
endlocal
exit /b 1
