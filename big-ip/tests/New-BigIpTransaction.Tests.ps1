# Importing the function under test

. $PSScriptRoot\..\functions\Invoke-BigIpRestRequest.ps1
. $PSScriptRoot\..\functions\New-BigIpSession.ps1
. $PSScriptRoot\..\functions\New-BigIpTransaction.ps1

Describe 'New-BigIpTransaction' {

    BeforeEach {
        Mock -CommandName Invoke-RestMethod -MockWith { 
            @{ 
                token = @{ 
                    token = "1"; 
                    startTime = (Get-Date).ToShortDateString() 
                }
            } | Write-Output 
        }
        
        $password = "world" | ConvertTo-SecureString -AsPlainText -Force
        New-BigIpSession -root "" -credential (new-object PSCredential("hello", $password))

        Mock -CommandName Invoke-RestMethod -MockWith { 
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

        Assert-MockCalled Invoke-RestMethod 1 -ParameterFilter { $Uri -like "https://helloworld*" }
    }

    It "Uses the correct api path" {
        New-BigIpTransaction
        Assert-MockCalled Invoke-RestMethod 1 -ParameterFilter { $Uri -like "*/mgmt/tm/transaction" }
    }
}
