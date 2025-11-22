targetScope = 'subscription'

@description('Logical environment label (e.g., dev, stage, prod).')
param environmentName string

@description('Azure region to deploy all resources into.')
param location string

@description('AKS cluster name.')
param aksName string

@description('Azure Container Registry name.')
param acrName string

@description('Event Hubs namespace name.')
param eventHubNamespace string

@description('Explicit storage account name used when randomization is disabled (3-24 lowercase alphanumeric).')
param storageAccountName string = 'ordersstorage001'

@description('Base prefix (3-11 lowercase alphanumeric) for generated storage account names.')
param storageAccountPrefix string = 'ordersstorage'

@description('When true, append a deterministic suffix to storageAccountPrefix to ensure global uniqueness.')
param storageAccountRandomize bool = true

@description('Application Insights component name.')
param applicationInsightsName string

@secure()
@description('SSH RSA public key used for the AKS node admin account.')
param sshRSAPublicKey string

@description('Optional override for the resource group name.')
param resourceGroupName string = toLower('rg-orders-${environmentName}')

@description('DNS prefix for the AKS API server endpoint.')
param aksDnsPrefix string = toLower('orders-${environmentName}')

@description('Default Event Hub entity name.')
param eventHubName string = 'orders'

@description('Consumer group used by the worker service.')
param eventHubConsumerGroup string = 'orders-worker'

@description('Name for the user-assigned workload identity.')
param workloadIdentityName string = toLower('orders-workload-${environmentName}')

@description('Default tags applied to all resources.')
param tags object = {}

@description('VM size for AKS system node pool.')
param agentPoolVMSize string = 'Standard_D4as_v5'

@description('Initial AKS node count.')
@minValue(1)
param agentPoolNodeCount int = 2

@description('Maximum AKS node count when autoscaling.')
@minValue(1)
param agentPoolMaxCount int = 5

@description('Kubernetes version to deploy onto AKS.')
param kubernetesVersion string = '1.33.5'

@description('Admin username for AKS nodes.')
param linuxAdminUsername string = 'aksadmin'

var standardTags = union({
	Environment: environmentName
	Project: 'orders-demo'
}, tags)

var storageSuffix = toLower(substring(uniqueString(subscription().id, environmentName, resourceGroupName), 0, 8))
var generatedStorageAccountName = toLower('${storageAccountPrefix}${storageSuffix}')
var effectiveStorageAccountName = storageAccountRandomize || empty(storageAccountName) ? generatedStorageAccountName : toLower(storageAccountName)

resource rg 'Microsoft.Resources/resourceGroups@2021-04-01' = {
	name: resourceGroupName
	location: location
	tags: standardTags
}

var logAnalyticsWorkspaceName = toLower('law-orders-${environmentName}')

module monitoring './modules/monitoring.bicep' = {
	name: 'monitoring-${environmentName}'
	scope: rg
	params: {
		workspaceName: logAnalyticsWorkspaceName
		applicationInsightsName: applicationInsightsName
		location: location
		tags: standardTags
	}
}

module acr './modules/acr.bicep' = {
	name: 'acr-${environmentName}'
	scope: rg
	params: {
		name: acrName
		location: location
		tags: standardTags
	}
}

module storage './modules/storage.bicep' = {
	name: 'storage-${environmentName}'
	scope: rg
	params: {
		name: effectiveStorageAccountName
		location: location
		tags: standardTags
	}
}

module identity './modules/identity.bicep' = {
	name: 'identity-${environmentName}'
	scope: rg
	params: {
		identityName: workloadIdentityName
		location: location
		tags: standardTags
	}
}

module eventHubs './modules/eventhubs.bicep' = {
	name: 'eventhub-${environmentName}'
	scope: rg
	params: {
		namespaceName: eventHubNamespace
		eventHubName: eventHubName
		location: location
		consumerGroupName: eventHubConsumerGroup
		tags: standardTags
	}
}

module aks './modules/aks.bicep' = {
	name: 'aks-${environmentName}'
	scope: rg
	params: {
		name: aksName
		location: location
		dnsPrefix: aksDnsPrefix
		kubernetesVersion: kubernetesVersion
		agentPoolVMSize: agentPoolVMSize
		agentPoolNodeCount: agentPoolNodeCount
		agentPoolMaxCount: agentPoolMaxCount
		linuxAdminUsername: linuxAdminUsername
		sshRSAPublicKey: sshRSAPublicKey
		logAnalyticsWorkspaceResourceId: monitoring.outputs.logAnalyticsId
		tags: standardTags
	}
}

module roles './modules/roles.bicep' = {
	name: 'roles-${environmentName}'
	scope: rg
	params: {
		acrName: acr.outputs.name
		storageAccountName: storage.outputs.name
		eventHubNamespaceName: eventHubs.outputs.namespaceNameOut
		aksKubeletPrincipalId: aks.outputs.kubeletPrincipalId
		workloadIdentityPrincipalId: identity.outputs.principalId
	}
}

output resourceGroupNameOut string = rg.name
output aksNameOut string = aks.outputs.name
output aksFqdn string = aks.outputs.fqdn
output acrLoginServer string = acr.outputs.loginServer
output storageConnectionString string = storage.outputs.primaryConnectionString
output eventHubSendConnection string = eventHubs.outputs.sendPrimaryConnectionString
output eventHubListenConnection string = eventHubs.outputs.listenPrimaryConnectionString
output workloadIdentityClientId string = identity.outputs.clientId
output applicationInsightsConnectionString string = monitoring.outputs.applicationInsightsConnectionString
output logAnalyticsWorkspaceId string = monitoring.outputs.logAnalyticsId
output eventHubNamespace string = eventHubs.outputs.namespaceNameOut
output eventHubName string = eventHubs.outputs.eventHubNameOut
output storageAccountName string = effectiveStorageAccountName
output acrName string = acr.outputs.name
