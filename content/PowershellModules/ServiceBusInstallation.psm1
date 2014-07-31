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

    foreach($serviceBusSubscriptionConfig in @($serviceBusTopicConfig.subscriptions.subscription)) {
        if(!$serviceBusSubscriptionConfig) { continue }

        Install-ServiceBusSubscription -connectionString $connectionString -serviceBusSubscriptionConfig $serviceBusSubscriptionConfig
    }
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