@echo off
echo ========================================
echo  Ky Nang Song - Backend Server
echo  Database: MongoDB
echo ========================================
echo.

REM Kiem tra MongoDB Service co dang chay khong
sc query MongoDB >nul 2>&1
if %errorlevel% neq 0 (
    echo [CANH BAO] MongoDB Service chua chay!
    echo Hay vao Services ^(services.msc^) va bat MongoDB, hoac tai tai: https://www.mongodb.com/try/download/community
    echo.
) else (
    echo [OK] MongoDB Service dang chay.
)

echo [*] Khoi dong FastAPI Backend...
echo [*] API se chay tai: http://localhost:8000
echo [*] API docs tai:    http://localhost:8000/docs
echo [*] Nhan Ctrl+C de dung server
echo.

uvicorn main:app --reload --host 0.0.0.0 --port 8000

pause
