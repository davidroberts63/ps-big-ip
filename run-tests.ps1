Import-Module .\big-ip\Big-Ip.psd1
Import-Module Pester

Invoke-Pester -Path .\tests -CodeCoverage .\big-ip\functions\*