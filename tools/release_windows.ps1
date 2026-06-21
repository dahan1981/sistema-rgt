param(
  [Parameter(Mandatory = $true)]
  [ValidatePattern('^\d+\.\d+\.\d+$')]
  [string]$Version,
  [string]$Notes = "Atualização do Sistema RGT.",
  [switch]$Mandatory,
  [switch]$Sign,
  [string]$CertificateThumbprint,
  [switch]$Upload
)

$ErrorActionPreference = "Stop"
$repoPath = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$junctionPath = Join-Path $env:USERPROFILE "dev\sistema-rgt"
$flutter = Join-Path $env:USERPROFILE "dev\flutter\bin\flutter.bat"

if (-not (Test-Path -LiteralPath $junctionPath)) {
  New-Item -ItemType Junction -Path $junctionPath -Target $repoPath | Out-Null
}

$localConfig = Join-Path $PSScriptRoot "start_windows.local.ps1"
if (Test-Path -LiteralPath $localConfig) {
  . $localConfig
}

if ([string]::IsNullOrWhiteSpace($env:SUPABASE_PUBLISHABLE_KEY)) {
  throw "Defina SUPABASE_PUBLISHABLE_KEY em tools/start_windows.local.ps1."
}

$supabaseUrl = if ([string]::IsNullOrWhiteSpace($env:SUPABASE_URL)) {
  "https://libpncdxxgwshnlxicbt.supabase.co"
} else {
  $env:SUPABASE_URL.TrimEnd('/')
}
$manifestUrl = "$supabaseUrl/storage/v1/object/public/app-updates/latest.json"

Push-Location $junctionPath
try {
  & $flutter build windows --release `
    "--build-name=$Version" `
    "--dart-define=SUPABASE_URL=$supabaseUrl" `
    "--dart-define=SUPABASE_PUBLISHABLE_KEY=$($env:SUPABASE_PUBLISHABLE_KEY)" `
    "--dart-define=UPDATE_MANIFEST_URL=$manifestUrl" `
    "--dart-define=ALLOW_ACCOUNT_SIGNUP=false"
  if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

  $isccCandidates = @(
    (Join-Path $env:ProgramFiles "Inno Setup 6\ISCC.exe"),
    (Join-Path ${env:ProgramFiles(x86)} "Inno Setup 6\ISCC.exe")
  )
  $iscc = $isccCandidates | Where-Object { Test-Path -LiteralPath $_ } |
    Select-Object -First 1
  if (-not $iscc) {
    throw "Inno Setup 6 não encontrado. Instale-o antes de gerar o instalador."
  }

  & $iscc "/DMyAppVersion=$Version" "installer\sistema-rgt.iss"
  if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

  $installer = Join-Path $junctionPath "dist\SistemaRGT-Setup-$Version.exe"
  if (-not (Test-Path -LiteralPath $installer)) {
    throw "O instalador esperado não foi gerado: $installer"
  }

  if ($Sign) {
    if ([string]::IsNullOrWhiteSpace($CertificateThumbprint)) {
      throw "Informe -CertificateThumbprint para assinar a release."
    }
    $signtool = (Get-Command signtool.exe -ErrorAction SilentlyContinue).Source
    if (-not $signtool) {
      throw "signtool.exe não encontrado no Windows SDK."
    }
    & $signtool sign /sha1 $CertificateThumbprint /fd SHA256 /tr `
      http://timestamp.digicert.com /td SHA256 $installer
    if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
  }

  $hash = (Get-FileHash -LiteralPath $installer -Algorithm SHA256).Hash.ToLower()
  $fileName = [IO.Path]::GetFileName($installer)
  $downloadUrl = "$supabaseUrl/storage/v1/object/public/app-updates/windows/$fileName"
  $manifest = [ordered]@{
    version = $Version
    windows_url = $downloadUrl
    sha256 = $hash
    notes = $Notes
    mandatory = [bool]$Mandatory
  }
  $manifestPath = Join-Path $junctionPath "dist\latest.json"
  $manifestJson = $manifest | ConvertTo-Json
  [IO.File]::WriteAllText(
    $manifestPath,
    $manifestJson,
    (New-Object Text.UTF8Encoding($false))
  )

  if ($Upload) {
    if ([string]::IsNullOrWhiteSpace($env:SUPABASE_SERVICE_ROLE_KEY)) {
      throw "Defina SUPABASE_SERVICE_ROLE_KEY apenas no ambiente administrativo."
    }
    $headers = @{
      apikey = $env:SUPABASE_SERVICE_ROLE_KEY
      Authorization = "Bearer $($env:SUPABASE_SERVICE_ROLE_KEY)"
      "x-upsert" = "true"
    }
    Invoke-RestMethod -Method Post `
      -Uri "$supabaseUrl/storage/v1/object/app-updates/windows/$fileName" `
      -Headers $headers -ContentType "application/vnd.microsoft.portable-executable" `
      -InFile $installer | Out-Null
    Invoke-RestMethod -Method Post `
      -Uri "$supabaseUrl/storage/v1/object/app-updates/latest.json" `
      -Headers $headers -ContentType "application/json" `
      -InFile $manifestPath | Out-Null
  }

  Write-Host "Release pronta: $installer"
  Write-Host "Manifesto: $manifestPath"
  Write-Host "SHA-256: $hash"
} finally {
  Pop-Location
}
