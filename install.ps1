<<<<<<< HEAD
$ErrorActionPreference = 'Stop'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

#region Variables
$soniqFolderPath = "$env:LOCALAPPDATA\soniq"
# Legacy locations from the upstream tool, migrated non-destructively on install.
$soniqLegacyFolderPath = "$env:LOCALAPPDATA\spicetify"
$soniqOldFolderPath = "$HOME\spicetify-cli"
# Override with $env:SONIQ_REPO_URL to install from a custom location.
$soniqRepoUrl = if ($env:SONIQ_REPO_URL) { $env:SONIQ_REPO_URL } else { 'https://github.com/soniq/cli' }
$soniqApiUrl = $soniqRepoUrl -replace 'github\.com', 'api.github.com/repos'
#endregion Variables

#region Functions
function Write-Success {
  [CmdletBinding()]
  param ()
  process {
    Write-Host -Object ' > OK' -ForegroundColor 'Green'
  }
}

function Write-Unsuccess {
  [CmdletBinding()]
  param ()
  process {
    Write-Host -Object ' > ERROR' -ForegroundColor 'Red'
  }
}

function Test-Admin {
  [CmdletBinding()]
  param ()
  begin {
    Write-Host -Object "Checking if the script is not being run as administrator..." -NoNewline
  }
  process {
    $currentUser = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
    -not $currentUser.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
  }
}

function Test-PowerShellVersion {
  [CmdletBinding()]
  param ()
  begin {
    $PSMinVersion = [version]'5.1'
  }
  process {
    Write-Host -Object 'Checking if your PowerShell version is compatible...' -NoNewline
    $PSVersionTable.PSVersion -ge $PSMinVersion
  }
}

function Move-OldSONIQFolder {
  [CmdletBinding()]
  param ()
  process {
    # Migrate the historic per-user folder without deleting the source data.
    if ((Test-Path -Path $soniqOldFolderPath) -and (-not (Test-Path -Path $soniqFolderPath))) {
      Write-Host -Object 'Migrating the legacy per-user folder...' -NoNewline
      Copy-Item -Path "$soniqOldFolderPath\*" -Destination $soniqFolderPath -Recurse -Force
      Write-Success
    }
    # Migrate the legacy upstream config folder without deleting the source data.
    if ((Test-Path -Path $soniqLegacyFolderPath) -and (-not (Test-Path -Path $soniqFolderPath))) {
      Write-Host -Object 'Migrating the legacy upstream folder...' -NoNewline
      Copy-Item -Path "$soniqLegacyFolderPath\*" -Destination $soniqFolderPath -Recurse -Force
      Write-Success
    }
  }
}

function Get-SONIQ {
  [CmdletBinding()]
  param ()
  begin {
    if ($env:PROCESSOR_ARCHITECTURE -eq 'AMD64') {
      $architecture = 'x64'
    }
    elseif ($env:PROCESSOR_ARCHITECTURE -eq 'ARM64') {
      $architecture = 'arm64'
    }
    else {
      $architecture = 'x32'
    }
    if ($v) {
      if ($v -match '^\d+\.\d+\.\d+$') {
        $targetVersion = $v
      }
      else {
        Write-Warning -Message "You have specified an invalid SONIQ version: $v `nThe version must be in the following format: 1.2.3"
        Pause
        exit
      }
    }
    else {
      Write-Host -Object 'Fetching the latest SONIQ version...' -NoNewline
      $latestRelease = Invoke-RestMethod -Uri "$soniqApiUrl/releases/latest"
      $targetVersion = $latestRelease.tag_name -replace 'v', ''
      Write-Success
    }
    $archivePath = [System.IO.Path]::Combine([System.IO.Path]::GetTempPath(), "soniq.zip")
  }
  process {
    Write-Host -Object "Downloading SONIQ v$targetVersion..." -NoNewline
    $Parameters = @{
      Uri            = "$soniqRepoUrl/releases/download/v$targetVersion/soniq-$targetVersion-windows-$architecture.zip"
      UseBasicParsin = $true
      OutFile        = $archivePath
    }
    Invoke-WebRequest @Parameters
    Write-Success
  }
  end {
    $archivePath
  }
}

