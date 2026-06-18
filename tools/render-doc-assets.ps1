param(
  [string]$Root = (Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path))
)

$ErrorActionPreference = "Stop"

Add-Type -AssemblyName System.Drawing

$AssetsDir = Join-Path $Root "docs\assets"
$ScreenshotsDir = Join-Path $Root "docs\screenshots"
New-Item -ItemType Directory -Force -Path $AssetsDir, $ScreenshotsDir | Out-Null

function New-Color([int]$A, [int]$R, [int]$G, [int]$B) {
  [System.Drawing.Color]::FromArgb($A, $R, $G, $B)
}

function New-Font($Size, $Style = [System.Drawing.FontStyle]::Regular) {
  $family = "Microsoft YaHei UI"
  try {
    return [System.Drawing.Font]::new($family, [single]$Size, $Style, [System.Drawing.GraphicsUnit]::Pixel)
  }
  catch {
    return [System.Drawing.Font]::new("Segoe UI", [single]$Size, $Style, [System.Drawing.GraphicsUnit]::Pixel)
  }
}

function New-RoundRectPath([float]$X, [float]$Y, [float]$W, [float]$H, [float]$R) {
  $path = [System.Drawing.Drawing2D.GraphicsPath]::new()
  $d = $R * 2
  $path.AddArc($X, $Y, $d, $d, 180, 90)
  $path.AddArc($X + $W - $d, $Y, $d, $d, 270, 90)
  $path.AddArc($X + $W - $d, $Y + $H - $d, $d, $d, 0, 90)
  $path.AddArc($X, $Y + $H - $d, $d, $d, 90, 90)
  $path.CloseFigure()
  return $path
}

function Fill-RoundRect($Graphics, [float]$X, [float]$Y, [float]$W, [float]$H, [float]$R, $Color) {
  $brush = [System.Drawing.SolidBrush]::new($Color)
  if ($R -le 0) {
    $Graphics.FillRectangle($brush, $X, $Y, $W, $H)
    $brush.Dispose()
    return
  }
  $path = New-RoundRectPath $X $Y $W $H $R
  $Graphics.FillPath($brush, $path)
  $path.Dispose()
  $brush.Dispose()
}

function Stroke-RoundRect($Graphics, [float]$X, [float]$Y, [float]$W, [float]$H, [float]$R, $Color, [float]$Width = 1) {
  $pen = [System.Drawing.Pen]::new($Color, $Width)
  if ($R -le 0) {
    $Graphics.DrawRectangle($pen, $X, $Y, $W, $H)
    $pen.Dispose()
    return
  }
  $path = New-RoundRectPath $X $Y $W $H $R
  $Graphics.DrawPath($pen, $path)
  $path.Dispose()
  $pen.Dispose()
}

function Draw-Text($Graphics, [string]$Text, $Font, $Color, [float]$X, [float]$Y, [float]$W, [float]$H) {
  $brush = [System.Drawing.SolidBrush]::new($Color)
  $format = [System.Drawing.StringFormat]::new()
  $format.Trimming = [System.Drawing.StringTrimming]::None
  $rect = [System.Drawing.RectangleF]::new($X, $Y, $W, $H)
  $Graphics.DrawString($Text, $Font, $brush, $rect, $format)
  $format.Dispose()
  $brush.Dispose()
}

function Draw-CoverImage($Graphics, [string]$Path, [int]$W, [int]$H) {
  $image = [System.Drawing.Image]::FromFile($Path)
  try {
    $scale = [Math]::Max($W / $image.Width, $H / $image.Height)
    $drawW = $image.Width * $scale
    $drawH = $image.Height * $scale
    $x = ($W - $drawW) / 2
    $y = ($H - $drawH) / 2
    $dest = [System.Drawing.RectangleF]::new([single]$x, [single]$y, [single]$drawW, [single]$drawH)
    $Graphics.DrawImage($image, $dest)
  }
  finally {
    $image.Dispose()
  }
}

