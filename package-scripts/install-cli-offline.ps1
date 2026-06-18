param(
  [switch]$SkipNodeInstall
)

$ErrorActionPreference = "Stop"

$Root = Split-Path -Parent $MyInvocation.MyCommand.Path
$MainPackage = Join-Path $Root "npm\openai-codex-0.135.0.tgz"
$NativePackage = Join-Path $Root "npm\openai-codex-0.135.0-win32-x64.tgz"
$NodeMsi = Join-Path $Root "installers\node-v24.0.0-x64.msi"
$NpmCache = Join-Path $Root "npm-cache"

function Write-Step($Message) {
  Write-Host "==> $Message"
}

function Test-NodeReady {
  $node = Get-Command node -ErrorAction SilentlyContinue
  if (-not $node) {
    return $false
  }

  $major = (& node -p "Number(process.versions.node.split('.')[0])")
  return ([int]$major -ge 16)
}

function Install-NodeIfNeeded {
  if (Test-NodeReady) {
    Write-Step "Node is already installed: $(node --version)"
    return
  }

  if ($SkipNodeInstall) {
    throw "Node.js >=16 is required, but SkipNodeInstall was set."
  }

  if (-not (Test-Path -LiteralPath $NodeMsi)) {
    throw "Node installer not found: $NodeMsi"
  }

  Write-Step "Installing bundled Node.js MSI"
  $args = @("/i", "`"$NodeMsi`"", "/qn", "/norestart")
  $process = Start-Process -FilePath "msiexec.exe" -ArgumentList $args -Wait -PassThru
  if ($process.ExitCode -ne 0) {
    throw "Node MSI failed with exit code $($process.ExitCode). Try running PowerShell as Administrator."
  }

  $machineNode = "C:\Program Files\nodejs"
  if ((Test-Path -LiteralPath $machineNode) -and ($env:PATH -notlike "*$machineNode*")) {
    $env:PATH = "$machineNode;$env:PATH"
  }

  if (-not (Test-NodeReady)) {
    throw "Node was installed, but this shell cannot see node.exe yet. Open a new PowerShell window and rerun this script."
  }
}

function Install-CodexCli {
  if ($env:PROCESSOR_ARCHITECTURE -notmatch "AMD64|x64") {
    throw "This package is for Windows x64 only. Current architecture: $env:PROCESSOR_ARCHITECTURE"
  }

  foreach ($file in @($MainPackage, $NativePackage)) {
    if (-not (Test-Path -LiteralPath $file)) {
      throw "Required package not found: $file"
    }
  }

  Write-Step "Installing Codex CLI main package from local tarball"
  npm install -g $MainPackage --cache $NpmCache --offline --omit=optional --no-audit --fund=false

  $globalRoot = (& npm root -g).Trim()
  $codexRoot = Join-Path $globalRoot "@openai\codex"
  if (-not (Test-Path -LiteralPath $codexRoot)) {
    throw "Codex package was not found after npm install: $codexRoot"
  }

  Write-Step "Injecting bundled Windows x64 native vendor files"
  $tempRoot = Join-Path ([System.IO.Path]::GetTempPath()) ("codex-native-" + [System.Guid]::NewGuid().ToString("N"))
  New-Item -ItemType Directory -Force -Path $tempRoot | Out-Null
  try {
    tar -xzf $NativePackage -C $tempRoot
    $vendorSource = Join-Path $tempRoot "package\vendor"
    $vendorTarget = Join-Path $codexRoot "vendor"
    if (-not (Test-Path -LiteralPath $vendorSource)) {
      throw "Native vendor folder was not found inside $NativePackage"
    }
    if (Test-Path -LiteralPath $vendorTarget) {
      Remove-Item -LiteralPath $vendorTarget -Recurse -Force
    }
    Copy-Item -LiteralPath $vendorSource -Destination $vendorTarget -Recurse -Force
  }
  finally {
    if (Test-Path -LiteralPath $tempRoot) {
      Remove-Item -LiteralPath $tempRoot -Recurse -Force
    }
  }

  $prefix = (& npm prefix -g).Trim()
  $codexCmd = Join-Path $prefix "codex.cmd"
  if (-not (Test-Path -LiteralPath $codexCmd)) {
    $cmd = Get-Command codex -ErrorAction SilentlyContinue
    if ($cmd) {
      $codexCmd = $cmd.Source
    }
  }

  Write-Step "Verifying Codex CLI"
  & $codexCmd --version
}

Install-NodeIfNeeded
Install-CodexCli
Write-Host ""
Write-Host "Codex CLI offline install completed."
