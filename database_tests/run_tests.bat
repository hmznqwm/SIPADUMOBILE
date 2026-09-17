@echo off
title Uji Coba Sinkronisasi Database SmartSchedule
cls
echo ==============================================================================
echo Menjalankan Pengujian Sinkronisasi Database dan Backend...
echo ==============================================================================
echo.

if exist "..\backend-python\.venv\Scripts\python.exe" (
    "..\backend-python\.venv\Scripts\python.exe" run_all_database_tests.py
) else (
    python run_all_database_tests.py
)

echo.
echo ==============================================================================
echo Pengujian selesai.
echo ==============================================================================
pause
