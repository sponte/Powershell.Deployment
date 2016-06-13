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

    foreach($serviceBusQueueConfig in @($serviceBusConfig.queues.queue)) {
        if(!$serviceBusQueueConfig) { continue }
        Install-ServiceBusQueue -connectionString $serviceBusConfig.connectionString -serviceBusQueueConfig $serviceBusQueueConfig
    }

    foreach($serviceBusTopicConfig in @($serviceBusConfig.topics.topic)) {
        if(!$serviceBusTopicConfig) { continue }
        Install-ServiceBusTopic -connectionString $serviceBusConfig.connectionString -serviceBusTopicConfig $serviceBusTopicConfig
    }
}

function Install-ServiceBusQueue {
    param(
        [Parameter(Mandatory = $true)]
        [string]
        $connectionString,     
        [Parameter(Mandatory = $true)]
        [System.XML.XMLElement]
        $serviceBusQueueConfig
    )
    $ErrorActionPreference = "stop"

    $queue = $serviceBusQueueConfig.Name
    
    $autoDeleteOnIdle = [System.Xml.XmlConvert]::ToTimeSpan($serviceBusQueueConfig.AutoDeleteOnIdle)
    $defaultMessageTimeToLive = [System.Xml.XmlConvert]::ToTimeSpan($serviceBusQueueConfig.DefaultMessageTimeToLive)
    $duplicateDetectionHistoryTimeWindow = [System.Xml.XmlConvert]::ToTimeSpan($serviceBusQueueConfig.DuplicateDetectionHistoryTimeWindow)
    $enableDeadLetteringOnMessageExpiration = $serviceBusQueueConfig.EnableDeadLetteringOnMessageExpiration -eq $true
    $enableBatchedOperations = $serviceBusQueueConfig.EnableBatchedOperations -eq $true
    $enableExpress = $serviceBusQueueConfig.EnableExpress -eq $true
    $enablePartitioning = $serviceBusQueueConfig.EnablePartitioning -eq $true
    $forwardDeadLetteredMessagesTo = $serviceBusQueueConfig.ForwardDeadLetteredMessagesTo 
    $forwardTo  = $serviceBusQueueConfig.ForwardTo 
    $isAnonymousAccessible = $serviceBusQueueConfig.IsAnonymousAccessible -eq $true
    $lockDuration = [System.Xml.XmlConvert]::ToTimeSpan($serviceBusQueueConfig.LockDuration)
    $maxDeliveryCount  = $serviceBusQueueConfig.MaxDeliveryCount 
    $maxSizeInMegabytes  = $serviceBusQueueConfig.MaxSizeInMegabytes 
    $requiresDuplicateDetection  = $serviceBusQueueConfig.RequiresDuplicateDetection -eq $true
    $requiresSession = $serviceBusQueueConfig.RequiresSession -eq $true
    $supportOrdering  = $serviceBusQueueConfig.SupportOrdering -eq $true

    if (!(Test-SbQueue -connectionString $connectionString -name $queue)) {
        Write-Log "Creating queue $queue"
        
        try{   
            New-SbQueue -connectionString $connectionString -name $queue `
                -autoDeleteOnIdle $autoDeleteOnIdle `
                -defaultMessageTimeToLive $defaultMessageTimeToLive `
                -duplicateDetectionHistoryTimeWindow $duplicateDetectionHistoryTimeWindow `
                -enableDeadLetteringOnMessageExpiration $enableDeadLetteringOnMessageExpiration `
                -enableBatchedOperations $enableBatchedOperations `
                -enableExpress $enableExpress `
                -enablePartitioning $enablePartitioning `
                -forwardDeadLetteredMessagesTo $forwardDeadLetteredMessagesTo `
                -forwardTo $forwardTo `
                -isAnonymousAccessible $isAnonymousAccessible `
                -lockDuration $lockDuration `
                -maxDeliveryCount $maxDeliveryCount `
                -maxSizeInMegabytes $maxSizeInMegabytes `
                -requiresDuplicateDetection $requiresDuplicateDetection `
                -requiresSession $requiresSession `
                -supportOrdering $supportOrdering
        } Catch [Microsoft.ServiceBus.Messaging.MessagingEntityAlreadyExistsException] {
            Write-Warning "Queue $queue already exists, unable to create it"
        }
    }

    foreach($serviceBusQueueAuthorizationConfig in @($serviceBusQueueConfig.authorizations.authorization)) {
        if(!$serviceBusQueueAuthorizationConfig) { continue }

        Install-ServiceBusQueueAuthorization -connectionString $connectionString -queue $queue -serviceBusAuthorizationConfig $serviceBusQueueAuthorizationConfig
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

    $autoDeleteOnIdle = [System.Xml.XmlConvert]::ToTimeSpan($serviceBusTopicConfig.AutoDeleteOnIdle)
    $defaultMessageTimeToLive = [System.Xml.XmlConvert]::ToTimeSpan($serviceBusTopicConfig.DefaultMessageTimeToLive)
    $duplicateDetectionHistoryTimeWindow = [System.Xml.XmlConvert]::ToTimeSpan($serviceBusTopicConfig.DuplicateDetectionHistoryTimeWindow)
    $enableBatchedOperations = $serviceBusTopicConfig.EnableBatchedOperations -eq $true
    $enableExpress = $serviceBusTopicConfig.EnableExpress -eq $true
    $enableFilteringMessagesBeforePublishing = $serviceBusTopicConfig.EnableFilteringMessagesBeforePublishing -eq $true
    $enablePartitioning = $serviceBusTopicConfig.EnablePartitioning -eq $true
    $isAnonymousAccessible = $serviceBusTopicConfig.IsAnonymousAccessible -eq $true
    $maxSizeInMegabytes  = $serviceBusTopicConfig.MaxSizeInMegabytes 
    $requiresDuplicateDetection  = $serviceBusTopicConfig.RequiresDuplicateDetection -eq $true
    $supportOrdering  = $serviceBusTopicConfig.SupportOrdering -eq $true    

    if (!(Test-SbTopic -connectionString $connectionString -name $topic)) {
        Write-Log "Creating topic $topic"
        
        try{   
            New-SbTopic -connectionString $connectionString -name $topic `
                -autoDeleteOnIdle $autoDeleteOnIdle `
                -defaultMessageTimeToLive $defaultMessageTimeToLive `
                -duplicateDetectionHistoryTimeWindow $duplicateDetectionHistoryTimeWindow `
                -enableBatchedOperations $enableBatchedOperations `
                -enableExpress $enableExpress `
                -enableFilteringMessagesBeforePublishing $enableFilteringMessagesBeforePublishing `
                -enablePartitioning $enablePartitioning `
                -isAnonymousAccessible $isAnonymousAccessible `
                -maxSizeInMegabytes $maxSizeInMegabytes `
                -requiresDuplicateDetection $requiresDuplicateDetection `
                -supportOrdering $supportOrdering `
        } Catch [Microsoft.ServiceBus.Messaging.MessagingEntityAlreadyExistsException] {
            Write-Warning "Topic $topic already exists, unable to create it"
        }
    }

    foreach($serviceBusTopicAuthorizationConfig in @($serviceBusTopicConfig.authorizations.authorization)) {
        if(!$serviceBusTopicAuthorizationConfig) { continue }

        Install-ServiceBusTopicAuthorization -connectionString $connectionString -topic $topic -serviceBusTopicAuthorizationConfig $serviceBusTopicAuthorizationConfig
    }  

    foreach($serviceBusSubscriptionConfig in @($serviceBusTopicConfig.subscriptions.subscription)) {
        if(!$serviceBusSubscriptionConfig) { continue }

        Install-ServiceBusSubscription -connectionString $connectionString -topic $topic -serviceBusSubscriptionConfig $serviceBusSubscriptionConfig
    }
}

function Install-ServiceBusQueueAuthorization {
    param(
        [Parameter(Mandatory = $true)]
        [string]
        $connectionString,    
        [Parameter(Mandatory = $true)]
        [string]
        $queue, 
        [Parameter(Mandatory = $true)]
        [System.XML.XMLElement]
        $serviceBusQueueAuthorizationConfig
    )

    Write-Warning "We dont support authorization yet"
}

function Install-ServiceBusTopicAuthorization {
    param(
        [Parameter(Mandatory = $true)]
        [string]
        $connectionString,    
        [Parameter(Mandatory = $true)]
        [string]
        $topic, 
        [Parameter(Mandatory = $true)]
        [System.XML.XMLElement]
        $serviceBusTopicAuthorizationConfig
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

    $autoDeleteOnIdle = [System.Xml.XmlConvert]::ToTimeSpan($serviceBusSubscriptionConfig.AutoDeleteOnIdle)
    $defaultMessageTimeToLive = [System.Xml.XmlConvert]::ToTimeSpan($serviceBusSubscriptionConfig.DefaultMessageTimeToLive)
    $enableBatchedOperations = $serviceBusSubscriptionConfig.EnableBatchedOperations -eq $true
    $enableDeadLetteringOnFilterEvaluationExceptions = $serviceBusSubscriptionConfig.EnableDeadLetteringOnFilterEvaluationExceptions -eq $true
    $enableDeadLetteringOnMessageExpiration = $serviceBusSubscriptionConfig.EnableDeadLetteringOnMessageExpiration -eq $true
    $forwardDeadLetteredMessagesTo = $serviceBusSubscriptionConfig.ForwardDeadLetteredMessagesTo
    $forwardTo = $serviceBusSubscriptionConfig.ForwardTo
    $lockDuration = [System.Xml.XmlConvert]::ToTimeSpan($serviceBusSubscriptionConfig.LockDuration)
    $maxDeliveryCount  = $serviceBusSubscriptionConfig.MaxDeliveryCount 
    $requiresSession = $serviceBusSubscriptionConfig.RequiresSession -eq $true

    if (!(Test-SbTopicSubscription -connectionString $connectionString -topic $topic -name $subscription)) {
        Write-Log "Creating subscription $subscription"

        try{   
            New-SbTopicSubscription -connectionString $connectionString -topic $topic -name $subscription `
                -autoDeleteOnIdle $autoDeleteOnIdle `
                -defaultMessageTimeToLive $defaultMessageTimeToLive `
                -enableBatchedOperations $enableBatchedOperations `
                -enableDeadLetteringOnFilterEvaluationExceptions $enableDeadLetteringOnFilterEvaluationExceptions `
                -forwardDeadLetteredMessagesTo $forwardDeadLetteredMessagesTo `
                -forwardTo $forwardTo `
                -lockDuration $lockDuration `
                -maxDeliveryCount $maxDeliveryCount `
                -requiresSession $requiresSession 
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

    foreach($serviceBusTopicConfig in @($serviceBusConfig.queues.queue)) {
        if(!$serviceBusTopicConfig) { continue }
        Uninstall-ServiceBusQueue -connectionString $serviceBusConfig.connectionString -$serviceBusQueueConfig $serviceBusTopicConfig
    }

    foreach($serviceBusTopicConfig in @($serviceBusConfig.topics.topic)) {
        if(!$serviceBusTopicConfig) { continue }
        Uninstall-ServiceBusTopic -connectionString $serviceBusConfig.connectionString -serviceBusTopicConfig $serviceBusTopicConfig
    }
}

function Uninstall-ServiceBusQueue {
    param(
        [Parameter(Mandatory = $true)]
        [string]
        $connectionString,     
        [Parameter(Mandatory = $true)]
        [System.XML.XMLElement]
        $serviceBusQueueConfig
    )
    $ErrorActionPreference = "stop"

    $queue = $serviceBusQueueConfig.Name

    if ((Test-SbQueue -connectionString $connectionString -name $queue)) {
        Write-Log "Not removing queue $queue"
    }
}

function Uninstall-ServiceBusTopic {
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
        Write-Log "Not removing topic $topic"
    }
}

function Get-MetadataForServiceBus {
    param(   
        [Parameter(Mandatory = $true)]
        [System.XML.XMLElement]
        $serviceBusConfig
    )
}

function Get-SbQueue {
    [CmdletBinding()]
    param(
        [string] $connectionString,
        [string] $name
    )

    $namespaceManager = [Microsoft.ServiceBus.NamespaceManager]::CreateFromConnectionString($connectionString)
    $namespaceManager.GetQueue($name)
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

function Test-SbQueue {
    [CmdletBinding()]
    param(
        [string] $connectionString,
        [string] $name
    )

    $namespaceManager = [Microsoft.ServiceBus.NamespaceManager]::CreateFromConnectionString($connectionString)
    $namespaceManager.QueueExists($name)
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

function Remove-SbQueue {
    [CmdletBinding()]
    param(
        [string] $connectionString,
        [string] $name
    )

    $namespaceManager = [Microsoft.ServiceBus.NamespaceManager]::CreateFromConnectionString($connectionString)
    $namespaceManager.DeleteQueue($name)
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

function New-SbQueue {
    [CmdletBinding()]
    param(
        [string] $connectionString,
        [string] $name,
        [System.TimeSpan] $autoDeleteOnIdle = [System.TimeSpan]"106751:02:48:05.477",
        [System.TimeSpan] $defaultMessageTimeToLive = [System.TimeSpan]"106751:02:48:05.477",
        [System.TimeSpan] $duplicateDetectionHistoryTimeWindow = [System.TimeSpan]"00:10:00",
        [bool] $enableDeadLetteringOnMessageExpiration = $false,
        [bool] $enableBatchedOperations = $false,
        [bool] $enableExpress = $false,
        [bool] $enablePartitioning = $false,
        [string] $forwardDeadLetteredMessagesTo = "",
        [string] $forwardTo  = "",
        [bool] $isAnonymousAccessible = $false,
        [System.TimeSpan] $lockDuration = [System.TimeSpan]"00:01:00",
        [int] $maxDeliveryCount  = 10,
        [long] $maxSizeInMegabytes  = 1000,
        [bool] $requiresDuplicateDetection = $false,
        [bool] $requiresSession = $false,
        [bool] $supportOrdering  = $false
    )

    $namespaceManager = [Microsoft.ServiceBus.NamespaceManager]::CreateFromConnectionString($connectionString)
    $queueDescription = New-Object Microsoft.ServiceBus.Messaging.QueueDescription $name

    $queueDescription.AutoDeleteOnIdle = $autoDeleteOnIdle
    $queueDescription.DefaultMessageTimeToLive = $defaultMessageTimeToLive
    $queueDescription.DuplicateDetectionHistoryTimeWindow = $duplicateDetectionHistoryTimeWindow
    $queueDescription.EnableDeadLetteringOnMessageExpiration = $enableDeadLetteringOnMessageExpiration
    $queueDescription.EnableBatchedOperations = $enableBatchedOperations
    if(Get-Member -inputobject $queueDescription -MemberType Properties | ?{$_.Name -eq "EnableExpress"}){
        $queueDescription.EnableExpress = $enableExpress
    }
    if(Get-Member -inputobject $queueDescription -MemberType Properties | ?{$_.Name -eq "EnablePartitioning"}){
        $queueDescription.EnablePartitioning = $enablePartitioning
    }
    if(Get-Member -inputobject $queueDescription -MemberType Properties | ?{$_.Name -eq "ForwardDeadLetteredMessagesTo"}){
        $queueDescription.ForwardDeadLetteredMessagesTo = $forwardDeadLetteredMessagesTo
    }
    $queueDescription.ForwardTo  = $forwardTo
    $queueDescription.IsAnonymousAccessible = $isAnonymousAccessible
    $queueDescription.LockDuration = $lockDuration
    $queueDescription.MaxDeliveryCount  = $maxDeliveryCount 
    $queueDescription.MaxSizeInMegabytes  = $maxSizeInMegabytes
    $queueDescription.RequiresDuplicateDetection  = $requiresDuplicateDetection
    $queueDescription.RequiresSession = $requiresSession
    $queueDescription.SupportOrdering  = $supportOrdering
    $queueDescription.LockDuration = $lockDuration

    $namespaceManager.CreateQueue($queueDescription)
}

function New-SbTopic {
    [CmdletBinding()]
    param(
        [string] $connectionString,
        [string] $name,
        [System.TimeSpan] $autoDeleteOnIdle = [System.TimeSpan]"106751:02:48:05.477",
        [System.TimeSpan] $defaultMessageTimeToLive = [System.TimeSpan]"106751:02:48:05.477",
        [System.TimeSpan] $duplicateDetectionHistoryTimeWindow = [System.TimeSpan]"00:10:00",
        [bool] $enableBatchedOperations = $false,
        [bool] $enableExpress = $false,
        [bool] $enableFilteringMessagesBeforePublishing = $false,
        [bool] $enablePartitioning = $false,
        [bool] $isAnonymousAccessible = $false,
        [long] $maxSizeInMegabytes  = 1000,
        [bool] $requiresDuplicateDetection = $false,
        [bool] $supportOrdering  = $false
    )

    $namespaceManager = [Microsoft.ServiceBus.NamespaceManager]::CreateFromConnectionString($connectionString)
    $topicDescription = New-Object Microsoft.ServiceBus.Messaging.TopicDescription $name

    $topicDescription.AutoDeleteOnIdle = $autoDeleteOnIdle
    $topicDescription.DefaultMessageTimeToLive = $defaultMessageTimeToLive
    $topicDescription.DuplicateDetectionHistoryTimeWindow = $duplicateDetectionHistoryTimeWindow
    $topicDescription.EnableBatchedOperations = $enableBatchedOperations

    if(Get-Member -inputobject $topicDescription -MemberType Properties | ?{$_.Name -eq "EnableExpress"}){
        $topicDescription.EnableExpress = $enableExpress
    }

    $topicDescription.EnableFilteringMessagesBeforePublishing = $enableFilteringMessagesBeforePublishing 

    if(Get-Member -inputobject $topicDescription -MemberType Properties | ?{$_.Name -eq "EnablePartitioning"}){
        $topicDescription.EnablePartitioning = $enablePartitioning
    }

    $topicDescription.IsAnonymousAccessible = $isAnonymousAccessible
    $topicDescription.MaxSizeInMegabytes  = $maxSizeInMegabytes
    $topicDescription.RequiresDuplicateDetection  = $requiresDuplicateDetection
    $topicDescription.SupportOrdering  = $supportOrdering

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
        [System.TimeSpan] $autoDeleteOnIdle = [System.TimeSpan]"106751:02:48:05.477",
        [System.TimeSpan] $defaultMessageTimeToLive = [System.TimeSpan]"106751:02:48:05.477",
        [bool] $enableBatchedOperations = $false,
        [bool] $enableDeadLetteringOnFilterEvaluationExceptions  = $false,
        [bool] $enableDeadLetteringOnMessageExpiration  = $false,
        [string] $forwardDeadLetteredMessagesTo = "",
        [string] $forwardTo  = "",
        [System.TimeSpan] $lockDuration = [System.TimeSpan]"00:01:00",
        [int] $maxDeliveryCount  = 10,
        [bool] $requiresSession = $false        
    )

    $namespaceManager = [Microsoft.ServiceBus.NamespaceManager]::CreateFromConnectionString($connectionString)
    $subscriptionDescription =  New-Object Microsoft.ServiceBus.Messaging.SubscriptionDescription $topic,$name

    $subscriptionDescription.AutoDeleteOnIdle = $autoDeleteOnIdle
    $subscriptionDescription.DefaultMessageTimeToLive = $defaultMessageTimeToLive
    $subscriptionDescription.EnableBatchedOperations = $enableBatchedOperations
    $subscriptionDescription.EnableDeadLetteringOnFilterEvaluationExceptions = $enableDeadLetteringOnFilterEvaluationExceptions
    $subscriptionDescription.EnableDeadLetteringOnMessageExpiration = $enableDeadLetteringOnMessageExpiration
    if(Get-Member -inputobject $subscriptionDescription -MemberType Properties | ?{$_.Name -eq "ForwardDeadLetteredMessagesTo"}){
        $subscriptionDescription.ForwardDeadLetteredMessagesTo = $forwardDeadLetteredMessagesTo
    }
    $subscriptionDescription.ForwardTo = $forwardTo
    $subscriptionDescription.LockDuration = $lockDuration
    $subscriptionDescription.MaxDeliveryCount = $maxDeliveryCount
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