function Invoke-BigIpRestRequest {
    [CmdletBinding()]
    param (
        $path,
        $method = $null,
        $payload = $null,
        $session = $null,
        $transaction = $null
    )

    if(!$session) {
        Write-Verbose "Using script session"
        $session = $Script:Session
    } else {
        Write-Verbose "Using session supplied in call"
    }

    $uri = $session.root + $path

    # Clone headers so we don't mess up the session headers with transaction id.
    $headers = @{}
    $session.webSession.Headers.GetEnumerator() | ForEach-Object {
        Write-Debug "Adding header $($_.Key):$($_.Value)"
        $headers["$($_.Key)"] = $_.Value
    }
    
    if(!$method) {
        if($payload) {
            Write-Verbose "No method specified and payload found, default to POST"
            $method = "POST"
        } else {
            Write-Verbose "No method specified and no payload found, default to GET"
            $method = "GET"
        }
    }

    if($transaction) {
        Write-Verbose "Including this request in an F5 transaction"
        if(!$headers["X-F5-REST-Coordination-Id"]) {
            $headers.Add("X-F5-REST-Coordination-Id", "")
        }
        $headers["X-F5-REST-Coordination-Id"] = $transaction.transId
    }

    try {
        if($payload) {
            $body = $payload | ConvertTo-Json
            Invoke-RestMethod $uri -Method $method -Body $body -ContentType 'application/json' -Headers $headers -WebSession $session.webSession | Write-Output
        } else {
            Invoke-RestMethod $uri -Method $method -ContentType 'application/json' -Headers $headers -WebSession $session.webSession | Write-Output
        }
    } catch {
        if($_.ErrorDetails) {
            try {
                $details = $_.ErrorDetails | ConvertFrom-Json -ErrorAction SilentlyContinue
                if($details.code -and $details.code -eq 404 -and $method -eq "GET") {
                    # Whatever was asked for doesn't exist as far as the F5 knows.
                    return;
                }
            } catch {
                # No-op. The JSON wasn't valid so throw as usual
            }
        }

        throw $_;
    }
}
