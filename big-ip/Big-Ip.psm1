$Script:Session = $null

Get-ChildItem .\functions | ForEach-Object {
    . $_.fullname
}