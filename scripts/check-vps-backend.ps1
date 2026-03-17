# Script to check VPS backend status and logs
# Usage: .\scripts\check-vps-backend.ps1

Write-Host "🔍 Checking VPS Backend Status..." -ForegroundColor Cyan

# Get VPS credentials from GitHub secrets
$vpsHost = (gh secret list --json name,updatedAt | ConvertFrom-Json | Where-Object { $_.name -eq "VPS_HOST" }).name
$vpsUser = (gh secret list --json name,updatedAt | ConvertFrom-Json | Where-Object { $_.name -eq "VPS_USER" }).name

if (-not $vpsHost -or -not $vpsUser) {
    Write-Host "❌ Could not retrieve VPS credentials from GitHub secrets" -ForegroundColor Red
    exit 1
}

Write-Host "✅ VPS credentials found" -ForegroundColor Green
Write-Host ""

# Check if SSH key exists
$sshKeyPath = "$env:USERPROFILE\.ssh\id_rsa"
if (-not (Test-Path $sshKeyPath)) {
    Write-Host "❌ SSH key not found at $sshKeyPath" -ForegroundColor Red
    Write-Host "Please ensure your SSH key is configured" -ForegroundColor Yellow
    exit 1
}

Write-Host "📋 Checking backend deployment..." -ForegroundColor Cyan
Write-Host ""

# Commands to run on VPS
$commands = @"
echo '=== Docker Containers Status ==='
cd /home/auditflow/prod-backend
docker compose ps

echo ''
echo '=== Backend Logs (last 50 lines) ==='
docker compose logs --tail=50 backend

echo ''
echo '=== Database Status ==='
docker compose exec -T db pg_isready -U \$POSTGRES_USER -d \$POSTGRES_DB || echo 'Database not ready'

echo ''
echo '=== Environment Variables Check ==='
if [ -f .env ]; then
    echo 'API_DOMAIN:' \$(grep API_DOMAIN .env | cut -d'=' -f2)
    echo 'BACKEND_PORT:' \$(grep BACKEND_PORT .env | cut -d'=' -f2)
    echo 'DATABASE_URL exists:' \$(grep -q DATABASE_URL .env && echo 'Yes' || echo 'No')
    echo 'JWT_SECRET exists:' \$(grep -q JWT_SECRET .env && echo 'Yes' || echo 'No')
else
    echo '.env file not found!'
fi

echo ''
echo '=== Network Test ==='
docker compose exec -T backend wget -q -O- http://localhost:3000/health || echo 'Backend health check failed'
"@

Write-Host "Connecting to VPS and running diagnostics..." -ForegroundColor Yellow
Write-Host ""

# Note: This will prompt for SSH connection if not already trusted
# You may need to manually approve the connection
Write-Host "Note: You may need to manually enter VPS host and user when prompted" -ForegroundColor Yellow
Write-Host "VPS_HOST should be retrieved from GitHub secrets" -ForegroundColor Yellow
Write-Host ""
Write-Host "To connect manually, use:" -ForegroundColor Cyan
Write-Host "ssh -i $sshKeyPath <VPS_USER>@<VPS_HOST>" -ForegroundColor Cyan
Write-Host ""
Write-Host "Then run these commands:" -ForegroundColor Cyan
Write-Host $commands -ForegroundColor Gray
