@description('Name of the existing VNET to inject Cloud Shell into.')
param existingVNETName string

@description('Name of Azure Relay Namespace.')
param relayNamespaceName string

@description('Object Id of Azure Container Instance Service Principal. We have to grant this permission to create hybrid connections in the Azure Relay you specify. To get it - Get-AzADServicePrincipal -DisplayNameBeginsWith \'Azure Container Instance\'')
param azureContainerInstanceOID string

@description('Name of the subnet to use for cloud shell containers.')
param containerSubnetName string = 'cloudshellsubnet'

@description('Address space of the subnet to add for cloud shell. e.g. 10.0.1.0/26')
param containerSubnetAddressPrefix string

@description('Name of the subnet to use for private link of relay namespace.')
param relaySubnetName string = 'relaysubnet'

@description('Address space of the subnet to add for relay. e.g. 10.0.2.0/26')
param relaySubnetAddressPrefix string

@description('Name of the subnet to use for storage account.')
param storageSubnetName string = 'storagesubnet'

@description('Address space of the subnet to add for storage. e.g. 10.0.3.0/26')
param storageSubnetAddressPrefix string

@description('Name of Private Endpoint for Azure Relay.')
param privateEndpointName string = 'cloudshellRelayEndpoint'

@description('Location for all resources.')
param location string = resourceGroup().location

var networkProfileName_var = 'aci-networkProfile-${location}'
var networkProfileRef = networkProfileName.id
var containerSubnetRef = existingVNETName_containerSubnetName.id
var relayNamespaceRef = relayNamespaceName_resource.id
var relaySubnetRef = existingVNETName_relaySubnetName.id
var contributorRoleDefinitionId = resourceId('Microsoft.Authorization/roleDefinitions', 'b24988ac-6180-42a0-ab88-20f7382dd24c')
var networkRoleDefinitionId = resourceId('Microsoft.Authorization/roleDefinitions', '4d97b98b-1d4f-4787-a291-c67834d212e7')
var privateDnsZoneName_var = ((toLower(environment().name) == 'azureusgovernment') ? 'privatelink.servicebus.usgovcloudapi.net' : 'privatelink.servicebus.windows.net')
var networkRef = resourceId('Microsoft.Network/virtualNetworks', existingVNETName)
var privateEndpointRef = privateEndpointName_resource.id

resource existingVNETName_containerSubnetName 'Microsoft.Network/virtualNetworks/subnets@2020-04-01' = {
  name: '${existingVNETName}/${containerSubnetName}'
  location: location
  properties: {
    addressPrefix: containerSubnetAddressPrefix
    serviceEndpoints: [
      {
        service: 'Microsoft.Storage'
        locations: [
          location
        ]
      }
    ]
    delegations: [
      {
        name: 'CloudShellDelegation'
        properties: {
          serviceName: 'Microsoft.ContainerInstance/containerGroups'
        }
      }
    ]
  }
}

resource networkProfileName 'Microsoft.Network/networkProfiles@2019-11-01' = {
  name: networkProfileName_var
  location: location
  properties: {
    containerNetworkInterfaceConfigurations: [
      {
        name: 'eth-${containerSubnetName}'
        properties: {
          ipConfigurations: [
            {
              name: 'ipconfig-${containerSubnetName}'
              properties: {
                subnet: {
                  id: containerSubnetRef
                }
              }
            }
          ]
        }
      }
    ]
  }
  dependsOn: [
    containerSubnetRef
  ]
}

resource networkProfileName_Microsoft_Authorization_networkRoleDefinitionId_azureContainerInstanceOID_networkProfileName 'Microsoft.Network/networkProfiles/providers/roleAssignments@2018-09-01-preview' = {
  name: '${networkProfileName_var}/Microsoft.Authorization/${guid(networkRoleDefinitionId, azureContainerInstanceOID, networkProfileName_var)}'
  properties: {
    roleDefinitionId: networkRoleDefinitionId
    principalId: azureContainerInstanceOID
    scope: networkProfileRef
  }
  dependsOn: [
    networkProfileRef
  ]
}

