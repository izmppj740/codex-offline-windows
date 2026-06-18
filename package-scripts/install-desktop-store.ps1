$ErrorActionPreference = "Stop"

$Root = Split-Path -Parent $MyInvocation.MyCommand.Path
$StoreInstaller = Join-Path $Root "installers\Codex Store Installer.exe"

Write-Host "Codex Desktop for Windows is distributed through Microsoft Store."
Write-Host "This bundled installer is the official Microsoft Store handoff installer, not a full offline MSIX package."
Write-Host ""
Write-Host "If a VPN/local proxy breaks Microsoft Store TLS, run enable-store-direct-bypass.ps1 first."
Write-Host ""

if (Test-Path -LiteralPath $StoreInstaller) {
  Write-Host "Launching bundled Store installer..."
  Start-Process -FilePath $StoreInstaller -Wait
}
else {
  Write-Host "Bundled Store installer missing, trying winget..."
  winget install Codex -s msstore --accept-source-agreements --accept-package-agreements
}
