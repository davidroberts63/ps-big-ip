# BIG-IP Powershell Module
[![Build status](https://ci.appveyor.com/api/projects/status/56ujpqrniiil5q43?svg=true)](https://ci.appveyor.com/project/davidroberts63/ps-big-ip)
[![codecov](https://codecov.io/gh/davidroberts63/ps-big-ip/branch/master/graph/badge.svg)](https://codecov.io/gh/davidroberts63/ps-big-ip)

A Powershell module for the F5 BIG-IP REST API interface. It works with version 12+.

The goal is to provide easy access to any BIG-IP REST API via the core `Invoke-BigIpRestRequest` function. As well as offer wrappers around the core function to give you familiar access to higher level BIG-IP functionality such as virtual servers, pools, etc.

## Installing

```
Install-Module Big-Ip
Import-Module Big-Ip
```

## Logging in

```
$yourCredential = Get-Credential
New-BigIpSession -root "https://url-to-your-big-ip" -credential $yourCredential
```

The session is stored within the script module and is used automatically. `New-BigIpSession` outputs the session object and you can keep it in a variable for use later. This would be useful if you plan on querying multiple BIG-IPs within the same script.

## Querying virtual servers example

```
# Must already be logged in via `New-BigIpSession`
$result = Invoke-BigIpRestRequest -path "/mgmt/tm/ltm/virtual"
$result.items
```

The above outputs the virtual servers currently available on your BIG-IP:

```
kind                         : tm:ltm:virtual:virtualstate
name                         : foo-bar.mycorp.com_https
partition                    : Common
fullPath                     : /Common/foo-bar.mycorp.com_https
...
```

## Creating a pool example

```
$payload = @{
    name = $poolName;
    partition = $partition;
    loadBalancingMode = "least-connections-member"
}
$pool = Invoke-BigIpRestRequest -path "/mgmt/tm/ltm/pool" -method POST -payload $payload
```

The `method` parameter of `Invoke-BigIpRestRequest` accepts the same values as `Invoke-RestMethod`. If you do not specify the `method` parameter POST is used as a default if the `payload` is specified. If you do not provide a payload then GET is the default method.

## Invoke-BigpRestRequest

This is the core function that provides familiar access to the BIG-IP REST api. With very few exceptions (`New-BigIpSession` for one) all wrapper functions will use this core function to communicate with the Big-Ip. If you cannot find needed functionality in the wrapper functions (or it simply doesn't exist yet) you can use `Invoke-BigIpRestRequest`. You will need to be familiar with the [BIG-IP iControl REST API](https://devcentral.f5.com/wiki/iControlREST.HomePage.ashx) to do so.

Parameters
* path[required] 
    - The path to the BIG-IP resource being queried or updated.
* method
    - The REST method to be used.
* payload
    - The powershell object to send in the body of the request. This gets converted to JSON.
* session
    - The logged in session with the F5 BIG-IP. You only need to specify this if you are using a different session from the last time you called `New-BigIpSession`
* transaction
    - The transaction this request is to be a part of in the BIG-IP.

## Using transactions

```
$transaction = New-BigIpTransaction
Invoke-BigIpRestRequest -path "/some-path' -payload $somePayload -transaction $transaction
...
Complete-BigIpTransaction -transaction $transaction
```

You may want to review the F5 BIG-IP documentation on [transactions](https://devcentral.f5.com/articles/demystifying-icontrol-rest-part-7-understanding-transactions-21404). When specifying the `transaction` parameter on `Invoke-BigIpRestRequest` or any future wrapper functions, the F5 transaction coordination header will be added accordingly.

## Contributing

If you would like to contribute changes, thank you. You're help is greatly appreciated. Please keep the following in mind.

* Bugs or ideas create an issue, label it as a bug or enhancement.
* Run the `run-tests.ps1` script to verify functionality. All contributions must provide tests, you don't have to get 100% coverage but make sure the main features are verified in the tests.
    - Using [pester](https://github.com/pester/Pester)
* If this is your first time contributing, wonderful. Please know I have a full time job and personal life, but I enjoy helping new people. Whether you've been coding for 10 years or one, I'll help guide and review your contribution.