function Save-Png($Bitmap, [string]$Path) {
  $Bitmap.Save($Path, [System.Drawing.Imaging.ImageFormat]::Png)
  Write-Host "Wrote $Path"
}

function New-PromoInstaller {
  $w = 1600
  $h = 900
  $bmp = [System.Drawing.Bitmap]::new($w, $h)
  $g = [System.Drawing.Graphics]::FromImage($bmp)
  try {
    $g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
    $g.TextRenderingHint = [System.Drawing.Text.TextRenderingHint]::AntiAliasGridFit
    Draw-CoverImage $g (Join-Path $AssetsDir "promo-bg-installer.png") $w $h

    $grad = [System.Drawing.Drawing2D.LinearGradientBrush]::new(
      [System.Drawing.Rectangle]::new(0, 0, $w, $h),
      (New-Color 245 4 10 20),
      (New-Color 60 4 10 20),
      [System.Drawing.Drawing2D.LinearGradientMode]::Horizontal
    )
    $g.FillRectangle($grad, 0, 0, $w, $h)
    $grad.Dispose()

    Fill-RoundRect $g 96 92 360 48 24 (New-Color 215 17 189 226)
    Draw-Text $g "Windows x64 全量离线包" (New-Font 24 ([System.Drawing.FontStyle]::Bold)) (New-Color 255 4 20 33) 126 102 310 34

    Draw-Text $g "Codex Offline" (New-Font 84 ([System.Drawing.FontStyle]::Bold)) (New-Color 255 255 255 255) 96 168 700 100
    Draw-Text $g "0.135.0 一键安装版" (New-Font 48 ([System.Drawing.FontStyle]::Bold)) (New-Color 255 110 226 255) 100 270 720 64
    Draw-Text $g "面向 Win10 / Win11 / Windows Server 的完整离线部署包，内置 CLI、桌面负载、Node.js 与本地 npm 缓存。" (New-Font 29) (New-Color 235 226 237 249) 104 365 760 128

    $badges = @(
      @{ Text = "setup.exe"; Width = 170 },
      @{ Text = "full.tar.gz"; Width = 190 },
      @{ Text = "SHA256 可校验"; Width = 220 },
      @{ Text = "无需现场下载核心组件"; Width = 300 }
    )
    $x = 104
    foreach ($badge in $badges) {
      $bw = $badge.Width
      Fill-RoundRect $g $x 536 $bw 54 12 (New-Color 190 255 255 255)
      Draw-Text $g $badge.Text (New-Font 22 ([System.Drawing.FontStyle]::Bold)) (New-Color 255 18 31 43) ($x + 20) 548 ($bw - 32) 34
      $x += $bw + 18
    }

    Draw-Text $g "Release: codex-offline-windows-x64-0.135.0" (New-Font 24) (New-Color 220 212 224 238) 106 720 780 38
    Draw-Text $g "GitHub: izmppj740/codex-offline-windows" (New-Font 24) (New-Color 220 212 224 238) 106 762 780 38

    Save-Png $bmp (Join-Path $AssetsDir "promo-codex-offline-installer.png")
  }
  finally {
    $g.Dispose()
    $bmp.Dispose()
  }
}