function Add-SONIQToPath {
  [CmdletBinding()]
  param ()
  begin {
    Write-Host -Object 'Making SONIQ available in the PATH...' -NoNewline
    $user = [EnvironmentVariableTarget]::User
    $path = [Environment]::GetEnvironmentVariable('PATH', $user)
  }
  process {
    $path = $path -replace "$([regex]::Escape($soniqOldFolderPath))\\*;*", ''
    if ($path -notlike "*$soniqFolderPath*") {
      $path = "$path;$soniqFolderPath"
    }
  }
  end {
    [Environment]::SetEnvironmentVariable('PATH', $path, $user)
    if (($env:PATH -split ';') -notcontains $soniqFolderPath) {
      $env:PATH = "$env:PATH;$soniqFolderPath"
    }
    Write-Success
  }
}

function Install-SONIQ {
  [CmdletBinding()]
  param ()
  begin {
    Write-Host -Object 'Installing SONIQ...'
  }
  process {
    $archivePath = Get-SONIQ
    Write-Host -Object 'Extracting SONIQ...' -NoNewline
    Expand-Archive -Path $archivePath -DestinationPath $soniqFolderPath -Force
    Write-Success
    Add-SONIQToPath
  }
  end {
    Remove-Item -Path $archivePath -Force -ErrorAction 'SilentlyContinue'
    Write-Host -Object 'SONIQ was successfully installed!' -ForegroundColor 'Green'
  }
}
#endregion Functions

#region Main
#region Checks
if (-not (Test-PowerShellVersion)) {
  Write-Unsuccess
  Write-Warning -Message 'PowerShell 5.1 or higher is required to run this script'
  Write-Warning -Message "You are running PowerShell $($PSVersionTable.PSVersion)"
  Write-Host -Object 'PowerShell 5.1 install guide:'
  Write-Host -Object 'https://learn.microsoft.com/skypeforbusiness/set-up-your-computer-for-windows-powershell/download-and-install-windows-powershell-5-1'
  Write-Host -Object 'PowerShell 7 install guide:'
  Write-Host -Object 'https://learn.microsoft.com/powershell/scripting/install/installing-powershell-on-windows'
  Pause
  exit
}
else {
  Write-Success
}
if (-not (Test-Admin)) {
  Write-Unsuccess
  Write-Warning -Message "The script was run as administrator. This can result in problems with the installation process or unexpected behavior. Do not continue if you do not know what you are doing."
  $Host.UI.RawUI.Flushinputbuffer()
  $choices = [System.Management.Automation.Host.ChoiceDescription[]] @(
    (New-Object System.Management.Automation.Host.ChoiceDescription '&Yes', 'Abort installation.'),
    (New-Object System.Management.Automation.Host.ChoiceDescription '&No', 'Resume installation.')
  )
  $choice = $Host.UI.PromptForChoice('', 'Do you want to abort the installation process?', $choices, 0)
  if ($choice -eq 0) {
    Write-Host -Object 'SONIQ installation aborted' -ForegroundColor 'Yellow'
    Pause
    exit
  }
}
else {
  Write-Success
}
#endregion Checks

#region SONIQ
$installedSONIQ = Join-Path -Path $soniqFolderPath -ChildPath 'soniq.exe'
if (-not (Test-Path -LiteralPath $installedSONIQ -PathType Leaf)) {
  $installedCommand = Get-Command -Name 'soniq' -CommandType Application -ErrorAction SilentlyContinue | Select-Object -First 1
  if ($installedCommand) {
    $installedSONIQ = $installedCommand.Source
  }
  else {
    $installedSONIQ = $null
  }
}

if ($installedSONIQ) {
  $Host.UI.RawUI.Flushinputbuffer()
  $choices = [System.Management.Automation.Host.ChoiceDescription[]] @(
    (New-Object System.Management.Automation.Host.ChoiceDescription '&Yes', 'Run soniq update.'),
    (New-Object System.Management.Automation.Host.ChoiceDescription '&No', 'Continue with installation.')
  )
  $choice = $Host.UI.PromptForChoice('', 'SONIQ is already installed. Do you want to repair your installation?', $choices, 0)
  if ($choice -eq 0) {
    & $installedSONIQ update
    if ($LASTEXITCODE -ne 0) {
      throw "SONIQ update failed with exit code $LASTEXITCODE."
    }
    return
  }
}

