# Generate PowerSync configuration from template with environment variables
# Usage: .\scripts\generate-powersync-config.ps1 [dev|prod]

param(
    [string]$Env = "dev"
)

$TemplateFile = "powersync.template.yaml"

if ($Env -eq "prod") {
    $OutputFile = "powersync.prod.yaml"
    Write-Host "Generating production PowerSync config..."
} else {
    $OutputFile = "powersync.yaml"
    Write-Host "Generating development PowerSync config..."
}

# Check if .env exists
if (-not (Test-Path .env)) {
    Write-Error "Error: .env file not found"
    exit 1
}

# Read and parse .env file
$envVars = @{}

Get-Content .env | ForEach-Object {
    $line = $_.Trim()
    if ($line -and -not $line.StartsWith("#")) {
        if ($line -match "^([^=]+)=(.*)$") {
            $key = $matches[1].Trim()
            $value = $matches[2].Trim()
            # Remove quotes if present
            $value = $value -replace '^["\']|["\']$'
            $envVars[$key] = $value
        }
    }
}

# Read template
$template = Get-Content $TemplateFile -Raw

# Replace variables
$content = $template
foreach ($key in $envVars.Keys) {
    $content = $content -replace "\`$\{$key\}", $envVars[$key]
}

# Write output file
$content | Out-File -FilePath $OutputFile -Encoding UTF8

Write-Host "✅ Config generated: $OutputFile"
Write-Host ""
Write-Host "Preview (first 10 lines):"
Get-Content $OutputFile -TotalCount 10
