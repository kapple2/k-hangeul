@echo off
rem Build the K-HANGEUL driver: build.bat        -> build\K-HANGEUL.bin, build\FONT12.bin, build\FONT6X10.bin
rem                              build.bat disk   -> and copy them to the project disk
rem Needs cc65 (ca65, ld65) and Python 3. Change the three lines below if yours are elsewhere.
setlocal
set CC65=D:\opt\devtools\asm\cc65\bin
set ACX=C:\bin\acx.exe
set DISK=..\..\disk\NEWHANGEUL.DSK
cd /d "%~dp0"

if not exist build mkdir build
py -3 fontgen.py ..\fonteditor\font.json build || goto fail
"%CC65%\ca65.exe" -t none -I build -l build\driver.lst -o build\driver.o driver.s || goto fail
"%CC65%\ld65.exe" -C driver.cfg -m build\driver.map -Ln build\driver.lbl -o build\K-HANGEUL.bin build\driver.o || goto fail
echo built build\K-HANGEUL.bin, build\FONT12.bin and build\FONT6X10.bin

if /i not "%1"=="disk" goto done
"%ACX%" -d "%DISK%" FONT12 >nul 2>&1
"%ACX%" -p "%DISK%" FONT12 bin 0x6000 < build\FONT12.bin || goto fail
"%ACX%" -d "%DISK%" FONT6X10 >nul 2>&1
"%ACX%" -p "%DISK%" FONT6X10 bin 0x7200 < build\FONT6X10.bin || goto fail
"%ACX%" -d "%DISK%" NEWHANGEUL >nul 2>&1
"%ACX%" -d "%DISK%" K-HANGEUL >nul 2>&1
"%ACX%" -p "%DISK%" K-HANGEUL bin 0x0F94 < build\K-HANGEUL.bin || goto fail
"%ACX%" -d "%DISK%" HELLO >nul 2>&1
"%ACX%" -bas "%DISK%" HELLO < hello.bas || goto fail
echo copied to %DISK%

:done
endlocal
exit /b 0

:fail
echo BUILD FAILED
endlocal
exit /b 1
