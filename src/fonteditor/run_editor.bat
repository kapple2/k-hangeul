@echo off
rem Font editor: edits font.json in this folder. Uses the project's .venv if there is one, else the Python launcher.
cd /d "%~dp0"
if exist "..\..\.venv\Scripts\python.exe" ( "..\..\.venv\Scripts\python.exe" editor.py ) else ( py -3 editor.py )
