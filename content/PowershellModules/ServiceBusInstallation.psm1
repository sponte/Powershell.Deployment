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
        Install-ServiceBusTopic -connectionString $serviceBusConfig.connectionString -serviceBusTopicConfig $serviceBusTopicConfig
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

    $topic = $serviceBusTopicConfig.Name

    if (!(Test-SbTopic -connectionString $connectionString -name $topic)) {
        Write-Log "Creating topic $subscription"
        New-SbTopic -connectionString $connectionString -name $topic
    }

    foreach($serviceBusAuthorizationConfig in @($serviceBusTopicConfig.authorizations.authorization)) {
        if(!$serviceBusAuthorizationConfig) { continue }

        Install-ServiceBusAuthorization -connectionString $connectionString -topic $topic -serviceBusAuthorizationConfig $serviceBusAuthorizationConfig
    }  

    foreach($serviceBusSubscriptionConfig in @($serviceBusTopicConfig.subscriptions.subscription)) {
        if(!$serviceBusSubscriptionConfig) { continue }

        Install-ServiceBusSubscription -connectionString $connectionString -topic $topic -serviceBusSubscriptionConfig $serviceBusSubscriptionConfig
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
        $serviceBusAuthorizationConfig
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

    $subscription = $serviceBusSubscriptionConfig.Name

    if (!(Test-SbTopicSubscription -connectionString $connectionString -topic $topic -name $subscription)) {
        Write-Log "Creating subscription $subscription"
        New-SbTopicSubscription -connectionString $connectionString -topic $topic -name $subscription
    }

    foreach($serviceBusSubscriptionRuleConfig in @($serviceBusSubscriptionConfig.rules.rule)) {
        if(!$serviceBusSubscriptionRuleConfig) { continue }

        Install-ServiceBusSubscriptionRule -connectionString $connectionString -topic $topic -subscription $subscription -serviceBusSubscriptionRuleConfig $serviceBusSubscriptionRuleConfig
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

    $rule = $serviceBusSubscriptionRuleConfig.Name

    if (!(Test-SbTopicSubscriptionRule -connectionString $connectionString -topic $topic -subscription $subscription -name $rule)) {
        Write-Log "Creating subscription rule $rule"
        New-SbTopicSubscriptionRule -connectionString $connectionString -topic $topic -subscription $subscription -name $rule -filter $serviceBusSubscriptionRuleConfig.filter -action $serviceBusSubscriptionRuleConfig.action
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

    $subscriptionClient = [Microsoft.ServiceBus.Messaging.SubscriptionClient]::CreateFromConnectionString($connectionString, $topic, $subscription)

    $ruleDescription = New-Object Microsoft.ServiceBus.Messaging.RuleDescription
    $ruleDescription.Name = $name

    if ($filter) {
        $ruleDescription.Filter = New-Object Microsoft.ServiceBus.Messaging.SqlFilter $filter
    }

    if ($action) {
        $ruleDescription.Action = New-Object Microsoft.ServiceBus.Messaging.SqlRuleAction $action
    }

    $subscriptionClient.AddRule($ruleDescription)
}

function Remove-SbTopicSubscriptionRule {
    [CmdletBinding()]
    param(
        [string] $connectionString,
        [string] $topic,
        [string] $subscription,
        [string] $name
    )

    $subscriptionClient = [Microsoft.ServiceBus.Messaging.SubscriptionClient]::CreateFromConnectionString($connectionString, $topic, $subscription)
    $subscriptionClient.RemoveRule($name)
}

function Get-SbTopicSubscriptionRule {
    [CmdletBinding()]
    param(
        [string] $connectionString,
        [string] $topic,
        [string] $subscription,
        [string] $name
    )

    $namespaceManager = [Microsoft.ServiceBus.NamespaceManager]::CreateFromConnectionString($connectionString)
    $namespaceManager.GetRules($topic, $subscription) | ?{$_.Name -eq $name}
}

function Test-SbTopicSubscriptionRule {
    [CmdletBinding()]
    param(
        [string] $connectionString,
        [string] $topic,
        [string] $subscription,
        [string] $name
    )

    $namespaceManager = [Microsoft.ServiceBus.NamespaceManager]::CreateFromConnectionString($connectionString)
    $rules = $namespaceManager.GetRules($topic, $subscription) | ?{$_.Name -eq $name} 

    if ($rules) {
        return $true
    } else {
        return $false
    }
}