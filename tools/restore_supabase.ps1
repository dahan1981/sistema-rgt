param(
  [Parameter(Mandatory = $true)]
  [string]$BackupFile,
  [switch]$ConfirmRestore
)

$ErrorActionPreference = "Stop"
if (-not $ConfirmRestore) {
  throw "Restauração bloqueada. Revise o destino e use -ConfirmRestore."
}
if ([string]::IsNullOrWhiteSpace($env:DATABASE_URL)) {
  throw "Defina DATABASE_URL somente no ambiente administrativo."
}
$resolvedBackup = (Resolve-Path -LiteralPath $BackupFile).Path
$pgRestore = (Get-Command pg_restore -ErrorAction SilentlyContinue).Source
if (-not $pgRestore) {
  throw "pg_restore não encontrado. Instale as ferramentas cliente do PostgreSQL."
}

& $pgRestore --clean --if-exists --no-owner --no-privileges `
  --dbname=$env:DATABASE_URL $resolvedBackup
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
Write-Host "Restauração concluída a partir de: $resolvedBackup"
