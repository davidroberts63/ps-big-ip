Import-Module (Resolve-Path $PSScriptRoot\..\big-ip\big-ip.psd1) -Force

Describe "New-BigIpSession" {
    $resultingSession = $null

    BeforeEach {
        Mock -ModuleName Big-Ip Invoke-RestMethod -MockWith { 
            $theDate = Get-Date
            @{ 
                token = @{ 
                    token = "1"; 
                    startTime = "$($theDate.ToShortDateString()) $($theDate.ToLongTimeString())"
                }
            } | Write-Output 
        }
        
        $password = "world" | ConvertTo-SecureString -AsPlainText -Force
        $resultingSession = New-BigIpSession -root "" -credential (new-object PSCredential("hello", $password))
    }

    It "Uses the correct api path" {
        Assert-MockCalled -ModuleName Big-Ip Invoke-RestMethod 1 -ParameterFilter {
            $uri -like "*/mgmt/shared/authn/login"
        }
    }

    It "Uses the correct method" {
        Assert-MockCalled -ModuleName Big-Ip Invoke-RestMethod 1 -ParameterFilter {
            $method -eq "POST"
        }
    }

    It "Provides the proper credentials payload" {
        Assert-MockCalled -ModuleName Big-Ip Invoke-RestMethod 1 -ParameterFilter {
            $payload = $body | ConvertFrom-Json
            
            ($payload.username -eq "hello") `
            -and `
            ($payload.password -eq "world") `
            -and `
            ($payload.loginProviderName -eq "tmos")
        }
    }

    It "Adds the token to the session headers" {
        $resultingSession.webSession.Headers["X-F5-Auth-Token"] | Should Be "1"
    }

    It "Adds the token expiration to the session headers" {
        $resultingSession.webSession.Headers["Token-Expiration"] | Should BeGreaterThan (Get-Date)
    }
}