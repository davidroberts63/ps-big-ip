Import-Module $PSScriptRoot\big-ip\Big-Ip.psd1
Import-Module Pester -ErrorAction SilentlyContinue
$pester = Get-Module Pester
if(-not $pester) {
    Write-Warning "Could not find the Pester Powershell module. 'Install-Module Pester -Force -SkipPublisherCheck' first."
} elseif($pester.Version.Major -lt 4) {
    Write-Warning "Pester 4.0 and greater is required. 'Install-Module Pester -Force -SkipPublisherCheck' first."
    exit 1
}

$results = Invoke-Pester -PassThru -Path $PSScriptRoot\tests `
    -OutputFile $PSScriptRoot\tests-results.xml -OutputFormat NUnitXML `
    -CodeCoverage $PSScriptRoot\big-ip\functions\* `
    -CodeCoverageOutputFile $PSScriptRoot\coverage-results.xml -CodeCoverageOutputFileFormat JaCoCo

Write-Host "Generating Coveralls report"
. .\Get-CoverallsReport.ps1
$report = Get-CoverallsReport $results.CodeCoverage $ENV:COVERALLS_TOKEN

Write-Host "Uploading Coveralls report"
Add-Type -AssemblyName System.Net.Http | Out-Null
$formData = New-Object System.Net.Http.MultipartFormDataContent
$content = New-Object System.Net.Http.StringContent(($report | ConvertTo-Json -Depth 10), [System.Text.Encoding]::UTF8, "application/json")
$formData.Add($content, "json_file", "coverage.json") | Out-Null
$headers = @{ "Content-Type" = ($formData.Headers | Select Key,Value | Where Key -eq "Content-Type" | Select -ExpandProperty Value) }

Invoke-RestMethod -Uri "https://coveralls.io/api/v1/jobs" -Method Post -Headers $headers -Body ($formData.ReadAsStringAsync().Result)

if($ENV:APPVEYOR_JOB_ID) {
    Write-Host "Uploading tests results to AppVeyor"
    $wc = New-Object 'System.Net.WebClient'
    $wc.UploadFile("https://ci.appveyor.com/api/testresults/nunit3/$($ENV:APPVEYOR_JOB_ID)", (Resolve-Path $PSScriptRoot\tests-results.xml)) | Out-Null
}
