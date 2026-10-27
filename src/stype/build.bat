@echo off
rem Build STYPE, the & command with smooth rows: build.bat         -> build\STYPE.bin (load address $8A00)
rem                                              build.bat disk    -> and copy STYPE and STYPEDEMO to the project disk
rem Needs cc65 (ca65, ld65). Change the three lines below if yours are elsewhere.
setlocal
set CC65=D:\opt\devtools\asm\cc65\bin
set ACX=C:\bin\acx.exe
set DISK=..\..\disk\NEWHANGEUL.DSK
cd /d "%~dp0"

if not exist build mkdir build
"%CC65%\ca65.exe" -t none -I . -I ..\type -l build\stype.lst -o build\stype.o stype.s || goto fail
"%CC65%\ld65.exe" -C stype.cfg -m build\stype.map -o build\STYPE.bin build\stype.o || goto fail
for %%f in (build\STYPE.bin) do echo built %%f, %%~zf bytes

if /i not "%1"=="disk" goto done
"%ACX%" -d "%DISK%" STYPE >nul 2>&1
"%ACX%" -p "%DISK%" STYPE bin 0x8A00 < build\STYPE.bin || goto fail
"%ACX%" -d "%DISK%" STYPEDEMO >nul 2>&1
"%ACX%" -bas "%DISK%" STYPEDEMO < stypedemo.bas || goto fail
echo copied to %DISK%

:done
endlocal
exit /b 0

:fail
echo BUILD FAILED
endlocal
exit /b 1
