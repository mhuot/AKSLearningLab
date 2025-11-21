targetScope = 'resourceGroup'

@description('Name of the Azure Container Registry.')
param acrName string

@description('Name of the Event Hubs namespace.')
param eventHubNamespaceName string

@description('Name of the storage account used for checkpoints.')
param storageAccountName string

@description('Principal ID of the AKS kubelet identity.')
param aksKubeletPrincipalId string

@description('Principal ID of the user-assigned identity used by workloads.')
param workloadIdentityPrincipalId string

// Existing resources resolved by name within the current resource group scope.
resource acr 'Microsoft.ContainerRegistry/registries@2023-07-01' existing = {
	name: acrName
}

resource eventHubNamespace 'Microsoft.EventHub/namespaces@2022-10-01-preview' existing = {
	name: eventHubNamespaceName
}

resource storageAccount 'Microsoft.Storage/storageAccounts@2023-01-01' existing = {
	name: storageAccountName
}

// Role definition IDs
var acrPullRoleDefinitionId = subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '7f951dda-4ed3-4680-a7ca-43fe172d538d')
var eventHubSendRoleDefinitionId = subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '5c86776b-8d61-47b0-8337-d527f03c46d8')
var eventHubListenRoleDefinitionId = subscriptionResourceId('Microsoft.Authorization/roleDefinitions', 'a638d3c7-ab3a-418d-83e6-5f17a39d4fde')
var storageBlobContributorRoleDefinitionId = subscriptionResourceId('Microsoft.Authorization/roleDefinitions', 'ba92f5b4-2d11-453d-a403-e96b0029c9fe')

resource acrPullAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
	name: guid(acr.id, aksKubeletPrincipalId, acrPullRoleDefinitionId)
	scope: acr
	properties: {
		roleDefinitionId: acrPullRoleDefinitionId
		principalId: aksKubeletPrincipalId
		principalType: 'ServicePrincipal'
	}
}

resource eventHubSenderAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
	name: guid(eventHubNamespace.id, workloadIdentityPrincipalId, eventHubSendRoleDefinitionId)
	scope: eventHubNamespace
	properties: {
		roleDefinitionId: eventHubSendRoleDefinitionId
		principalId: workloadIdentityPrincipalId
		principalType: 'ServicePrincipal'
	}
}

resource eventHubListenerAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
	name: guid('${eventHubNamespace.id}/listen', workloadIdentityPrincipalId, eventHubListenRoleDefinitionId)
	scope: eventHubNamespace
	properties: {
		roleDefinitionId: eventHubListenRoleDefinitionId
		principalId: workloadIdentityPrincipalId
		principalType: 'ServicePrincipal'
	}
}

resource storageContributorAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
	name: guid(storageAccount.id, workloadIdentityPrincipalId, storageBlobContributorRoleDefinitionId)
	scope: storageAccount
	properties: {
		roleDefinitionId: storageBlobContributorRoleDefinitionId
		principalId: workloadIdentityPrincipalId
		principalType: 'ServicePrincipal'
	}
}
