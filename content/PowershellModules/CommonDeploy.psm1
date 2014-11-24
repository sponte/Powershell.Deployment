# Common deployment module

$global:ErrorActionPreference = "Stop"

$CurrentPath = Split-Path -parent $MyInvocation.MyCommand.Definition

Import-Module $CurrentPath\Utils.psd1 -Force -DisableNameChecking
Import-Module $CurrentPath\Installation.psd1 -Force -DisableNameChecking
Import-Module $CurrentPath\CertificateInstallation.psd1 -Force -DisableNameChecking
Import-Module $CurrentPath\FilePermissionInstallation.psd1 -Force -DisableNameChecking
Import-Module $CurrentPath\ServiceInstallation.psd1 -Force -DisableNameChecking

$m = Get-Module WebAdministration -ListAvailable
if($m) {
    Import-Module WebAdministration
    Import-Module $CurrentPath\WebInstallation.psd1 -Force -DisableNameChecking
} else {
    Write-Warning "WebAdministration module is not installed. It is not required for all installations but if you're trying to configure a website your installation will fail"
}

if(Test-Path "$CurrentPath\Tools\Microsoft.ServiceBus.dll") {
    Import-Module $CurrentPath\Tools\Microsoft.ServiceBus.dll -Force -DisableNameChecking
    Import-Module $CurrentPath\ServiceBusInstallation.psd1 -Force -DisableNameChecking
} else {
    Write-Warning "ServiceBus module is not installed. It is not required for all installations but if you're trying to configure windows service bus your installation will fail"
}

if(Test-Path "$CurrentPath\Tools\PrtgSetupTool.exe") {
    Import-Module $CurrentPath\PrtgMonitoringInstallation.psd1 -Force -DisableNameChecking
} else {
    Write-Warning "Prtg Monitoring is not installed. It is not required for all installations but if you're trying to configure prtg monitor your installation will fail"
}