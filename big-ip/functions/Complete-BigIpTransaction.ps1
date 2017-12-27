function Complete-BigIpTransaction {
    [CmdletBinding()]
    param (
        $transaction,
        $session = $null
    )

    $payload = @{
        state = "VALIDATING"
    }

    if(!$session) {
        Write-Verbose "Removing F5 transaction header"
        $Script:Session.webSession.Headers.Remove("X-F5-REST-Coordination-Id")
    }

    Invoke-BigIpRestRequest -path "/mgmt/tm/transaction/$($transaction.transId)" -method PATCH -session $session -payload $payload | Write-Output
}
