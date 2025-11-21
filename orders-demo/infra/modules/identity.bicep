targetScope = 'resourceGroup'

@description('Name of the user-assigned managed identity.')
param identityName string

@description('Azure region for the managed identity.')
param location string

@description('Optional resource tags to apply to the managed identity.')
param tags object = {}

resource workloadIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31' = {
	name: identityName
	location: location
	tags: tags
}

output id string = workloadIdentity.id
output clientId string = workloadIdentity.properties.clientId
output principalId string = workloadIdentity.properties.principalId
output name string = workloadIdentity.name
