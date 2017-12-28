Set-StrictMode -Version 2.0
$Script:Session = $null

Get-ChildItem .\functions | ForEach-Object {
    . $_.fullname
}