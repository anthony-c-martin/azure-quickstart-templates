@description('The name of the Managed Cluster resource.')
param resourceName string = 'aksadcluster'

@description('The Azure location of the AKS resource.')
param location string = resourceGroup().location

@description('Optional DNS prefix to use with hosted Kubernetes API server FQDN.')
param dnsPrefix string = 'aksadcluster'

@minValue(0)
@maxValue(1023)
@description('Disk size (in GB) to provision for each of the agent pool nodes. This value ranges from 0 to 1023. Specifying 0 will apply the default disk size for that agentVMSize.')
param osDiskSizeGB int = 500

@minValue(1)
@maxValue(50)
@description('The number of agent nodes for the cluster. Production workloads have a recommended minimum of 3.')
param agentCount int = 3

@description('The size of the Virtual Machine.')
param agentVMSize string = 'Standard_D2_v2'

@description('Oject ID against which the Network Contributor roles will be assigned on the subnet')
@secure()
param existingServicePrincipalObjectId string

@description('Client ID (used by cloudprovider)')
@secure()
param existingServicePrincipalClientId string

@description('The Service Principal Client Secret.')
@secure()
param existingServicePrincipalClientSecret string

@allowed([
  'Linux'
])
@description('The type of operating system.')
param osType string = 'Linux'

@description('The version of Kubernetes.')
param kubernetesVersion string = '1.12.6'

@description('boolean flag to turn on and off of http application routing')
param enableHttpApplicationRouting bool = false

@allowed([
  'azure'
  'kubenet'
])
@description('Network plugin used for building Kubernetes network.')
param networkPlugin string = 'azure'

@description('Maximum number of pods that can run on a node.')
param maxPods int = 30

@description('boolean flag to turn on and off of RBAC')
param enableRBAC bool = true

@description('Name of an existing VNET that will contain this AKS deployment.')
param existingVirtualNetworkName string

@description('Name of the existing VNET resource group')
param existingVirtualNetworkResourceGroup string

@description('Subnet name that will contain the App Service Environment')
param existingSubnetName string

@description('Name of the Role Assignment created for the Service Principal in the existing Subnet')
param existingSubnetRoleAssignmentName string = newGuid()

@description('A CIDR notation IP range from which to assign service cluster IPs.')
param serviceCidr string = '10.0.0.0/16'

@description('Containers DNS server IP address.')
param dnsServiceIP string = '10.0.0.10'

@description('A CIDR notation IP for Docker bridge.')
param dockerBridgeCidr string = '172.17.0.1/16'

@description('The Application ID for the Client App Service Principal')
@secure()
param AAD_ClientAppID string

@description('The Application ID for the Server App Service Principal')
@secure()
param AAD_ServerAppID string

@description('The Azure AD Tenant where the cluster will reside')
@secure()
param AAD_TenantID string

@description('The Service Principal Secret for the Client App Service Principal')
@secure()
param AAD_ServerAppSecret string

var vnetSubnetId = resourceId(existingVirtualNetworkResourceGroup, 'Microsoft.Network/virtualNetworks/subnets', existingVirtualNetworkName, existingSubnetName)

resource resourceName_resource 'Microsoft.ContainerService/managedClusters@2018-03-31' = {
  name: resourceName
  location: location
  properties: {
    kubernetesVersion: kubernetesVersion
    enableRBAC: enableRBAC
    dnsPrefix: dnsPrefix
    aadProfile: {
      clientAppID: AAD_ClientAppID
      serverAppID: AAD_ServerAppID
      tenantID: AAD_TenantID
      serverAppSecret: AAD_ServerAppSecret
    }
    addonProfiles: {
      httpApplicationRouting: {
        enabled: enableHttpApplicationRouting
      }
    }
    agentPoolProfiles: [
      {
        name: 'agentpool'
        osDiskSizeGB: osDiskSizeGB
        count: agentCount
        vmSize: agentVMSize
        osType: osType
        storageProfile: 'ManagedDisks'
        vnetSubnetID: vnetSubnetId
        maxPods: maxPods
      }
    ]
    servicePrincipalProfile: {
      clientId: existingServicePrincipalClientId
      secret: existingServicePrincipalClientSecret
    }
    networkProfile: {
      networkPlugin: networkPlugin
      serviceCidr: serviceCidr
      dnsServiceIP: dnsServiceIP
      dockerBridgeCidr: dockerBridgeCidr
    }
  }
  dependsOn: [
    ClusterSubnetRoleAssignmentDeployment
  ]
}

module ClusterSubnetRoleAssignmentDeployment './nested_ClusterSubnetRoleAssignmentDeployment.bicep' = {
  name: 'ClusterSubnetRoleAssignmentDeployment'
  scope: resourceGroup(existingVirtualNetworkResourceGroup)
  params: {
    variables_vnetSubnetId: vnetSubnetId
    existingSubnetRoleAssignmentName: existingSubnetRoleAssignmentName
    existingServicePrincipalObjectId: existingServicePrincipalObjectId
  }
}

output controlPlaneFQDN string = reference('Microsoft.ContainerService/managedClusters/${resourceName}').fqdn