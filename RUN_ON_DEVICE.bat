@echo off
echo ========================================================
echo   HVAC Duct Sizing & Airflow Calculator - Local Runner
echo ========================================================
echo.

echo [1/3] Running flutter clean to remove stale Gradle cache...
call flutter clean

echo [2/3] Fetching Flutter dependencies...
call flutter pub get

echo [3/3] Launching app on connected Android device...
call flutter run
pause
