param(
  [string]$PathToAdd = (Join-Path (Split-Path -Parent $MyInvocation.MyCommand.Path) "cli-native")
)

$ErrorActionPreference = "Stop"

$FullPath = [System.IO.Path]::GetFullPath($PathToAdd).TrimEnd("\")
$Current = [Environment]::GetEnvironmentVariable("Path", "User")
$Parts = @()
if ($Current) {
  $Parts = $Current -split ";" | Where-Object { $_ }
}

$Exists = $false
foreach ($Part in $Parts) {
  if ($Part.TrimEnd("\").Equals($FullPath, [System.StringComparison]::OrdinalIgnoreCase)) {
    $Exists = $true
    break
  }
}

if (-not $Exists) {
  $NewPath = (@($Parts) + $FullPath) -join ";"
  [Environment]::SetEnvironmentVariable("Path", $NewPath, "User")
  Write-Host "Added to user PATH: $FullPath"
}
else {
  Write-Host "User PATH already contains: $FullPath"
}
