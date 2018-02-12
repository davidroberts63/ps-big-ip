Import-Module $PSScriptRoot\big-ip\Big-Ip.psd1
Import-Module Pester -ErrorAction SilentlyContinue
$pester = Get-Module Pester
if(-not $pester) {
    Write-Warning "Could not find the Pester Powershell module. 'Install-Module Pester -Force -SkipPublisherCheck' first."
} elseif($pester.Version.Major -lt 4) {
    Write-Warning "Pester 4.0 and greater is required. 'Install-Module Pester -Force -SkipPublisherCheck' first."
    exit 1
}

Invoke-Pester -Path $PSScriptRoot\tests `
    -OutputFile $PSScriptRoot\tests-results.xml -OutputFormat NUnitXML `
    -CodeCoverage $PSScriptRoot\big-ip\functions\* `
    -CodeCoverageOutputFile $PSScriptRoot\coverage-results.xml -CodeCoverageOutputFileFormat JaCoCo

if($ENV:APPVEYOR_JOB_ID) {
    Write-Host "Uploading tests results to AppVeyor"
    $wc = New-Object 'System.Net.WebClient'
    $wc.UploadFile("https://ci.appveyor.com/api/testresults/nunit3/$($ENV:APPVEYOR_JOB_ID)", (Resolve-Path $PSScriptRoot\tests-results.xml))
}