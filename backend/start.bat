@echo off
echo ========================================
echo  Ky Nang Song - Backend Server
echo  Database: MongoDB
echo ========================================
echo.

REM Kiem tra MongoDB co dang chay khong
mongod --version >nul 2>&1
if %errorlevel% neq 0 (
    echo [CANH BAO] Khong tim thay MongoDB!
    echo Hay tai va cai dat MongoDB tai: https://www.mongodb.com/try/download/community
    echo.
) else (
    echo [OK] MongoDB da duoc cai dat.
)

echo [*] Khoi dong FastAPI Backend...
echo [*] API se chay tai: http://localhost:8000
echo [*] API docs tai:    http://localhost:8000/docs
echo [*] Nhan Ctrl+C de dung server
echo.

uvicorn main:app --reload --host 0.0.0.0 --port 8000

pause