Move-OldSONIQFolder
Install-SONIQ
Write-Host -Object "`nRun" -NoNewline
Write-Host -Object ' soniq -h ' -NoNewline -ForegroundColor 'Cyan'
Write-Host -Object 'to get started'
#endregion SONIQ

#region Marketplace
$Host.UI.RawUI.Flushinputbuffer()
$choices = [System.Management.Automation.Host.ChoiceDescription[]] @(
    (New-Object System.Management.Automation.Host.ChoiceDescription "&Yes", "Install SONIQ Marketplace."),
    (New-Object System.Management.Automation.Host.ChoiceDescription "&No", "Do not install SONIQ Marketplace.")
)
$choice = $Host.UI.PromptForChoice('', "`nDo you also want to install SONIQ Marketplace? It will become available within the Spotify client, where you can easily install themes and extensions.", $choices, 0)
if ($choice -eq 1) {
  Write-Host -Object 'SONIQ Marketplace installation aborted' -ForegroundColor 'Yellow'
}
else {
  Write-Host -Object 'Starting the SONIQ Marketplace installation script..'
  # Third-party community Marketplace resource. Override with $env:SONIQ_MARKETPLACE_URL.
  $marketplaceUrl = if ($env:SONIQ_MARKETPLACE_URL) { $env:SONIQ_MARKETPLACE_URL } else { 'https://raw.githubusercontent.com/spicetify/spicetify-marketplace/main/resources/install.ps1' }
  try {
    $Parameters = @{
      Uri             = $marketplaceUrl
      UseBasicParsing = $true
    }
    Invoke-WebRequest @Parameters | Invoke-Expression
  }
  catch {
    Write-Warning -Message 'Marketplace installation failed; SONIQ itself is installed.'
  }
}
#endregion Marketplace
#endregion Main
=======
$ErrorActionPreference = 'Stop'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

#region Variables
$soniqFolderPath = "$env:LOCALAPPDATA\soniq"
# Legacy locations from the upstream tool, migrated non-destructively on install.
$soniqLegacyFolderPath = "$env:LOCALAPPDATA\spicetify"
$soniqOldFolderPath = "$HOME\spicetify-cli"
# Override with $env:SONIQ_REPO_URL to install from a custom location.
$soniqRepoUrl = if ($env:SONIQ_REPO_URL) { $env:SONIQ_REPO_URL } else { 'https://github.com/Bazw39/soniq' }
$soniqApiUrl = $soniqRepoUrl -replace 'github\.com', 'api.github.com/repos'
#endregion Variables

#region Functions
function Write-Success {
  [CmdletBinding()]
  param ()
  process {
    Write-Host -Object ' > OK' -ForegroundColor 'Green'
  }
}

function Write-Unsuccess {
  [CmdletBinding()]
  param ()
  process {
    Write-Host -Object ' > ERROR' -ForegroundColor 'Red'
  }
}

function Test-Admin {
  [CmdletBinding()]
  param ()
  begin {
    Write-Host -Object "Checking if the script is not being run as administrator..." -NoNewline
  }
  process {
    $currentUser = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
    -not $currentUser.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
  }
}

function Test-PowerShellVersion {
  [CmdletBinding()]
  param ()
  begin {
    $PSMinVersion = [version]'5.1'
  }
  process {
    Write-Host -Object 'Checking if your PowerShell version is compatible...' -NoNewline
    $PSVersionTable.PSVersion -ge $PSMinVersion
  }
}

