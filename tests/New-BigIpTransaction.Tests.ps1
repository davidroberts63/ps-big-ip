Import-Module (Resolve-Path $PSScriptRoot\..\big-ip\big-ip.psd1) -Force

Describe 'New-BigIpTransaction' {

    BeforeEach {
        Mock -ModuleName Big-Ip Invoke-RestMethod -MockWith { 
            @{ 
                token = @{ 
                    token = "1"; 
                    startTime = (Get-Date).ToShortDateString() 
                }
            } | Write-Output 
        }
        
        $password = "world" | ConvertTo-SecureString -AsPlainText -Force
        New-BigIpSession -root "" -credential (new-object PSCredential("hello", $password)) | FL *
        
        Mock -ModuleName Big-Ip Invoke-RestMethod -MockWith { 
            @{ transId = "1" } | Write-Output 
        }
    }

    It "Given no parameters, returns the created transaction object" {
        $transaction = New-BigIpTransaction

        $transaction.transId | Should -Not -BeNullOrEmpty
    }

    It "Uses the given session" {
        New-BigIpTransaction -session @{
            root = "https://helloworld"
            webSession = New-Object Microsoft.PowerShell.Commands.WebRequestSession
        }

        Assert-MockCalled -ModuleName Big-Ip Invoke-RestMethod 1 -ParameterFilter { $Uri -like "https://helloworld*" }
    }

    It "Uses the correct api path" {
        New-BigIpTransaction
        Assert-MockCalled -ModuleName Big-Ip Invoke-RestMethod 1 -ParameterFilter { $Uri -like "*/mgmt/tm/transaction" }
    }
}
