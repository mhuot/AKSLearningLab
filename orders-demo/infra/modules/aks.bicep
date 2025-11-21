// Placeholder for Azure Kubernetes Service module definition.
targetScope = 'resourceGroup'

@description('Name of the AKS cluster.')
param name string

@description('Azure region for the AKS cluster.')
param location string

@description('DNS prefix for the Kubernetes API server.')
param dnsPrefix string

@description('Kubernetes version to deploy.')
param kubernetesVersion string = '1.28.5'

@description('VM size for the default node pool.')
param agentPoolVMSize string = 'Standard_D4as_v5'

@description('Initial node count for the default system node pool.')
@minValue(1)
param agentPoolNodeCount int = 2

@description('Maximum node count for the default system node pool when autoscaling.')
@minValue(1)
param agentPoolMaxCount int = 5

@description('Admin username for SSH access to AKS nodes.')
param linuxAdminUsername string = 'aksadmin'

@secure()
@description('SSH RSA public key for the admin user.')
param sshRSAPublicKey string

@description('Resource ID of the Log Analytics workspace to attach for monitoring.')
param logAnalyticsWorkspaceResourceId string

@description('Optional resource tags to apply to the AKS cluster.')
param tags object = {}

resource managedCluster 'Microsoft.ContainerService/managedClusters@2023-07-01' = {
	name: name
	location: location
	sku: {
		name: 'Base'
		tier: 'Free'
	}
	identity: {
		type: 'SystemAssigned'
	}
	tags: tags
	properties: {
		dnsPrefix: dnsPrefix
		kubernetesVersion: kubernetesVersion
		enableRBAC: true
		oidcIssuerProfile: {
			enabled: true
		}
		securityProfile: {
			workloadIdentity: {
				enabled: true
			}
		}
		agentPoolProfiles: [
			{
				name: 'systempool'
				count: agentPoolNodeCount
				maxCount: agentPoolMaxCount
				minCount: agentPoolNodeCount
				vmSize: agentPoolVMSize
				osType: 'Linux'
				osSKU: 'Ubuntu'
				mode: 'System'
				type: 'VirtualMachineScaleSets'
				enableAutoScaling: true
			}
		]
		linuxProfile: {
			adminUsername: linuxAdminUsername
			ssh: {
				publicKeys: [
					{
						keyData: sshRSAPublicKey
					}
				]
			}
		}
		addonProfiles: {
			omsagent: {
				enabled: true
				config: {
					logAnalyticsWorkspaceResourceID: logAnalyticsWorkspaceResourceId
				}
			}
		}
		networkProfile: {
			networkPlugin: 'kubenet'
			loadBalancerSku: 'standard'
			outboundType: 'loadBalancer'
			serviceCidr: '10.2.0.0/16'
			dnsServiceIP: '10.2.0.10'
		}
		autoScalerProfile: {
			'scan-interval': '20s'
			'scale-down-delay-after-add': '15m'
			'balance-similar-node-groups': 'true'
		}
	}
}

output id string = managedCluster.id
output name string = managedCluster.name
output fqdn string = managedCluster.properties.fqdn
output principalId string = managedCluster.identity.principalId
output kubeletPrincipalId string = managedCluster.properties.identityProfile['kubeletidentity'].objectId
output oidcIssuerUrl string = managedCluster.properties.oidcIssuerProfile.issuerURL
output nodeResourceGroup string = managedCluster.properties.nodeResourceGroup