function Move-OldSONIQFolder {
  [CmdletBinding()]
  param ()
  process {
    # Migrate the historic per-user folder without deleting the source data.
    if ((Test-Path -Path $soniqOldFolderPath) -and (-not (Test-Path -Path $soniqFolderPath))) {
      Write-Host -Object 'Migrating the legacy per-user folder...' -NoNewline
      Copy-Item -Path "$soniqOldFolderPath\*" -Destination $soniqFolderPath -Recurse -Force
      Write-Success
    }
    # Migrate the legacy upstream config folder without deleting the source data.
    if ((Test-Path -Path $soniqLegacyFolderPath) -and (-not (Test-Path -Path $soniqFolderPath))) {
      Write-Host -Object 'Migrating the legacy upstream folder...' -NoNewline
      Copy-Item -Path "$soniqLegacyFolderPath\*" -Destination $soniqFolderPath -Recurse -Force
      Write-Success
    }
  }
}

function Get-SONIQ {
  [CmdletBinding()]
  param ()
  begin {
    if ($env:PROCESSOR_ARCHITECTURE -eq 'AMD64') {
      $architecture = 'x64'
    }
    elseif ($env:PROCESSOR_ARCHITECTURE -eq 'ARM64') {
      $architecture = 'arm64'
    }
    else {
      $architecture = 'x32'
    }
    if ($v) {
      if ($v -match '^\d+\.\d+\.\d+$') {
        $targetVersion = $v
      }
      else {
        Write-Warning -Message "You have specified an invalid SONIQ version: $v `nThe version must be in the following format: 1.2.3"
        Pause
        exit
      }
    }
    else {
      Write-Host -Object 'Fetching the latest SONIQ version...' -NoNewline
      $latestRelease = Invoke-RestMethod -Uri "$soniqApiUrl/releases/latest"
      $targetVersion = $latestRelease.tag_name -replace 'v', ''
      Write-Success
    }
    $archivePath = [System.IO.Path]::Combine([System.IO.Path]::GetTempPath(), "soniq.zip")
  }
  process {
    Write-Host -Object "Downloading SONIQ v$targetVersion..." -NoNewline
    $Parameters = @{
      Uri            = "$soniqRepoUrl/releases/download/v$targetVersion/soniq-$targetVersion-windows-$architecture.zip"
      UseBasicParsin = $true
      OutFile        = $archivePath
    }
    Invoke-WebRequest @Parameters
    Write-Success
  }
  end {
    $archivePath
  }
}

function Add-SONIQToPath {
  [CmdletBinding()]
  param ()
  begin {
    Write-Host -Object 'Making SONIQ available in the PATH...' -NoNewline
    $user = [EnvironmentVariableTarget]::User
    $path = [Environment]::GetEnvironmentVariable('PATH', $user)
  }
  process {
    $path = $path -replace "$([regex]::Escape($soniqOldFolderPath))\\*;*", ''
    if ($path -notlike "*$soniqFolderPath*") {
      $path = "$path;$soniqFolderPath"
    }
  }
  end {
    [Environment]::SetEnvironmentVariable('PATH', $path, $user)
    if (($env:PATH -split ';') -notcontains $soniqFolderPath) {
      $env:PATH = "$env:PATH;$soniqFolderPath"
    }
    Write-Success
  }
}

function Install-SONIQ {
  [CmdletBinding()]
  param ()
  begin {
    Write-Host -Object 'Installing SONIQ...'
  }
  process {
    $archivePath = Get-SONIQ
    Write-Host -Object 'Extracting SONIQ...' -NoNewline
    Expand-Archive -Path $archivePath -DestinationPath $soniqFolderPath -Force
    Write-Success
    Add-SONIQToPath
  }
  end {
    Remove-Item -Path $archivePath -Force -ErrorAction 'SilentlyContinue'
    Write-Host -Object 'SONIQ was successfully installed!' -ForegroundColor 'Green'
  }
}
#endregion Functions

