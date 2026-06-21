param(
  [string]$OutputDirectory = (Join-Path $PSScriptRoot "..\backups")
)

$ErrorActionPreference = "Stop"
if ([string]::IsNullOrWhiteSpace($env:DATABASE_URL)) {
  throw "Defina DATABASE_URL somente no ambiente administrativo."
}
$pgDump = (Get-Command pg_dump -ErrorAction SilentlyContinue).Source
if (-not $pgDump) {
  throw "pg_dump não encontrado. Instale as ferramentas cliente do PostgreSQL."
}

New-Item -ItemType Directory -Force -Path $OutputDirectory | Out-Null
$timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
$output = Join-Path $OutputDirectory "sistema-rgt-$timestamp.dump"
& $pgDump --format=custom --no-owner --no-privileges `
  --file=$output $env:DATABASE_URL
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

$hash = (Get-FileHash -LiteralPath $output -Algorithm SHA256).Hash.ToLower()
Set-Content -LiteralPath "$output.sha256" -Value "$hash  $([IO.Path]::GetFileName($output))"
Write-Host "Backup criado: $output"