function New-PromoEnterprise {
  $w = 1600
  $h = 900
  $bmp = [System.Drawing.Bitmap]::new($w, $h)
  $g = [System.Drawing.Graphics]::FromImage($bmp)
  try {
    $g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
    $g.TextRenderingHint = [System.Drawing.Text.TextRenderingHint]::AntiAliasGridFit
    Draw-CoverImage $g (Join-Path $AssetsDir "promo-bg-enterprise.png") $w $h

    $panelColor = New-Color 225 247 251 255
    Fill-RoundRect $g 860 92 620 690 18 $panelColor
    Stroke-RoundRect $g 860 92 620 690 18 (New-Color 150 90 151 196) 2

    Fill-RoundRect $g 910 142 184 46 23 (New-Color 230 16 126 206)
    Draw-Text $g "离线部署" (New-Font 23 ([System.Drawing.FontStyle]::Bold)) (New-Color 255 255 255 255) 948 151 130 30

    Draw-Text $g "内网环境也能装 Codex" (New-Font 48 ([System.Drawing.FontStyle]::Bold)) (New-Color 255 9 28 43) 910 220 520 124
    Draw-Text $g "为无外网、弱网络、Windows Server 机房和批量交付准备的完整安装资料。" (New-Font 27) (New-Color 255 57 75 91) 914 360 510 112

    $items = @(
      "支持 Win10 / Win11 / Server",
      "内置 Windows x64 原生 CLI",
      "包含 Node.js、npm 缓存和校验清单",
      "NSIS 安装器创建桌面与命令行入口"
    )
    $y = 500
    foreach ($item in $items) {
      Fill-RoundRect $g 916 $y 34 34 17 (New-Color 255 23 201 147)
      Draw-Text $g "✓" (New-Font 24 ([System.Drawing.FontStyle]::Bold)) (New-Color 255 255 255 255) 923 ($y + 1) 26 30
      Draw-Text $g $item (New-Font 23 ([System.Drawing.FontStyle]::Bold)) (New-Color 255 15 35 51) 970 ($y - 1) 460 42
      $y += 62
    }

    Save-Png $bmp (Join-Path $AssetsDir "promo-codex-offline-enterprise.png")
  }
  finally {
    $g.Dispose()
    $bmp.Dispose()
  }
}

