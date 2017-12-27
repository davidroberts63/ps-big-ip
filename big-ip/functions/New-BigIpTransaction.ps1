function New-BigIpTransaction {
    [CmdletBinding()]
    param (
        $session = $null
    )

    Invoke-BigIpRestRequest -path "/mgmt/tm/transaction" -payload @{} -session $session | Write-Output
}