#region Main
#region Checks
if (-not (Test-PowerShellVersion)) {
  Write-Unsuccess
  Write-Warning -Message 'PowerShell 5.1 or higher is required to run this script'
  Write-Warning -Message "You are running PowerShell $($PSVersionTable.PSVersion)"
  Write-Host -Object 'PowerShell 5.1 install guide:'
  Write-Host -Object 'https://learn.microsoft.com/skypeforbusiness/set-up-your-computer-for-windows-powershell/download-and-install-windows-powershell-5-1'
  Write-Host -Object 'PowerShell 7 install guide:'
  Write-Host -Object 'https://learn.microsoft.com/powershell/scripting/install/installing-powershell-on-windows'
  Pause
  exit
}
else {
  Write-Success
}
if (-not (Test-Admin)) {
  Write-Unsuccess
  Write-Warning -Message "The script was run as administrator. This can result in problems with the installation process or unexpected behavior. Do not continue if you do not know what you are doing."
  $Host.UI.RawUI.Flushinputbuffer()
  $choices = [System.Management.Automation.Host.ChoiceDescription[]] @(
    (New-Object System.Management.Automation.Host.ChoiceDescription '&Yes', 'Abort installation.'),
    (New-Object System.Management.Automation.Host.ChoiceDescription '&No', 'Resume installation.')
  )
  $choice = $Host.UI.PromptForChoice('', 'Do you want to abort the installation process?', $choices, 0)
  if ($choice -eq 0) {
    Write-Host -Object 'SONIQ installation aborted' -ForegroundColor 'Yellow'
    Pause
    exit
  }
}
else {
  Write-Success
}
#endregion Checks

#region SONIQ
$installedSONIQ = Join-Path -Path $soniqFolderPath -ChildPath 'soniq.exe'
if (-not (Test-Path -LiteralPath $installedSONIQ -PathType Leaf)) {
  $installedCommand = Get-Command -Name 'soniq' -CommandType Application -ErrorAction SilentlyContinue | Select-Object -First 1
  if ($installedCommand) {
    $installedSONIQ = $installedCommand.Source
  }
  else {
    $installedSONIQ = $null
  }
}

if ($installedSONIQ) {
  $Host.UI.RawUI.Flushinputbuffer()
  $choices = [System.Management.Automation.Host.ChoiceDescription[]] @(
    (New-Object System.Management.Automation.Host.ChoiceDescription '&Yes', 'Run soniq update.'),
    (New-Object System.Management.Automation.Host.ChoiceDescription '&No', 'Continue with installation.')
  )
  $choice = $Host.UI.PromptForChoice('', 'SONIQ is already installed. Do you want to repair your installation?', $choices, 0)
  if ($choice -eq 0) {
    & $installedSONIQ update
    if ($LASTEXITCODE -ne 0) {
      throw "SONIQ update failed with exit code $LASTEXITCODE."
    }
    return
  }
}

Move-OldSONIQFolder
Install-SONIQ
Write-Host -Object "`nRun" -NoNewline
Write-Host -Object ' soniq -h ' -NoNewline -ForegroundColor 'Cyan'
Write-Host -Object 'to get started'
#endregion SONIQ

#region Marketplace
$Host.UI.RawUI.Flushinputbuffer()
$choices = [System.Management.Automation.Host.ChoiceDescription[]] @(
    (New-Object System.Management.Automation.Host.ChoiceDescription "&Yes", "Install SONIQ Marketplace."),
    (New-Object System.Management.Automation.Host.ChoiceDescription "&No", "Do not install SONIQ Marketplace.")
)
$choice = $Host.UI.PromptForChoice('', "`nDo you also want to install SONIQ Marketplace? It will become available within the Spotify client, where you can easily install themes and extensions.", $choices, 0)
if ($choice -eq 1) {
  Write-Host -Object 'SONIQ Marketplace installation aborted' -ForegroundColor 'Yellow'
}
else {
  Write-Host -Object 'Starting the SONIQ Marketplace installation script..'
  # Third-party community Marketplace resource. Override with $env:SONIQ_MARKETPLACE_URL.
  $marketplaceUrl = if ($env:SONIQ_MARKETPLACE_URL) { $env:SONIQ_MARKETPLACE_URL } else { 'https://raw.githubusercontent.com/spicetify/spicetify-marketplace/main/resources/install.ps1' }
  try {
    $Parameters = @{
      Uri             = $marketplaceUrl
      UseBasicParsing = $true
    }
    Invoke-WebRequest @Parameters | Invoke-Expression
  }
  catch {
    Write-Warning -Message 'Marketplace installation failed; SONIQ itself is installed.'
  }
}
#endregion Marketplace
#endregion Main
>>>>>>> adc39be (SONIQ release v2.42.0)
