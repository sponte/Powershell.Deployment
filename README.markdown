# What is it for?

It provides an easy way to do common deployment tasks.

# When should I use it?

If you want to deploy a web service or a windows service.

# What does it consist of

## Hook in base scripts

These are the contracts that every component must fufill when dealing with deployments. Its important to have this strong convention as it will allow you to treat each component the same in a release automation tool like Octopus. This makes it simple to use with configuration management tools like Chef and Puppet as well.

This also gives component developers an opportunity to add any custom configuration that is not covered by Powershell helper modules. 

Each script will have access to the xml infrastructure configuration file and the json parameter configuration file when being executed.

### Install

Calling this will install the component.

### Uninstall

Calling this will uninstall the component.

### Start

Calling this will start the component.

### Stop

Calling this will stop the component.

### UpdateConfiguration

Calling this will update configuration used by the component. 

### Metadata

Calling this will return metadata about the component. It could return the assembly file version and the component name for example.

## Xsd Validator

This provides intellisense for xml infrastructure configuration. It also provides documenation on the features that are available.

## Xml Infrastructure Configuration

This file describes what infrastructure needs to be configured for the component. 

It can make use of variables:

Use moustache syntax to access variables in configuration e.g. "http://{{domainName}}"

It can also be any Powershell statement:

Use moustache syntax to access variables in configuration e.g. "http://{{ENV['HOSTNAME'] + '.test.com'}}"

## Json Parameter Configuration

This is a Json object that describes environment configuration. The one that is checked into source control should work out of the box for a developer. When doing a deployment this can be overridden as required. To make this work well with systems like Octopus, the suggestion is to use a simple key value structure and not an object graph. Most deployment systems will expose configuration as environmental variables or global powershell variables e.g. Octopus.

## Powershell helper modules

# Workflow

Install Nuget package
* The hook in base scripts are created. The installation process will try to detect the project type and create an appropriate default.
* Xsd validator for xml infrastructure configuration file is created.
* A xml infrastructure configuration file is created. The installation process will try to detect the project type and create an appropriate default.
* A demo json parameter configuration file is created. This is the variables to use for templates. These variables can be overridden with environment variables of the same name or global powershell variables of the same name. 
* Powershell helper modules are added.

Upgrade Nuget package.
* Powershell helper modules are updated.
* Xsd validator for xml infrastructure configuration is updated.

This means that any custom configuration created is not overwritten, but you are still able to update the Powershell helper modules.

# What type of common deployment tasks does it help with

## Windows Services
* Add/Remove Windows Service (Topshelf, NServiceBus, JavaService and Standard Windows Services)

## IIS
* Add/Remove App Pool
* Add/Remove Websites
* Select certificate to use for website

## Certificates
* Certificate permissions
* Add certificates

## Files
* File Permissions

## Windows Service Bus
* Add/Remove Topic
* Add/Remove Topic Subscription
* Add/Remove Queue

## PRTG
* Add PRTG monitoring end point
