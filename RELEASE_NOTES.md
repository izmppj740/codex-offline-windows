# v0.135.0

Codex Offline Windows x64 `0.135.0` 全量离线安装包。

## Release Assets

| 文件 | SHA256 | 大小 |
| --- | --- | --- |
| `codex-offline-windows-x64-0.135.0-setup.exe` | `03A82F40C82C7CB2EA889C75B18C0AA229344010E07BB586FF1A3D1667288891` | 877,258,199 bytes |
| `codex-offline-windows-x64-0.135.0-full.tar.gz` | `C85E03CC4660124853CACF667FAA68FA29BA245DDB10946C1F722B32A19874EF` | 851,183,792 bytes |

## 支持环境

- Windows 10 x64
- Windows 11 x64
- Windows Server x64

## 主要内容

- Codex CLI `0.135.0`
- Windows x64 原生 CLI vendor 文件
- Node.js x64 安装器
- npm 离线缓存
- Codex Desktop 提取负载和 Store 安装入口脚本
- Microsoft Visual C++ 2015-2022 x64 运行库安装器
- 一键安装器、卸载器、PATH 写入脚本和包内 SHA256 清单

## 使用方式

普通用户建议下载并运行：

```text
codex-offline-windows-x64-0.135.0-setup.exe
```

需要审计或手动部署时下载：

```text
codex-offline-windows-x64-0.135.0-full.tar.gz
```

手动解压后运行：

```powershell
.\install-cli-offline.ps1
.\verify-package.ps1
```

## 校验

```powershell
Get-FileHash -Algorithm SHA256 .\codex-offline-windows-x64-0.135.0-setup.exe
Get-FileHash -Algorithm SHA256 .\codex-offline-windows-x64-0.135.0-full.tar.gz
```

## 注意

这是非官方打包版本。二进制组件分别归其原权利方所有，请在公开分发或二次分发前确认对应许可和授权。
