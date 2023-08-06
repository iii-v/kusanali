<#
    .SYNOPSIS
    Starts the Automatic1111 application.

    .DESCRIPTION
    Automatic1111 Bootstrapper Script
    ---------------------------------
    This script contains startup logic for bootstrapping Automatic1111.
    It handles the following tasks:

    - Removing default App Execution Aliases for Python
    - Verifying the existence of dependencies like Git and pyenv
    - Verifying that the expected Python version is installed
    - Downloading Automatic1111 (and extensions)
    - Downloading model files (if any)
    - Starting the Gradio service

    .PARAMETER Quiet
    Specifies if the log verbosity should be lowered.

    .INPUTS
    None. You can't pipe objects to Start-Automatic1111.ps1.

    .OUTPUTS
    None. Start-Automatic1111.ps1 doesn't generate any output.

    .EXAMPLE
    PS> .\Start-Automatic1111.ps1

    .LINK
    Online version: https://github.com/iii-v/kusanali
#>

[CmdletBinding()]
param (
    [ValidateNotNullOrEmpty()]
    [String]
    $PythonVersion = "3.10.6",

    [switch]
    $Quiet
)

Function Remove-AppExecutionAlias {
    [CmdletBinding()]
    param ()

    Remove-Item $env:LOCALAPPDATA\Microsoft\WindowsApps\python.exe -ErrorAction SilentlyContinue
    Remove-Item $env:LOCALAPPDATA\Microsoft\WindowsApps\python3.exe -ErrorAction SilentlyContinue
}

Function Assert-Command {
    [CmdletBinding()]
    [OutputType([bool])]
    param (
        [Parameter(Mandatory)]
        [string]
        $Name
    )

    return [bool](Get-Command $Name -ErrorAction SilentlyContinue)
}

Function Install-Git {
    [CmdletBinding()]
    param ()

    if (Assert-Command git) {
        Write-Verbose "Git already installed."
        return
    }

    Write-Verbose "Git not found. Installing..."
    # winget may not be available: https://learn.microsoft.com/en-us/windows/package-manager/winget/#install-winget
    Add-AppxPackage -RegisterByFamilyName -MainPackage Microsoft.DesktopAppInstaller_8wekyb3d8bbwe
    # Issue with git command not loaded into shell: https://github.com/microsoft/winget-cli/issues/549
    winget install --id Git.Git -e --source winget
    $env:Path = [System.Environment]::GetEnvironmentVariable("Path", "Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path", "User")
}

Function Set-GitSafeDirectory {
    [CmdletBinding()]
    param ()

    git config --global safe.directory "*"
    Write-Verbose "Set Git 'safe.directory' config."
}

Function Sync-Repo {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [string]
        $RepoUrl,

        [Parameter(Mandatory)]
        [string]
        $ClonePath
    )

    $RepoName = ($RepoUrl -split "/")[-1] -replace ".git$", ""

    # Check if the directory contains a .git folder
    if (Test-Path (Join-Path $ClonePath ".git")) {
        Write-Verbose "Pulling latest changes for '$RepoName' repository..."
        git -C $ClonePath pull -r
    }
    else {
        Write-Verbose "Cloning '$RepoName' repository..."
        git clone $RepoUrl $ClonePath
    }
}

Function Install-Pyenv {
    [CmdletBinding()]
    param (
        [ValidateNotNullOrEmpty()]
        [string]
        $Path = (Join-Path $HOME ".pyenv")
    )

    # Needs to be cached before installing pyenv, or else state will have been modified
    $IsPyenvAlreadyInstalled = Assert-Command pyenv

    Sync-Repo -RepoUrl "https://github.com/pyenv-win/pyenv-win.git" -ClonePath $Path

    if (-Not $IsPyenvAlreadyInstalled) {
        Write-Verbose "Setting environment variables for pyenv."
        $SrcPath = Join-Path $Path "pyenv-win"
        [System.Environment]::SetEnvironmentVariable("PYENV", $SrcPath, "User")
        [System.Environment]::SetEnvironmentVariable("PYENV_ROOT", $SrcPath, "User")
        [System.Environment]::SetEnvironmentVariable("PYENV_HOME", $SrcPath, "User")
        [System.Environment]::SetEnvironmentVariable(
            "Path",
            (Join-Path $SrcPath "bin;") + (Join-Path $SrcPath "shims;") + [System.Environment]::GetEnvironmentVariable("Path", "User"),
            "User"
        )
        $env:Path = [System.Environment]::GetEnvironmentVariable("Path", "Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path", "User")
    }
}

Function Install-Python {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [string]
        $Version
    )

    if (& pyenv versions --bare | Select-String $Version) {
        Write-Verbose "Python $Version already installed via pyenv."
        return
    }

    Write-Verbose "Installing Python $Version via pyenv..."
    pyenv install $Version
}

