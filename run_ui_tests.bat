@echo off
echo Ultima-Style D20 RPG - UI Test Automation
echo ==========================================

REM Check if Godot executable exists
if not exist "Godot_v4.4.1-stable_win64.exe" (
    echo ERROR: Godot executable not found
    echo Please ensure Godot_v4.4.1-stable_win64.exe is in the current directory
    pause
    exit /b 1
)

REM Check if project.godot exists
if not exist "project.godot" (
    echo ERROR: project.godot not found
    echo Please run this script from the game's root directory
    pause
    exit /b 1
)

echo Starting UI tests...
echo This may take a few minutes...
echo.

REM Run the UI tests
Godot_v4.4.1-stable_win64.exe --headless --path . res://tests/UITestRunner.tscn

echo.
echo UI tests completed!
echo.
echo Test reports have been saved to your user data directory:
echo %APPDATA%\Godot\app_userdata\Ultima-Style RPG\
echo.

REM Check if Python is available to run the report processor
python --version >nul 2>&1
if %errorlevel% equ 0 (
    echo Running report processor...
    python run_ui_tests.py
) else (
    echo Python not found - skipping report processing
    echo You can manually check the test reports in the user data directory
)

echo.
echo Press any key to exit...
pause >nul
