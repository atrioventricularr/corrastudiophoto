param(
  [string]$ArtifactDir = "apps/desktop-electron/dist-installer",
  [string]$TimestampServer = "http://timestamp.digicert.com"
)

$ErrorActionPreference = "Stop"

Write-Host "Corra Windows Signing"
Write-Host "====================="

$signtool = Get-Command signtool.exe -ErrorAction SilentlyContinue

if (-not $signtool) {
  throw "signtool.exe not found. Install Windows SDK."
}

$artifacts = Get-ChildItem -Path $ArtifactDir -Recurse -Include *.exe,*.msi

if ($artifacts.Count -eq 0) {
  throw "No .exe/.msi artifacts found in $ArtifactDir"
}

foreach ($artifact in $artifacts) {
  Write-Host "Signing $($artifact.FullName)"

  if ($env:WINDOWS_PFX_PATH -and $env:WINDOWS_PFX_PASSWORD) {
    & signtool.exe sign /f $env:WINDOWS_PFX_PATH /p $env:WINDOWS_PFX_PASSWORD /tr $TimestampServer /td sha256 /fd sha256 $artifact.FullName
  } elseif ($env:WINDOWS_CERT_THUMBPRINT) {
    & signtool.exe sign /sha1 $env:WINDOWS_CERT_THUMBPRINT /tr $TimestampServer /td sha256 /fd sha256 $artifact.FullName
  } else {
    throw "Set WINDOWS_PFX_PATH + WINDOWS_PFX_PASSWORD or WINDOWS_CERT_THUMBPRINT."
  }

  & signtool.exe verify /pa /v $artifact.FullName
}

Write-Host "Signing complete."
