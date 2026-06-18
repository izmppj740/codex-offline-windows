$ErrorActionPreference = "Stop"

$Root = Split-Path -Parent $MyInvocation.MyCommand.Path
$ExpandedRoot = Join-Path $Root "desktop-expanded"

$Payload = Get-ChildItem -LiteralPath $ExpandedRoot -Directory -ErrorAction SilentlyContinue |
  Where-Object { Test-Path -LiteralPath (Join-Path $_.FullName "app\Codex.exe") } |
  Select-Object -First 1

if (-not $Payload) {
  throw "No desktop payload with app\Codex.exe was found under desktop-expanded."
}

$Exe = Join-Path $Payload.FullName "app\Codex.exe"
Write-Host "Launching extracted Codex desktop executable:"
Write-Host $Exe
Write-Host ""
Write-Host "This portable-style launch is experimental. Prefer the Microsoft Store installed app when available."
Start-Process -FilePath $Exe
