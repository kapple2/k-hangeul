@echo off
rem Build TYPE, the & command: build.bat         -> build\TYPE.bin (load address $8E00)
rem                            build.bat disk    -> and copy TYPE, SAMPLEB, TYPEDEMO, STORYT to the project disk
rem Needs cc65 (ca65, ld65). Change the three lines below if yours are elsewhere.
setlocal
set CC65=D:\opt\devtools\asm\cc65\bin
set ACX=C:\bin\acx.exe
set DISK=..\..\disk\NEWHANGEUL.DSK
cd /d "%~dp0"

if not exist build mkdir build
"%CC65%\ca65.exe" -t none -I . -l build\type.lst -o build\type.o type.s || goto fail
"%CC65%\ld65.exe" -C type.cfg -m build\type.map -o build\TYPE.bin build\type.o || goto fail
for %%f in (build\TYPE.bin) do echo built %%f, %%~zf bytes

if /i not "%1"=="disk" goto done
"%ACX%" -d "%DISK%" TYPE >nul 2>&1
"%ACX%" -p "%DISK%" TYPE bin 0x8E00 < build\TYPE.bin || goto fail
"%ACX%" -d "%DISK%" SAMPLEB >nul 2>&1
"%ACX%" -p "%DISK%" SAMPLEB bin 0x8000 < sampleb.bin || goto fail
"%ACX%" -d "%DISK%" TYPEDEMO >nul 2>&1
"%ACX%" -bas "%DISK%" TYPEDEMO < typedemo.bas || goto fail
"%ACX%" -d "%DISK%" STORYT >nul 2>&1
"%ACX%" -bas "%DISK%" STORYT < storyt.bas || goto fail
echo copied to %DISK%

:done
endlocal
exit /b 0

:fail
echo BUILD FAILED
endlocal
exit /b 1
