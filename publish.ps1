param(
    [switch]
    $Locally,
    [switch]
    $PowerShellGallery
)

$ErrorActionPreference = "STOP"

Import-Module PowerShellGet -ErrorAction SilentlyContinue
$powershellGet = Get-Module PowerShellGet
if(-not $powershellGet) {
    Write-Warning "Could not find the PowerShellGet module. 'Install-Module PowerShellGet' first."
} elseif($powershellGet.Version -lt "1.6.0") {
    Write-Warning "PowerShellGet 1.6.0 and greater is required. 'Install-Module PowerShellGet -Force' first."
    exit 1
}

if(-not $Locally -and -not $PowerShellGallery) {
    Write-Warning "You must specify either -Locally or -PowerShellGallery"
    exit 1
}

if($Locally) {
    Write-Host "Publishing locally"
    $name = "LocalBigIp"
    $path = "$PSScriptRoot\localgallery"

    if((Test-Path $path)) {
        Remove-Item $path -Recurse -Force | Out-Null
    }
    New-Item -Type Directory $path -Force | Out-Null
    Register-PSRepository -Name $name -SourceLocation $path -PublishLocation $path -InstallationPolicy Trusted

    # Note, the case in the folder name specified here affects how it's put into the repository.
    # So leave it as is. Why? I don't know but it's really annoying.
    Publish-Module -Path $PSScriptRoot\Big-Ip -Repository $name

    Unregister-PSRepository -Name $name

    Write-Host "Published locally to $path"
}

if ($PowerShellGallery) {
    Write-Host "Publishing to the PowerShell Gallery"
}