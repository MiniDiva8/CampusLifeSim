@echo off
setlocal

set "GODOT_EXE=C:\Users\24578\Tools\Godot\4.7.1\Godot_v4.7.1-stable_win64.exe"
set "GAME_PCK=%~dp0builds\windows\CampusLifeSim.pck"

if not exist "%GODOT_EXE%" (
    echo [ERROR] Godot 4.7.1 was not found:
    echo %GODOT_EXE%
    pause
    exit /b 1
)

if not exist "%GAME_PCK%" (
    echo [ERROR] CampusLifeSim.pck was not found:
    echo %GAME_PCK%
    pause
    exit /b 1
)

start "CampusLifeSim" "%GODOT_EXE%" --main-pack "%GAME_PCK%"
endlocal
