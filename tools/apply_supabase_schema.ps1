$ErrorActionPreference = "Stop"
if ([string]::IsNullOrWhiteSpace($env:DATABASE_URL)) {
  throw "Defina DATABASE_URL somente no ambiente administrativo."
}
$psql = (Get-Command psql -ErrorAction SilentlyContinue).Source
if (-not $psql) {
  throw "psql não encontrado. Instale as ferramentas cliente do PostgreSQL."
}

$schema = (Resolve-Path (Join-Path $PSScriptRoot "..\supabase\schema.sql")).Path
& $psql $env:DATABASE_URL -v ON_ERROR_STOP=1 -f $schema
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
Write-Host "Schema aplicado com sucesso."
