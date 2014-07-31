ipmo .\PowershellModules\ServiceBusInstallation.psm1 -force
.\install.ps1

return

ipmo ServiceBus


function Install-ServiceBuses {
 param(  
        [Parameter(Mandatory = $true)]
        [string]
        $rootPath,
        [Parameter(Mandatory = $true)]
        [System.XML.XMLDocument]
        $configuration
    )

    foreach($serviceBus in @($configuration.configuration.servicebuses.ServiceBus)) {
        if(!$serviceBus) { continue }
        Install-ServiceBus -rootPath $rootPath -serviceBusConfig $serviceBus
    }
}

function Uninstall-ServiceBuses {
 param(        
        [Parameter(Mandatory = $true)]
        [string]
        $rootPath,     
        [Parameter(Mandatory = $true)]
        [System.XML.XMLDocument]
        $configuration
    )
    
    foreach($serviceBus in @($configuration.configuration.servicebuses.ServiceBus)) {
        if(!$service) { continue }
        Uninstall-ServiceBus -rootPath $rootPath -serviceBusConfig $serviceBus
    }
}

function Stop-ServiceBuses {
 param(        
        [Parameter(Mandatory = $true)]
        [string]
        $rootPath,     
        [Parameter(Mandatory = $true)]
        [System.XML.XMLDocument]
        $configuration
    )   
}

function Start-ServiceBuses {
 param(        
        [Parameter(Mandatory = $true)]
        [string]
        $rootPath,     
        [Parameter(Mandatory = $true)]
        [System.XML.XMLDocument]
        $configuration
    )
}

function Get-MetadataForServiceBuses {
 param(        
        [Parameter(Mandatory = $true)]
        [string]
        $rootPath,     
        [Parameter(Mandatory = $true)]
        [System.XML.XMLDocument]
        $configuration
    )

    foreach($serviceBus in @($configuration.configuration.servicebuses.ServiceBus)) {
        if(!$serviceBus) { continue }
        Get-MetadataForServiceBus $serviceBus
    }
}

# Methods

function Install-ServiceBus {
    param(
        [Parameter(Mandatory = $true)]
        [string]
        $rootPath,     
        [Parameter(Mandatory = $true)]
        [System.XML.XMLElement]
        $serviceBusConfig
    )

    foreach($serviceBusTopicConfig in @($serviceBusConfig.topics.topic)) {
        if(!$serviceBusTopicConfig) { continue }
        Install-ServiceBusTopic -connectionString $connectionString -serviceBusTopicConfig $serviceBusTopicConfig
    }
}

function Install-ServiceBusTopic {
    param(
        [Parameter(Mandatory = $true)]
        [string]
        $connectionString,     
        [Parameter(Mandatory = $true)]
        [System.XML.XMLElement]
        $serviceBusTopicConfig
    )

    if (!(Test-SbTopic -connectionString $connectionString -name $serviceBusTopicConfig.Name)) {
        New-SbTopic -connectionString $connectionString -name $serviceBusTopicConfig.Name
    }

    foreach($serviceBusAuthorizationConfig in @($serviceBusTopicConfig.authorizations.authorization)) {
        if(!$serviceBusAuthorizationConfig) { continue }

        Install-ServiceBusAuthorization -connectionString $connectionString -topic $serviceBusTopicConfig.Name -serviceBusAuthorizationConfig $serviceBusAuthorizationConfig
    }  

    foreach($serviceBusSubscriptionConfig in @($serviceBusTopicConfig.subscriptions.subscription)) {
        if(!$serviceBusSubscriptionConfig) { continue }

        Install-ServiceBusSubscription -connectionString $connectionString -topic $serviceBusTopicConfig.Name -serviceBusSubscriptionConfig $serviceBusSubscriptionConfig
    }
}

function Install-ServiceBusAuthorization {
    param(
        [Parameter(Mandatory = $true)]
        [string]
        $connectionString,    
        [Parameter(Mandatory = $true)]
        [string]
        $topic, 
        [Parameter(Mandatory = $true)]
        [System.XML.XMLElement]
        $serviceBusSubscriptionConfig
    )

    Write-Warning "We dont support authorization yet"
}

