@echo off
rem Removes everything a build makes: the build\ folders of the five programs, Python caches, and the contents of DIST\.
rem It keeps disk\K-HANGEUL.DSK (the committed disk) and all source files. Needs no make and no cc65.
setlocal
cd /d "%~dp0"

for %%d in (driver type typec stype stypec) do (
  if exist "src\%%d\build" rd /s /q "src\%%d\build"
)
for /d /r "src" %%d in (__pycache__) do if exist "%%d" rd /s /q "%%d"
for /d /r "tools" %%d in (__pycache__) do if exist "%%d" rd /s /q "%%d"

if exist "DIST" (
  del /q "DIST\*" >nul 2>&1
  for /d %%d in ("DIST\*") do rd /s /q "%%d"
)
echo clean done
endlocal
exit /b 0