Function Sync-Automatic1111 {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [string]
        $ProjectPath,

        [Parameter(Mandatory)]
        [string]
        $PythonVersion
    )

    Sync-Repo -RepoUrl "https://github.com/AUTOMATIC1111/stable-diffusion-webui.git" -ClonePath $ProjectPath
    Set-Content -Path (Join-Path $ProjectPath ".python-version") -Value $PythonVersion

    $VirtualenvPath = Join-Path $ProjectPath "venv\$PythonVersion"
    if (-Not (Test-Path $VirtualenvPath)) {
        Write-Verbose "Creating Python $PythonVersion virtualenv."
        Push-Location
        Set-Location $ProjectPath
        python -m venv $VirtualenvPath
        Pop-Location
    }
    else {
        Write-Verbose "Python $PythonVersion virtualenv already exists."
    }
}

Function Sync-Automatic1111Extension {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [string]
        $ProjectPath,

        [Parameter(Mandatory)]
        [string[]]
        $ExtensionUrl
    )

    foreach ($url in $ExtensionUrl) {
        $dir = Join-Path (Join-Path $ProjectPath "extensions") (($url -split "/")[-1] -replace ".git$", "")
        Sync-Repo -RepoUrl $url -ClonePath $dir
    }
}

Function Start-Automatic1111 {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [string]
        $ProjectPath,

        [Parameter(Mandatory)]
        [string]
        $PythonVersion
    )

    # Prepare environment
    Remove-AppExecutionAlias
    Install-Git
    Set-GitSafeDirectory
    Install-Python -Version $PythonVersion

    # Install Automatic1111 and extensions
    Sync-Automatic1111 -ProjectPath $ProjectPath -PythonVersion $PythonVersion
    Sync-Automatic1111Extension -ProjectPath $ProjectPath -ExtensionUrl (
        "https://github.com/Mikubill/sd-webui-controlnet.git",
        "https://github.com/hako-mikan/sd-webui-regional-prompter.git"
    )

    # Post-install (download ControlNet models)
    $ControlNetExtensionPath = Join-Path $ProjectPath "extensions\sd-webui-controlnet"
    $ControlNetModelsPath = Join-Path $ControlNetExtensionPath "models"
    $ControlNetDownloadsPath = Join-Path $ControlNetExtensionPath "downloads"
    $ControlNetModelFiles = Get-ChildItem -Path $ControlNetModelsPath -Filter "*.pth"
    if (-Not ($ControlNetModelFiles.Count -gt 0)) {
        Write-Verbose "Downloading ControlNet models, this may take a while..."
        # files cloned via LFS do not show any progress status: https://github.com/git-lfs/git-lfs/issues/3704
        git clone https://huggingface.co/lllyasviel/ControlNet-v1-1 $ControlNetDownloadsPath
        $ControlNetModelFiles | Move-Item -Destination $ControlNetModelsPath
        Remove-Item -Path $ControlNetDownloadsPath -Recurse -Force
    }

    # Post-install (init models directories)
    $ModelPath = Join-Path $HOME "stable-diffusion\models"
    foreach (
        $ModelType in @(
            "checkpoint",
            "vae",
            "lora",
            "embedding",
            "hypernetwork",
            "controlnet"
        )
    ) {
        $ModelTypePath = Join-Path $ModelPath $ModelType
        if (-Not (Test-Path $ModelTypePath)) {
            New-Item -ItemType Directory $ModelTypePath | Out-Null
            Write-Verbose "Created directory for '$ModelType' models."
        }
    }

    Push-Location
    Set-Location $ProjectPath

    Write-Verbose "Activating Python virtualenv..."
    & "venv\$PythonVersion\Scripts\Activate.ps1"
    python -m pip install --quiet --upgrade pip setuptools

    Write-Verbose "Starting Gradio service for Automatic1111..."
    try {
        python launch.py `
            --ckpt-dir (Join-Path $ModelPath "checkpoint") `
            --vae-dir (Join-Path $ModelPath "vae") `
            --lora-dir (Join-Path $ModelPath "lora") `
            --embeddings-dir (Join-Path $ModelPath "embedding") `
            --hypernetwork-dir (Join-Path $ModelPath "hypernetwork") `
            --controlnet-dir (Join-Path $ModelPath "controlnet") `
            --autolaunch `
            --update-check `
            --xformers
    }
    finally {
        deactivate
        Write-Verbose "Stopped Gradio service."
        Pop-Location
        exit
    }
}

Start-Automatic1111 `
    -ProjectPath (Join-Path $HOME "stable-diffusion\automatic1111") `
    -PythonVersion "3.10.6" `
    -ErrorAction "Stop" `
    -Verbose:(-Not $Quiet)
