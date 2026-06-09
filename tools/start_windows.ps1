$ErrorActionPreference = "Stop"

$repoPath = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$junctionPath = Join-Path $env:USERPROFILE "dev\sistema-rgt"
$flutter = Join-Path $env:USERPROFILE "dev\flutter\bin\flutter.bat"
$exe = Join-Path $junctionPath "build\windows\x64\runner\Release\sistema_rgt.exe"

if (-not (Test-Path -LiteralPath $junctionPath)) {
  New-Item -ItemType Junction -Path $junctionPath -Target $repoPath | Out-Null
}

Push-Location $junctionPath
try {
  & $flutter build windows
  if ($LASTEXITCODE -ne 0) {
    exit $LASTEXITCODE
  }
  Start-Process -FilePath $exe
} finally {
  Pop-Location
}
