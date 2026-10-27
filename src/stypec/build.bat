@echo off
rem Build STYPEC, the command-line STYPE: build.bat         -> build\STYPEC.bin (load address $8A00)
rem                                        build.bat disk    -> and copy STYPEC to the project disk
rem Needs cc65 (ca65, ld65). Change the three lines below if yours are elsewhere.
setlocal
set CC65=D:\opt\devtools\asm\cc65\bin
set ACX=C:\bin\acx.exe
set DISK=..\..\disk\NEWHANGEUL.DSK
cd /d "%~dp0"

if not exist build mkdir build
"%CC65%\ca65.exe" -t none -I ..\stype -I ..\type -l build\stypec.lst -o build\stypec.o stypec.s || goto fail
"%CC65%\ld65.exe" -C stypec.cfg -m build\stypec.map -o build\STYPEC.bin build\stypec.o || goto fail
for %%f in (build\STYPEC.bin) do echo built %%f, %%~zf bytes

if /i not "%1"=="disk" goto done
"%ACX%" -d "%DISK%" STYPEC >nul 2>&1
"%ACX%" -p "%DISK%" STYPEC bin 0x8A00 < build\STYPEC.bin || goto fail
echo copied to %DISK%

:done
endlocal
exit /b 0

:fail
echo BUILD FAILED
endlocal
exit /b 1
