Import-Module (Resolve-Path $PSScriptRoot\..\big-ip\big-ip.psd1) -Force

Describe 'Complete-BigIpTransaction' {

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
        
        Mock -ModuleName Big-Ip Invoke-BigIpRestRequest -MockWith { }
        New-BigIpTransaction
        Complete-BigIpTransaction -transaction @{ transId = "123456789" }
    }

    It "Uses the correct payload" {
        Assert-MockCalled -ModuleName Big-Ip Invoke-BigIpRestRequest 1 -ParameterFilter { 
            $payload.state -eq "VALIDATING"
        }
    }

    It "Uses the correct api path" {
        Assert-MockCalled -ModuleName Big-Ip Invoke-BigIpRestRequest 1 -ParameterFilter { 
            $path -eq "/mgmt/tm/transaction/123456789"
        }
    }

    It "Removes any f5 transaction coordination id header" {
        InModuleScope -ModuleName Big-Ip {
            Assert-MockCalled Invoke-BigIpRestRequest 1 -ParameterFilter { 
                $Script:session.webSession.Headers.ContainsKey("X-F5-REST-Coordination-Id") -eq $false
            }    
        }
    }
}
