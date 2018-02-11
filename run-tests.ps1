Import-Module $PSScriptRoot\big-ip\Big-Ip.psd1
Import-Module Pester -ErrorAction SilentlyContinue
$pester = Get-Module Pester
if(-not $pester) {
    Write-Warning "Could not find the Pester Powershell module. 'Install-Module Pester' first."
} elseif($pester.Version.Major -lt 4) {
    Write-Warning "Pester 4.0 and greater is required. 'Update-Module Pester' first."
    exit 1
}

Invoke-Pester -Path $PSScriptRoot\tests `
    -OutputFile .\tests.xml -OutputFormat NUnitXML `
    -CodeCoverage $PSScriptRoot\big-ip\functions\* `
    -CodeCoverageOutputFile .\coverage.xml -CodeCoverageOutputFileFormat JaCoCo