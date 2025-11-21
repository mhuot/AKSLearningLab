// Placeholder for Azure Container Registry module definition.
targetScope = 'resourceGroup'

@description('Globally unique ACR name (5-50 lowercase alphanumeric characters).')
param name string

@description('Azure region for the registry.')
param location string

@description('Registry SKU tier.')
@allowed([
	'Basic'
	'Standard'
	'Premium'
])
param sku string = 'Standard'

@description('Optional resource tags to apply to the registry.')
param tags object = {}

resource containerRegistry 'Microsoft.ContainerRegistry/registries@2023-07-01' = {
	name: name
	location: location
	sku: {
		name: sku
	}
	tags: tags
	properties: {
		adminUserEnabled: false
		publicNetworkAccess: 'Enabled'
	}
}

output id string = containerRegistry.id
output loginServer string = containerRegistry.properties.loginServer
output name string = containerRegistry.name
