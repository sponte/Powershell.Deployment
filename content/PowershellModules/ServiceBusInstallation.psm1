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
    $ErrorActionPreference = "stop"

    $topic = $serviceBusTopicConfig.Name

    if (!(Test-SbTopic -connectionString $connectionString -name $topic)) {
        Write-Log "Creating topic $subscription"
        
        try{   
            New-SbTopic -connectionString $connectionString -name $topic
        } Catch [Microsoft.ServiceBus.Messaging.MessagingEntityAlreadyExistsException] {
            Write-Warning "Topic $topic already exists, unable to create it"
        }
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
    $ErrorActionPreference = "stop"

    $subscription = $serviceBusSubscriptionConfig.Name
	$requiresSession = $serviceBusSubscriptionConfig.RequiresSession -eq $true

    if (!(Test-SbTopicSubscription -connectionString $connectionString -topic $topic -name $subscription)) {
        Write-Log "Creating subscription $subscription"

        try{   
            New-SbTopicSubscription -connectionString $connectionString -topic $topic -name $subscription -requiresSession $requiresSession
        } Catch [Microsoft.ServiceBus.Messaging.MessagingEntityAlreadyExistsException] {
            Write-Warning "Topic subscription $subscription already exists, unable to create it"
        }
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
    $ErrorActionPreference = "stop"

    $rule = $serviceBusSubscriptionRuleConfig.Name
    $filter = $serviceBusSubscriptionRuleConfig.filter
    $action = $serviceBusSubscriptionRuleConfig.action

	if (Test-SbTopicSubscriptionRule -connectionString $connectionString -topic $topic -subscription $subscription -name '$Default') {
		Remove-SbTopicSubscriptionRule -connectionString $connectionString -topic $topic -subscription $subscription -name '$Default'
	}

    if (Test-SbTopicSubscriptionRule -connectionString $connectionString -topic $topic -subscription $subscription -name $rule) {
        $topicSubscriptionRule = Get-SbTopicSubscriptionRule -connectionString $connectionString -topic $topic -subscription $subscription -name $rule

        if ($topicSubscriptionRule) {
            $shouldDeleteRule = $false

            if ($topicSubscriptionRule.Filter.GetType().Name -eq 'SqlFilter' -and $topicSubscriptionRule.Filter.SqlExpression -ne $action) {
                $shouldDeleteRule = $true
            }

            if ($topicSubscriptionRule.Action.GetType().Name -eq 'SqlRuleAction' -and $topicSubscriptionRule.Action.SqlExpression -ne $action) {
                $shouldDeleteRule = $true
            }

            if ($topicSubscriptionRule.Action.GetType().Name -eq 'EmptyRuleAction' -and $action)  {
                $shouldDeleteRule = $true
            }
        } else {
            $shouldDeleteRule = $true
        }

        if ($shouldDeleteRule) {
            Write-Log "Rule $rule has been changed, so deleting it"
            Remove-SbTopicSubscriptionRule -connectionString $connectionString -topic $topic -subscription $subscription -name $rule
        }
    }

    if (!(Test-SbTopicSubscriptionRule -connectionString $connectionString -topic $topic -subscription $subscription -name $rule)) {
        Write-Log "Creating subscription rule $rule"

        try{   
            New-SbTopicSubscriptionRule -connectionString $connectionString -topic $topic -subscription $subscription -name $rule -filter $filter -action $action
        } Catch [Microsoft.ServiceBus.Messaging.MessagingEntityAlreadyExistsException] {
            Write-Warning "Topic subscription rule $rule already exists, unable to create it"
        }        
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
	    [string] $name,
        [bool] $requiresSession
    )

    $namespaceManager = [Microsoft.ServiceBus.NamespaceManager]::CreateFromConnectionString($connectionString)
    $subscriptionDescription =  New-Object Microsoft.ServiceBus.Messaging.SubscriptionDescription $topic,$name
	$subscriptionDescription.RequiresSession = $requiresSession
    
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