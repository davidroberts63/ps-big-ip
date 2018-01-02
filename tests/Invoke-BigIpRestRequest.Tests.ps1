Import-Module (Resolve-Path $PSScriptRoot\..\big-ip\big-ip.psd1) -Force

Describe 'Invoke-BigIpRestRequest' {
    BeforeEach {
        Mock -ModuleName Big-Ip Invoke-RestMethod -MockWith { }
        
        InModuleScope -ModuleName Big-Ip {
            $Script:session = @{
                root = "not-used"
                webSession = New-Object Microsoft.PowerShell.Commands.WebRequestSession
            }
        }    
    }

    It "Does not throw when receiving a 404 from big-ip GET request" {
        InModuleScope -ModuleName Big-Ip {
            Mock Invoke-Restmethod -MockWith {
                $er = New-Object Management.Automation.ErrorRecord(
                    (New-Object System.ApplicationException),
                    "",
                    "NotSpecified",
                    $null
                )
                $er.ErrorDetails = (@{code = 404} | ConvertTo-Json)
                throw $er
            }
        }

        { Invoke-BigIpRestRequest "/hello" } | Should Not Throw
    }

    It "Does throw when receiving a non json error response from big-ip" {
        InModuleScope -ModuleName Big-Ip {
            Mock Invoke-Restmethod -MockWith {
                $er = New-Object Management.Automation.ErrorRecord(
                    (New-Object System.ApplicationException), # Produces 'Error in the application.' error message.
                    "",
                    "NotSpecified",
                    $null
                )
                $er.ErrorDetails = "Not JSON"
                throw $er
            }
        }

        { Invoke-BigIpRestRequest "/hello" } | Should Throw "Error in the application."
    }

    Context "When not given a payload" {
        BeforeEach { 
            Invoke-BigIpRestRequest -path "/" 
        }
        InModuleScope Big-Ip {
            It "Does not send a body with no payload" {
                Assert-MockCalled Invoke-RestMethod -ParameterFilter {
                    $body -eq $null
                }
            }
        
            It "Append the path to the root uri" {
                Assert-MockCalled Invoke-RestMethod -ParameterFilter {
                    $uri -eq "not-used/"
                }  
            }
            
            It "Uses the GET verb by default" {
                Assert-MockCalled Invoke-RestMethod -ParameterFilter {
                    $method -eq "GET"
                }  
            }
            
        }
    }
    
    Context "When given a payload" {
        BeforeEach {
            Invoke-BigIpRestRequest -payload @{ planet = "jupiter" } -path ""
        }

        InModuleScope Big-Ip {
            It "Sends it as json in the body" {
                Assert-MockCalled Invoke-RestMethod 1 -ParameterFilter {
                    $body -eq (@{ planet = "jupiter" } | ConvertTo-Json)
                }
            }
    
            It "Uses the POST verb by default" {    
                Assert-MockCalled Invoke-RestMethod 1 -ParameterFilter {
                    $method -eq "POST"
                }
            }
        }
    }

    Context "When included in a transaction" {
        BeforeEach {
            Invoke-BigIpRestRequest -payload @{ planet = "jupiter" } -path "" -transaction @{ transId = "123456789" }
        }

        InModuleScope Big-Ip {
            It "Adds the f5 transaction header" {
                Assert-MockCalled Invoke-RestMethod 1 -ParameterFilter {
                    $headers.ContainsKey("X-F5-REST-Coordination-Id") -eq $true `
                    -and `
                    $headers["X-F5-REST-Coordination-Id"] -eq "123456789"
                }
            }
        }
    }
}