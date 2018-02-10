param(
    [switch]
    $Locally,
    [switch]
    $PowerShellGallery
)

$ErrorActionPreference = "STOP"

if(-not $Locally -and -not $PowerShellGallery) {
    Write-Warning "You must specify either -Locally or -PowerShellGallery"
    exit 1
}

if($Locally) {
    Write-Host "Publishing locally"
    $name = "LocalBigIp"
    $path = "$PSScriptRoot\localgallery"

    Remove-Item $path -Recurse -Force | Out-Null
    New-Item -Type Directory $path -Force | Out-Null
    Register-PSRepository -Name $name -SourceLocation $path -PublishLocation $path -InstallationPolicy Trusted

    Publish-Module -Path $PSScriptRoot\big-ip -Repository $name

    Unregister-PSRepository -Name $name

    Write-Host "Published locally to $path"
}

if ($PowerShellGallery) {
    Write-Host "Publishing to the PowerShell Gallery"
}