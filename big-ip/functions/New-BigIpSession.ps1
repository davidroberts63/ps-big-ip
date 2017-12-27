function New-BigIpSession {
    [CmdletBinding()]
    param (
        $root,
        $credential
    )

    $body = @{ 
        username = $credential.Username;
        password = $credential.GetNetworkCredential().Password;
        loginProviderName = "tmos" 
    } | ConvertTo-Json
    
    $result = Invoke-RestMethod "$root/mgmt/shared/authn/login" -Method POST -Body $body -ContentType 'application/json' -Credential $credential | Write-Output

    $Script:Session = New-Object -TypeName PsCustomobject -Property @{
        root = $root
        webSession = New-Object Microsoft.PowerShell.Commands.WebRequestSession
    }

    # Authentication token
    $token = $result.token.token
    $Script:Session.webSession.Headers.Add("X-F5-Auth-Token", $token)

    # Token expiration
    $tokenLifeSpan = 1200
    $ts = New-TimeSpan -Minutes ($tokenLifespan/60)
    $date = Get-Date -Date $result.token.startTime 
    $expirationTime = $date + $ts
    $Script:Session.webSession.Headers.Add('Token-Expiration', $expirationTime)

    $Script:Session | Write-Output
}
