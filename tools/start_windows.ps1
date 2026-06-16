$ErrorActionPreference = "Stop"

$repoPath = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$junctionPath = Join-Path $env:USERPROFILE "dev\sistema-rgt"
$flutter = Join-Path $env:USERPROFILE "dev\flutter\bin\flutter.bat"
$exe = Join-Path $junctionPath "build\windows\x64\runner\Release\sistema_rgt.exe"
$localConfig = Join-Path $PSScriptRoot "start_windows.local.ps1"

if (Test-Path -LiteralPath $localConfig) {
  . $localConfig
}

if ([string]::IsNullOrWhiteSpace($env:SUPABASE_URL)) {
  $env:SUPABASE_URL = "https://libpncdxxgwshnlxicbt.supabase.co"
}

$dartDefines = @(
  "--dart-define=SUPABASE_URL=$($env:SUPABASE_URL)"
)

if (-not [string]::IsNullOrWhiteSpace($env:SUPABASE_PUBLISHABLE_KEY)) {
  $dartDefines += "--dart-define=SUPABASE_PUBLISHABLE_KEY=$($env:SUPABASE_PUBLISHABLE_KEY)"
}

if (-not (Test-Path -LiteralPath $junctionPath)) {
  New-Item -ItemType Junction -Path $junctionPath -Target $repoPath | Out-Null
}

Push-Location $junctionPath
try {
  & $flutter build windows @dartDefines
  if ($LASTEXITCODE -ne 0) {
    exit $LASTEXITCODE
  }
  Start-Process -FilePath $exe
} finally {
  Pop-Location
}
