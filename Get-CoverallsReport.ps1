function Get-CoverallsReport() {
    [CmdletBinding()]
    param(
        $coverageData
    )

    $report = New-Object PSCustomObject -Property @{
        repo_token = "TnhlDxlxyaZshKwWaE9KpvcA8oRqpd8CH";
        service_name = "local";
        source_files = @()
    }

    $allCommands = $coverageData.HitCommands + $coverageData.MissedCommands
    $allCommands | Group-Object File | %{
        $file = $_.Name
        $lineCount = (Get-Content $file).Length # This includes blank lines, Measure-Object skips those, causing problems.

        $coverageFile = New-Object PSCustomObject -Property @{
            name = (Resolve-Path $file -Relative).Replace(".\","").Replace("\","/");
            source_digest = (Get-FileHash -Path $file -Algorithm MD5).Hash;
            source = "hello";
            coverage = @(@(0..($lineCount-1)) | ForEach-Object { "null" })
        }
        
        $_.Group | Group-Object Line | %{
            $lineNumber = $_.Name - 1
            try {
                $coverageFile.coverage[$lineNumber] = $_.Count
            } catch {
                Write-Warning "$file ~ $lineNumber"
            }
        }

        $report.source_files += $coverageFile
    }

    $report | Write-Output
}