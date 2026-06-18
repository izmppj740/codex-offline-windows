param(
  [string]$OutputFile,
  [switch]$Quiet
)

$ErrorActionPreference = "Stop"

$Root = Split-Path -Parent $MyInvocation.MyCommand.Path
$RequiredFiles = @(
  "npm\openai-codex-0.135.0.tgz",
  "npm\openai-codex-0.135.0-win32-x64.tgz",
  "installers\node-v24.0.0-x64.msi",
  "installers\Codex Store Installer.exe",
  "add-user-path.ps1",
  "remove-user-path.ps1",
  "cli-native\codex.cmd",
  "cli-native\x86_64-pc-windows-msvc\bin\codex.exe",
  "enable-store-direct-bypass.ps1",
  "install-cli-offline.ps1",
  "install-desktop-store.ps1",
  "install-desktop-expanded.ps1",
  "run-desktop-expanded.ps1",
  "README.md"
)

foreach ($relative in $RequiredFiles) {
  $path = Join-Path $Root $relative
  if (-not (Test-Path -LiteralPath $path)) {
    throw "Missing file: $relative"
  }
}

function ConvertTo-LongPath($Path) {
  $FullPath = [System.IO.Path]::GetFullPath($Path)
  if ($FullPath.StartsWith("\\?\")) {
    return $FullPath
  }
  if ($FullPath.StartsWith("\\")) {
    return "\\?\UNC\" + $FullPath.Substring(2)
  }
  return "\\?\" + $FullPath
}

function Get-Sha256Hex($Path) {
  $LongPath = ConvertTo-LongPath $Path
  $Sha = [System.Security.Cryptography.SHA256]::Create()
  $Stream = [System.IO.File]::Open($LongPath, [System.IO.FileMode]::Open, [System.IO.FileAccess]::Read, [System.IO.FileShare]::ReadWrite)
  try {
    $Bytes = $Sha.ComputeHash($Stream)
    return (($Bytes | ForEach-Object { $_.ToString("X2") }) -join "")
  }
  finally {
    $Stream.Dispose()
    $Sha.Dispose()
  }
}

$Lines = Get-ChildItem -LiteralPath $Root -Recurse -File -Force -ErrorAction SilentlyContinue |
  Where-Object {
    $_.FullName -notmatch "\\test-prefix\\" -and
    $_.FullName -notmatch "\\logs\\" -and
    $_.Name -ne "checksums.sha256" -and
    $_.Extension -ne ".zip"
  } |
  Sort-Object FullName |
  ForEach-Object {
    try {
      $hash = Get-Sha256Hex $_.FullName
      "{0}  {1}" -f $hash, ($_.FullName.Substring($Root.Length + 1))
    }
    catch {
      if (-not $Quiet) {
        Write-Warning "Could not hash $($_.FullName): $($_.Exception.Message)"
      }
    }
  }

if ($OutputFile) {
  $OutputPath = if ([System.IO.Path]::IsPathRooted($OutputFile)) {
    $OutputFile
  }
  else {
    Join-Path $Root $OutputFile
  }
  $Lines | Set-Content -LiteralPath $OutputPath -Encoding ASCII
}

if (-not $Quiet) {
  Write-Host "Package files are present."
  Write-Host ""
  Write-Host "SHA256:"
  $Lines
}
else {
  Write-Host "Package files are present. Hash count: $($Lines.Count)"
  if ($OutputFile) {
    Write-Host "Wrote $OutputPath"
  }
}
