Write-Host "Starting Libera Application..." -ForegroundColor Cyan

# 1. Install Python Dependencies
Write-Host "Installing Python dependencies..." -ForegroundColor Yellow
pip install -r requirements.txt
if ($LASTEXITCODE -ne 0) {
    Write-Host "Failed to install Python dependencies. Please check your Python installation." -ForegroundColor Red
    exit $LASTEXITCODE
}

# 2. Start Backend (Flask)
Write-Host "Starting Backend Server (Flask)..." -ForegroundColor Green
Start-Process powershell -ArgumentList "-NoExit", "-Command", "& { $host.UI.RawUI.WindowTitle = 'Libera Backend'; python -m hero_lib.app }"

# 3. Start Frontend (Next.js)
Write-Host "Starting Frontend Server (Next.js)..." -ForegroundColor Green
Start-Process powershell -ArgumentList "-NoExit", "-Command", "& { $host.UI.RawUI.WindowTitle = 'Libera Frontend'; cd 'new UI'; npm run dev }"

Write-Host "Application functionality is splitting across two new windows." -ForegroundColor Cyan
Write-Host "Backend: http://localhost:5000"
Write-Host "Frontend: http://localhost:3000"
