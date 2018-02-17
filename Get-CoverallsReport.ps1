function Get-CoverallsReport() {
    [CmdletBinding()]
    param(
        $coverageData,
        $coverallsToken
    )

    $git = Get-Command git -ErrorAction SilentlyContinue
    $gitData = $null
    if($git -and (& $git status)) {
        $commitData = & $git show -s --format=%H%n%an%n%ae%n%cn%n%ce%n%s HEAD
        $remoteNames = & $git remote

        $gitData = @{
            head = @{
                id = $commitData[0];
                author_name = $commitData[1];
                author_email = $commitData[2];
                committer_name = $commitData[3];
                committer_email = $commitData[4];
                message = $commitData[5];
            };
            branch = & $git rev-parse --abbrev-ref HEAD;
            remotes = @($remoteNames | ForEach-Object {
                @{
                    name = $_;
                    url = & $git remote get-url $_;
                }
            })
        }
    }

    $report = New-Object PSCustomObject -Property @{
        repo_token = $coverallsToken;
        service_name = "local";
        source_files = @();
        service_pull_request = $ENV:APPVEYOR_PULL_REQUEST_NUMBER;
        git = $gitData
    }

    $coverageData.HitCommands | Group-Object File | %{
        $file = $_.Name
        $lineCount = (Get-Content $file).Length # This includes blank lines, Measure-Object skips those, causing problems.

        $coverageFile = New-Object PSCustomObject -Property @{
            name = (Resolve-Path $file -Relative).Replace(".\","").Replace("\","/");
            source_digest = (Get-FileHash -Path $file -Algorithm MD5).Hash;
            coverage = @(@(0..($lineCount-1)) | ForEach-Object { $null })
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

    $coverageData.MissedCommands | Where-Object { $_ } | ForEach-Object {
        $name = (Resolve-Path $_.File -Relative).Replace(".\","").Replace("\","/");
        $sourceFile = $report.source_files | Where-Object name -eq $name
        if(-not $sourceFile) {
            $sourceFile = New-Object PSCustomObject -Property @{
                name = $name
                source_digest = (Get-FileHash -Path $_.File -Algorithm MD5).Hash;
                coverage = @(@(0..($lineCount-1)) | ForEach-Object { $null })
            }
            $report.source_files += $sourceFile
        }
        $sourceFile.coverage[$_.Line - 1] = 0;
    }

    $report | Write-Output
}