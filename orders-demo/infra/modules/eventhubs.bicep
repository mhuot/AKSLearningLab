// Placeholder for Event Hubs namespace + hub module definition.
targetScope = 'resourceGroup'

@description('Event Hubs namespace name (6-50 characters).')
param namespaceName string

@description('Event Hub entity name.')
param eventHubName string

@description('Azure region for the Event Hubs namespace.')
param location string

@description('Namespace SKU tier (Standard enables Kafka endpoint + autoscale).')
@allowed([
	'Standard'
])
param skuName string = 'Standard'

@description('Throughput unit capacity for the namespace (1-20).')
@minValue(1)
@maxValue(20)
param capacity int = 1

@description('Number of partitions for the Event Hub.')
@minValue(1)
@maxValue(32)
param partitionCount int = 2

@description('Retention period in days for the Event Hub.')
@minValue(1)
@maxValue(7)
param messageRetentionInDays int = 1

@description('Consumer group dedicated to the worker service.')
param consumerGroupName string = 'orders-worker'

@description('Authorization rule used by the API (publish/send).')
param sendRuleName string = 'orders-api'

@description('Authorization rule used by the worker (listen/receive).')
param listenRuleName string = 'orders-worker'

@description('Optional resource tags to apply to the namespace.')
param tags object = {}

var maxThroughputUnits = min(20, max(capacity, capacity * 5))

resource eventHubNamespace 'Microsoft.EventHub/namespaces@2022-10-01-preview' = {
	name: namespaceName
	location: location
	sku: {
		name: skuName
		tier: skuName
		capacity: capacity
	}
	tags: tags
	properties: {
		isAutoInflateEnabled: true
		maximumThroughputUnits: maxThroughputUnits
		kafkaEnabled: true
		zoneRedundant: false
	}
}

resource eventHub 'Microsoft.EventHub/namespaces/eventhubs@2022-10-01-preview' = {
	name: eventHubName
	parent: eventHubNamespace
	properties: {
		messageRetentionInDays: messageRetentionInDays
		partitionCount: partitionCount
	}
}

resource consumerGroup 'Microsoft.EventHub/namespaces/eventhubs/consumergroups@2022-10-01-preview' = {
	name: consumerGroupName
	parent: eventHub
	properties: {}
}

resource sendRule 'Microsoft.EventHub/namespaces/authorizationRules@2022-10-01-preview' = {
	name: sendRuleName
	parent: eventHubNamespace
	properties: {
		rights: [
			'Send'
			'Listen'
		]
	}
}

resource listenRule 'Microsoft.EventHub/namespaces/eventhubs/authorizationRules@2022-10-01-preview' = {
	name: listenRuleName
	parent: eventHub
	properties: {
		rights: [
			'Listen'
		]
	}
}

var sendRuleKeys = listKeys(sendRule.id, '2022-10-01-preview')
var listenRuleKeys = listKeys(listenRule.id, '2022-10-01-preview')

output namespaceId string = eventHubNamespace.id
output namespaceNameOut string = eventHubNamespace.name
output eventHubId string = eventHub.id
output eventHubNameOut string = eventHubName
output consumerGroup string = consumerGroupName
output sendPrimaryConnectionString string = '${sendRuleKeys.primaryConnectionString};EntityPath=${eventHubName}'
output listenPrimaryConnectionString string = '${listenRuleKeys.primaryConnectionString};EntityPath=${eventHubName}'