function Install-ServiceBusSubscription {
    param(
        [Parameter(Mandatory = $true)]
        [string]
        $connectionString,    
        [Parameter(Mandatory = $true)]
        [string]
        $topic, 
        [Parameter(Mandatory = $true)]
        [System.XML.XMLElement]
        $serviceBusSubscriptionConfig
    )

    if (!(Test-SbTopicSubscription -connectionString $connectionString -topic $topic -name $serviceBusSubscriptionConfig.Name)) {
        New-SbTopicSubscription -connectionString $connectionString -topic $topic -name $serviceBusSubscriptionConfig.Name
    }

    foreach($serviceBusSubscriptionRuleConfig in @($serviceBusTopicConfig.rules.rule)) {
        if(!$serviceBusSubscriptionRuleConfig) { continue }

        Install-ServiceBusSubscriptionRule -connectionString $connectionString -topic $topic -subscription $serviceBusSubscriptionConfig.Name -serviceBusSubscriptionRuleConfig $serviceBusSubscriptionRuleConfig
    }
}

function Install-ServiceBusSubscriptionRule {
    param(
        [Parameter(Mandatory = $true)]
        [string]
        $connectionString,    
        [Parameter(Mandatory = $true)]
        [string]
        $topic, 
        [Parameter(Mandatory = $true)]
        [string]
        $subscription,         
        [Parameter(Mandatory = $true)]
        [System.XML.XMLElement]
        $serviceBusSubscriptionRuleConfig
    )

    Write-Warning "We dont support rules yet"
}

function Uninstall-ServiceBus {
    param(
        [Parameter(Mandatory = $true)]
        [string]
        $rootPath,     
        [Parameter(Mandatory = $true)]
        [System.XML.XMLElement]
        $serviceBusConfig
    )
}

function Get-MetadataForServiceBus {
    param(   
        [Parameter(Mandatory = $true)]
        [System.XML.XMLElement]
        $serviceBusConfig
    )   
}

function Get-SbTopic {
    [CmdletBinding()]
    param(
        [string] $connectionString,
        [string] $name
    )

    $namespaceManager = [Microsoft.ServiceBus.NamespaceManager]::CreateFromConnectionString($connectionString)
    $namespaceManager.GetTopic($name)
}

function Test-SbTopic {
    [CmdletBinding()]
    param(
        [string] $connectionString,
        [string] $name
    )

    $namespaceManager = [Microsoft.ServiceBus.NamespaceManager]::CreateFromConnectionString($connectionString)
    $namespaceManager.TopicExists($name)
}

function Remove-SbTopic {
    [CmdletBinding()]
    param(
        [string] $connectionString,
        [string] $name
    )

    $namespaceManager = [Microsoft.ServiceBus.NamespaceManager]::CreateFromConnectionString($connectionString)
    $namespaceManager.DeleteTopic($name)
}

function New-SbTopic {
    [CmdletBinding()]
    param(
        [string] $connectionString,
        [string] $name
    )

    $namespaceManager = [Microsoft.ServiceBus.NamespaceManager]::CreateFromConnectionString($connectionString)
    $topicDescription = New-Object Microsoft.ServiceBus.Messaging.TopicDescription $name
    $namespaceManager.CreateTopic($topicDescription)
}

function Get-SbTopicSubscription {
    [CmdletBinding()]
    param(
        [string] $connectionString,
        [string] $topic,
        [string] $name
    )

    $namespaceManager = [Microsoft.ServiceBus.NamespaceManager]::CreateFromConnectionString($connectionString)
    $namespaceManager.GetSubscription($topic, $name)
}

function Test-SbTopicSubscription {
    [CmdletBinding()]
    param(
        [string] $connectionString,
        [string] $topic,
        [string] $name
    )

    $namespaceManager = [Microsoft.ServiceBus.NamespaceManager]::CreateFromConnectionString($connectionString)
    $namespaceManager.SubscriptionExists($topic, $name)
}

