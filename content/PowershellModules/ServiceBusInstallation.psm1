
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
        [string] $name,
        [string] $subscription
    )

    $namespaceManager = [Microsoft.ServiceBus.NamespaceManager]::CreateFromConnectionString($connectionString)
    $namespaceManager.GetSubscription($name, $subscription)
}

function Test-SbTopicSubscription {
    [CmdletBinding()]
    param(
        [string] $connectionString,
        [string] $name,
        [string] $subscription
    )

    $namespaceManager = [Microsoft.ServiceBus.NamespaceManager]::CreateFromConnectionString($connectionString)
    $namespaceManager.SubscriptionExists($name, $subscription)
}

function Remove-SbTopicSubscription {
    [CmdletBinding()]
    param(
        [string] $connectionString,
        [string] $name,
        [string] $subscription
    )

    $namespaceManager = [Microsoft.ServiceBus.NamespaceManager]::CreateFromConnectionString($connectionString)
    $namespaceManager.DeleteSubscription($name, $subscription)
}

function New-SbTopicSubscription {
    [CmdletBinding()]
    param(
        [string] $connectionString,
        [string] $name,
        [string] $subscription
    )

    $namespaceManager = [Microsoft.ServiceBus.NamespaceManager]::CreateFromConnectionString($connectionString)
    $subscriptionDescription =  New-Object Microsoft.ServiceBus.Messaging.SubscriptionDescription $name $subscription
    
    $namespaceManager.CreateSubscription($subscriptionDescription)
}