function New-InstallerScreenshot(
  [string]$Name,
  [string]$StepTitle,
  [string]$StepSubTitle,
  [string]$BodyTitle,
  [string[]]$Lines,
  [string]$SelectedPath = "",
  [string]$PrimaryButton = "下一步 >"
) {
  $w = 1280
  $h = 820
  $bmp = [System.Drawing.Bitmap]::new($w, $h)
  $g = [System.Drawing.Graphics]::FromImage($bmp)
  try {
    $g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
    $g.TextRenderingHint = [System.Drawing.Text.TextRenderingHint]::AntiAliasGridFit

    $bg = [System.Drawing.SolidBrush]::new((New-Color 255 236 240 245))
    $g.FillRectangle($bg, 0, 0, $w, $h)
    $bg.Dispose()

    Fill-RoundRect $g 130 70 1020 680 10 (New-Color 255 255 255 255)
    Stroke-RoundRect $g 130 70 1020 680 10 (New-Color 255 184 194 205) 1

    $titleBar = [System.Drawing.SolidBrush]::new((New-Color 255 242 246 250))
    $g.FillRectangle($titleBar, 131, 71, 1018, 56)
    $titleBar.Dispose()
    Draw-Text $g "CODEX 离线安装包 安装" (New-Font 21 ([System.Drawing.FontStyle]::Bold)) (New-Color 255 31 41 55) 158 87 360 30

    $header = [System.Drawing.SolidBrush]::new((New-Color 255 248 251 255))
    $g.FillRectangle($header, 131, 128, 1018, 110)
    $header.Dispose()
    Draw-Text $g $StepTitle (New-Font 30 ([System.Drawing.FontStyle]::Bold)) (New-Color 255 15 23 42) 178 154 720 40
    Draw-Text $g $StepSubTitle (New-Font 21) (New-Color 255 77 91 108) 180 198 760 32

    Fill-RoundRect $g 178 280 182 182 24 (New-Color 255 15 23 42)
    Fill-RoundRect $g 216 318 106 106 16 (New-Color 255 22 190 226)
    Draw-Text $g "C" (New-Font 66 ([System.Drawing.FontStyle]::Bold)) (New-Color 255 255 255 255) 245 333 80 80

    Draw-Text $g $BodyTitle (New-Font 31 ([System.Drawing.FontStyle]::Bold)) (New-Color 255 17 24 39) 410 286 600 48
    $lineY = 350
    foreach ($line in $Lines) {
      Draw-Text $g $line (New-Font 23) (New-Color 255 55 65 81) 414 $lineY 620 34
      $lineY += 44
    }

    if ($SelectedPath -ne "") {
      Fill-RoundRect $g 410 505 500 50 6 (New-Color 255 248 250 252)
      Stroke-RoundRect $g 410 505 500 50 6 (New-Color 255 190 200 214) 1
      Draw-Text $g $SelectedPath (New-Font 22) (New-Color 255 31 41 55) 426 518 460 30
      Fill-RoundRect $g 930 505 100 50 6 (New-Color 255 241 245 249)
      Stroke-RoundRect $g 930 505 100 50 6 (New-Color 255 190 200 214) 1
      Draw-Text $g "浏览..." (New-Font 21) (New-Color 255 31 41 55) 950 518 70 30
    }

    $footer = [System.Drawing.SolidBrush]::new((New-Color 255 246 248 251))
    $g.FillRectangle($footer, 131, 654, 1018, 95)
    $footer.Dispose()
    Stroke-RoundRect $g 130 654 1020 96 0 (New-Color 255 220 226 235) 1

    Fill-RoundRect $g 705 682 112 42 6 (New-Color 255 241 245 249)
    Stroke-RoundRect $g 705 682 112 42 6 (New-Color 255 200 210 222) 1
    Draw-Text $g "< 上一步" (New-Font 18) (New-Color 255 111 124 143) 730 693 70 24

    Fill-RoundRect $g 832 682 124 42 6 (New-Color 255 14 116 204)
    Draw-Text $g $PrimaryButton (New-Font 18 ([System.Drawing.FontStyle]::Bold)) (New-Color 255 255 255 255) 858 693 78 24

    Fill-RoundRect $g 972 682 104 42 6 (New-Color 255 241 245 249)
    Stroke-RoundRect $g 972 682 104 42 6 (New-Color 255 200 210 222) 1
    Draw-Text $g "取消" (New-Font 18) (New-Color 255 31 41 55) 1006 693 48 24

    Save-Png $bmp (Join-Path $ScreenshotsDir $Name)
  }
  finally {
    $g.Dispose()
    $bmp.Dispose()
  }
}

function New-InstallerScreenshots {
  New-InstallerScreenshot `
    -Name "installer-01-intro.png" `
    -StepTitle "第一步：安装包说明" `
    -StepSubTitle "CODEX 离线安装包 / 制作方：aiopentool" `
    -BodyTitle "CODEX 离线安装包" `
    -Lines @("制作方：aiopentool", "AI 小白 快乐营", "手把手教你制作第一个 APP，改变世界。", "访问：https://aiopentool.com/")

  New-InstallerScreenshot `
    -Name "installer-02-location.png" `
    -StepTitle "第二步：选择安装位置" `
    -StepSubTitle "请选择 CODEX 离线安装包释放到本机的位置" `
    -BodyTitle "选择安装目录" `
    -Lines @("默认安装到当前用户目录，不需要管理员权限。", "安装器会释放完整离线包并创建桌面入口。") `
    -SelectedPath "%LOCALAPPDATA%\OpenAI"

  New-InstallerScreenshot `
    -Name "installer-03-finish.png" `
    -StepTitle "第四步：安装成功" `
    -StepSubTitle "CODEX 已经安装完成，请点击完成退出安装器" `
    -BodyTitle "安装完成" `
    -Lines @("桌面入口：CODEX 离线桌面版", "命令行：新开终端后运行 codex --version", "网站入口：桌面上的 AI保姆站", "可在设置中卸载 CODEX 离线安装包") `
    -PrimaryButton "完成"
}

New-PromoInstaller
New-PromoEnterprise
New-InstallerScreenshots





