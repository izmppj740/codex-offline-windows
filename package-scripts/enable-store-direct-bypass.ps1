$ErrorActionPreference = "Stop"

$Key = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Internet Settings"
$Add = @(
  "storeedgefd.dsx.mp.microsoft.com",
  "displaycatalog.mp.microsoft.com",
  "purchase.mp.microsoft.com",
  "*.mp.microsoft.com",
  "get.microsoft.com",
  "*.s-microsoft.com",
  "*.windowsupdate.com",
  "ctldl.windowsupdate.com",
  "*.delivery.mp.microsoft.com",
  "*.blob.core.windows.net"
)

$Settings = Get-ItemProperty -Path $Key
$Parts = @()
if ($Settings.ProxyOverride) {
  $Parts += [string]$Settings.ProxyOverride -split ";" | Where-Object { $_ }
}

foreach ($Item in $Add) {
  if ($Parts -notcontains $Item) {
    $Parts += $Item
  }
}

Set-ItemProperty -Path $Key -Name ProxyOverride -Value ($Parts -join ";")

Add-Type @'
using System;
using System.Runtime.InteropServices;
public static class WinInetProxyNotify {
  [DllImport("wininet.dll", SetLastError = true)]
  public static extern bool InternetSetOption(IntPtr hInternet, int dwOption, IntPtr lpBuffer, int dwBufferLength);
}
'@

[WinInetProxyNotify]::InternetSetOption([IntPtr]::Zero, 39, [IntPtr]::Zero, 0) | Out-Null
[WinInetProxyNotify]::InternetSetOption([IntPtr]::Zero, 37, [IntPtr]::Zero, 0) | Out-Null

Write-Host "Microsoft Store domains were added to the current user's proxy bypass list."
Write-Host "Current ProxyOverride:"
(Get-ItemProperty -Path $Key).ProxyOverride
