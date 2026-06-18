param(
  [string]$PathToRemove = (Join-Path (Split-Path -Parent $MyInvocation.MyCommand.Path) "cli-native")
)

$ErrorActionPreference = "Stop"

$FullPath = [System.IO.Path]::GetFullPath($PathToRemove).TrimEnd("\")
$Current = [Environment]::GetEnvironmentVariable("Path", "User")
if (-not $Current) {
  exit 0
}

$Parts = $Current -split ";" | Where-Object {
  $_ -and -not $_.TrimEnd("\").Equals($FullPath, [System.StringComparison]::OrdinalIgnoreCase)
}

[Environment]::SetEnvironmentVariable("Path", ($Parts -join ";"), "User")
Write-Host "Removed from user PATH: $FullPath"
