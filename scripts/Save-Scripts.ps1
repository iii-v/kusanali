# Halt immediately if there is an error
$ErrorActionPreference = "Stop"

# Define script variables
$scriptDirPath = Join-Path $HOME "stable-diffusion"
$scriptFilePath = Join-Path $scriptDirPath "Start-Automatic1111.ps1"
$shortcutPath = Join-Path $HOME "Desktop\Automatic1111.lnk"
$url = "https://raw.githubusercontent.com/iii-v/noise/main/scripts/Start-Automatic1111.ps1"

# Initialize directory
if (-not (Test-Path $scriptDirPath)) {
    New-Item -Path $scriptDirPath -ItemType Directory | Out-Null
}

# Download the JSON file (if it already exists, it will be overwritten by default)
Invoke-WebRequest -Uri $url -OutFile $scriptFilePath

# Create the desktop shortcut
$shell = New-Object -ComObject ("WScript.Shell")
$shortcut = $shell.CreateShortcut($shortcutPath)
$shortcut.TargetPath = "powershell.exe"
$shortcut.Arguments = "-ExecutionPolicy Bypass -NoExit -File `"$scriptFilePath`""
# $shortcut.IconLocation = "powershell.exe"
$shortcut.Save()

Write-Host ">>> A shortcut for Automatic1111 has been placed on your desktop." -ForegroundColor Green
