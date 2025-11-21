// Placeholder for Storage Account module definition.
targetScope = 'resourceGroup'

@description('Globally unique storage account name (3-24 lowercase alphanumeric characters).')
param name string

@description('Azure region for the storage account.')
param location string

@description('Storage SKU to use.')
@allowed([
	'Standard_LRS'
	'Standard_GRS'
	'Standard_RAGRS'
	'Standard_ZRS'
	'Premium_LRS'
])
param skuName string = 'Standard_LRS'

@description('Storage account kind.')
@allowed([
	'StorageV2'
	'Storage'
	'BlobStorage'
])
param kind string = 'StorageV2'

@description('Optional resource tags to apply to the storage account.')
param tags object = {}

resource storageAccount 'Microsoft.Storage/storageAccounts@2023-01-01' = {
	name: name
	location: location
	sku: {
		name: skuName
	}
	kind: kind
	tags: tags
	properties: {
		allowBlobPublicAccess: false
		minimumTlsVersion: 'TLS1_2'
		supportsHttpsTrafficOnly: true
		publicNetworkAccess: 'Enabled'
	}
}

var storageAccountKey = listKeys(storageAccount.id, '2023-01-01').keys[0].value
var connectionString = 'DefaultEndpointsProtocol=https;AccountName=${name};AccountKey=${storageAccountKey};EndpointSuffix=${environment().suffixes.storage}'

output id string = storageAccount.id
output name string = storageAccount.name
output primaryConnectionString string = connectionString
output primaryEndpoints object = storageAccount.properties.primaryEndpoints
