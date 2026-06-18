param(
  [switch]$NoPortableFallback
)

$ErrorActionPreference = "Stop"

$Root = Split-Path -Parent $MyInvocation.MyCommand.Path
$ExpandedRoot = Join-Path $Root "desktop-expanded"

if (-not (Test-Path -LiteralPath $ExpandedRoot)) {
  throw "desktop-expanded folder was not found. This package does not contain the extracted desktop payload."
}

$Payload = Get-ChildItem -LiteralPath $ExpandedRoot -Directory |
  Where-Object { Test-Path -LiteralPath (Join-Path $_.FullName "AppxManifest.xml") } |
  Select-Object -First 1

if (-not $Payload) {
  throw "No AppxManifest.xml was found under desktop-expanded."
}

$Manifest = Join-Path $Payload.FullName "AppxManifest.xml"
$ManifestXml = [xml](Get-Content -LiteralPath $Manifest -Raw)
$IdentityName = $ManifestXml.Package.Identity.Name
$Version = $ManifestXml.Package.Identity.Version
$Exe = Join-Path $Payload.FullName "app\Codex.exe"

$Installed = Get-AppxPackage -Name $IdentityName -ErrorAction SilentlyContinue
if ($Installed) {
  Write-Host "$IdentityName is already installed: $($Installed.PackageFullName)"
  exit 0
}

Write-Host "Registering expanded Codex desktop payload:"
Write-Host $Payload.FullName
Write-Host ""
Write-Host "This is an experimental fallback from an extracted Store package payload."
Write-Host "The official supported route is Microsoft Store / winget."
Write-Host ""

try {
  Add-AppxPackage -Register $Manifest -DisableDevelopmentMode
  $After = Get-AppxPackage -Name $IdentityName -ErrorAction SilentlyContinue
  if (-not $After) {
    throw "Registration completed without error, but $IdentityName is still not visible to Get-AppxPackage."
  }
  Write-Host "Registered $($After.PackageFullName)"
}
catch {
  Write-Warning "Expanded payload Appx registration failed for $IdentityName $Version."
  Write-Warning $_.Exception.Message

  if ($NoPortableFallback) {
    exit 1
  }

  if (-not (Test-Path -LiteralPath $Exe)) {
    throw "Portable fallback cannot continue because Codex.exe was not found: $Exe"
  }

  $Programs = [Environment]::GetFolderPath("Programs")
  $Shortcut = Join-Path $Programs "Codex Offline Expanded.lnk"
  $Shell = New-Object -ComObject WScript.Shell
  $Link = $Shell.CreateShortcut($Shortcut)
  $Link.TargetPath = $Exe
  $Link.WorkingDirectory = Split-Path -Parent $Exe
  $Link.IconLocation = "$Exe,0"
  $Link.Description = "Codex Desktop extracted payload fallback"
  $Link.Save()

  Write-Host ""
  Write-Host "Created portable fallback Start Menu shortcut:"
  Write-Host $Shortcut
  Write-Host ""
  Write-Host "Launching Codex from extracted payload..."
  Start-Process -FilePath $Exe
}