function Remove-SbTopicSubscription {
    [CmdletBinding()]
    param(
        [string] $connectionString,
        [string] $topic,
        [string] $name
    )

    $namespaceManager = [Microsoft.ServiceBus.NamespaceManager]::CreateFromConnectionString($connectionString)
    $namespaceManager.DeleteSubscription($topic, $name)
}

function New-SbTopicSubscription {
    [CmdletBinding()]
    param(
        [string] $connectionString,
        [string] $topic,
        [string] $name
    )

    $namespaceManager = [Microsoft.ServiceBus.NamespaceManager]::CreateFromConnectionString($connectionString)
    $subscriptionDescription =  New-Object Microsoft.ServiceBus.Messaging.SubscriptionDescription $topic,$name
    
    $namespaceManager.CreateSubscription($subscriptionDescription)
}

function New-SbTopicSubscriptionRule {
    [CmdletBinding()]
    param(
        [string] $connectionString,
        [string] $topic,
        [string] $subscription,
        [string] $name,
        [string] $filter,
        [string] $action

    )

    if (!$filter -and !$action){
        return
    }

    $subscription = Get-SbTopicSubscription -connectionString $connectionString -topic $topic -name $subscription

    $ruleDescription = New-Object Microsoft.ServiceBus.Messaging.RuleDescription
    $ruleDescription.Name = $name

    if ($filter) {
        $ruleDescription.Filter = New-Object Microsoft.ServiceBus.Messaging.SqlFilter $filter
    }

    if ($action) {
        $ruleDescription.Action = New-Object Microsoft.ServiceBus.Messaging.SqlRuleAction $action
    }

}

function Remove-SbTopicSubscriptionRule {
    [CmdletBinding()]
    param(
        [string] $connectionString,
        [string] $topic,
        [string] $subscription,
        [string] $name
    )

    $subscription = Get-SbTopicSubscription -connectionString $connectionString -topic $topic -name $subscription
}

function Get-SbTopicSubscriptionRule {
    [CmdletBinding()]
    param(
        [string] $connectionString,
        [string] $topic,
        [string] $subscription,
        [string] $name
    )

    $subscription = Get-SbTopicSubscription -connectionString $connectionString -topic $topic -name $subscription
}

$connectionString = 'Endpoint=sb://uk-lon-pc-7m1j.office.interxion.net/ServiceBusDefaultNamespace;StsEndpoint=https://uk-lon-pc-7m1j.office.interxion.net:9355/ServiceBusDefaultNamespace;RuntimePort=9354;ManagementPort=9355;SharedAccessKeyName=RootManageSharedAccessKey;SharedAccessKey=vv4rcKFwx5MskGcsxZ4ftb+zBv2WkCoM2V9Xa+7RByM='
$topic = 'TestTopic'
$subscription = 'TestSubscription'
$rule = 'TestSubscriptionRule'
$ruleExpression = '1=1'
$ruleAction = ''

clear
sleep 1

Write-Host "Creating topic"
New-SbTopic -connectionString $connectionString -name $topic
Get-SbTopic -connectionString $connectionString -name $topic
Test-SbTopic -connectionString $connectionString -name $topic

Write-Host "Creating subscription"
New-SbTopicSubscription -connectionString $connectionString -topic $topic -name $subscription
Get-SbTopicSubscription -connectionString $connectionString -topic $topic -name $subscription
Test-SbTopicSubscription -connectionString $connectionString -topic $topic -name $subscription

Write-Host "Creating subscription rule"



Write-Host "Removing subscription"
Remove-SbTopicSubscription -connectionString $connectionString -topic $topic -name $subscription
Test-SbTopicSubscription -connectionString $connectionString -topic $topic -name $subscription

Write-Host "Removing topic"
Remove-SbTopic -connectionString $connectionString -name $topic
Test-SbTopic -connectionString $connectionString -name $topic