resource relayNamespaceName_resource 'Microsoft.Relay/namespaces@2018-01-01-preview' = {
  name: relayNamespaceName
  location: location
  sku: {
    name: 'Standard'
    tier: 'Standard'
  }
}

resource relayNamespaceName_Microsoft_Authorization_contributorRoleDefinitionId_azureContainerInstanceOID_relayNamespaceName 'Microsoft.Relay/namespaces/providers/roleAssignments@2018-09-01-preview' = {
  name: '${relayNamespaceName}/Microsoft.Authorization/${guid(contributorRoleDefinitionId, azureContainerInstanceOID, relayNamespaceName)}'
  properties: {
    roleDefinitionId: contributorRoleDefinitionId
    principalId: azureContainerInstanceOID
    scope: relayNamespaceRef
  }
  dependsOn: [
    relayNamespaceRef
  ]
}

resource existingVNETName_relaySubnetName 'Microsoft.Network/virtualNetworks/subnets@2020-04-01' = {
  name: '${existingVNETName}/${relaySubnetName}'
  location: location
  properties: {
    addressPrefix: relaySubnetAddressPrefix
    privateEndpointNetworkPolicies: 'Disabled'
    privateLinkServiceNetworkPolicies: 'Enabled'
  }
  dependsOn: [
    containerSubnetRef
  ]
}

resource privateEndpointName_resource 'Microsoft.Network/privateEndpoints@2020-04-01' = {
  name: privateEndpointName
  location: location
  properties: {
    privateLinkServiceConnections: [
      {
        name: privateEndpointName
        properties: {
          privateLinkServiceId: relayNamespaceRef
          groupIds: [
            'namespace'
          ]
        }
      }
    ]
    subnet: {
      id: relaySubnetRef
    }
  }
  dependsOn: [
    relaySubnetRef
    relayNamespaceRef
  ]
}

resource existingVNETName_storageSubnetName 'Microsoft.Network/virtualNetworks/subnets@2020-04-01' = {
  name: '${existingVNETName}/${storageSubnetName}'
  location: location
  properties: {
    addressPrefix: storageSubnetAddressPrefix
    serviceEndpoints: [
      {
        service: 'Microsoft.Storage'
        locations: [
          location
        ]
      }
    ]
  }
  dependsOn: [
    relaySubnetRef
  ]
}

resource privateDnsZoneName 'Microsoft.Network/privateDnsZones@2020-01-01' = {
  name: privateDnsZoneName_var
  location: 'global'
  properties: {
    maxNumberOfRecordSets: 25000
    maxNumberOfVirtualNetworkLinks: 1000
    maxNumberOfVirtualNetworkLinksWithRegistration: 100
    numberOfRecordSets: 2
    numberOfVirtualNetworkLinks: 1
    numberOfVirtualNetworkLinksWithRegistration: 0
  }
}

resource privateDnsZoneName_relayNamespaceName 'Microsoft.Network/privateDnsZones/A@2020-01-01' = {
  parent: privateDnsZoneName
  name: '${relayNamespaceName}'
  properties: {
    ttl: 3600
    aRecords: [
      {
        ipv4Address: first(first(reference(privateEndpointName, '2020-04-01', 'Full').properties.customDnsConfigs).ipAddresses)
      }
    ]
  }
  dependsOn: [
    privateEndpointRef
  ]
}

resource Microsoft_Network_privateDnsZones_virtualNetworkLinks_privateDnsZoneName_relayNamespaceName 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2020-01-01' = {
  parent: privateDnsZoneName
  name: '${relayNamespaceName}'
  location: 'global'
  properties: {
    registrationEnabled: false
    virtualNetwork: {
      id: networkRef
    }
  }
}

output vnetName string = existingVNETName
output containerSubnetName string = containerSubnetName
output storageSubnetName string = storageSubnetName