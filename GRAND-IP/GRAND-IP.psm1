Set-StrictMode -Version 2.0
$Script:Session = $null

Get-ChildItem $PSScriptRoot\functions | ForEach-Object {
    . $_.fullname
}