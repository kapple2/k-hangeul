@echo off
rem Build TYPEC, the command-line TYPE: build.bat        -> build\TYPEC.bin (load address $8E00)
rem                                      build.bat disk   -> and copy TYPEC to the project disk
rem Needs cc65 (ca65, ld65). Change the three lines below if yours are elsewhere.
setlocal
set CC65=D:\opt\devtools\asm\cc65\bin
set ACX=C:\bin\acx.exe
set DISK=..\..\disk\NEWHANGEUL.DSK
cd /d "%~dp0"

if not exist build mkdir build
"%CC65%\ca65.exe" -t none -I ..\type -l build\typec.lst -o build\typec.o typec.s || goto fail
"%CC65%\ld65.exe" -C typec.cfg -m build\typec.map -o build\TYPEC.bin build\typec.o || goto fail
for %%f in (build\TYPEC.bin) do echo built %%f, %%~zf bytes

if /i not "%1"=="disk" goto done
"%ACX%" -d "%DISK%" TYPEC >nul 2>&1
"%ACX%" -p "%DISK%" TYPEC bin 0x8E00 < build\TYPEC.bin || goto fail
echo copied to %DISK%

:done
endlocal
exit /b 0

:fail
echo BUILD FAILED
endlocal
exit /b 1
