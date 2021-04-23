@description('The name of the Integration Service Environment.')
param integrationServiceEnvironmentName string

@description('Location for all resources.')
param location string = resourceGroup().location

@allowed([
  'Developer'
  'Premium'
])
@description('The SKU for the Integration Service Environment, either Developer or Premium.')
param integrationServiceEnvironmentSku string = 'Developer'

@description('The number of scale units for the Integration Service Environment. 0 is the base unit.')
param skuCapacity int = 0

@allowed([
  'Internal'
  'External'
])
@description('The type of access endpoint to use for the Integration Service Environment. The endpoint determine whether request or webhook triggers on logic apps in the Integration Service Environment can receive calls from outside the virtual network.')
param accessEndpointType string = 'External'

@description('The list of managed connectors to deploy into the ISE in JSON array format (e.g. ["sql", "ftp" ...]). The values must be from this list: sql;ftp;azureblob;azurefile;azurequeues;azuretables;sftpwithssh;edifact;x12;servicebus;documentdb;eventhubs;mq;sqldw;db2;smtp;si3270')
param managedConnectors array

@description('The name of the VNET for ISE to be deployed into.')
param vnetName string

@description('The VNET address prefix. For example, 10.0.0.0/22.')
param vnetAddressPrefix string = '10.0.0.0/22'

@description('The prefix for the first ISE subnet. For example, 10.0.1.0/26.')
param subnet1Prefix string = '10.0.1.0/26'

@description('The name of the first ISE subnet.')
param subnet1Name string = 'Subnet1'

@description('The prefix for the second ISE subnet. For example, 10.0.1.64/26.')
param subnet2Prefix string = '10.0.1.64/26'

@description('The name of the second ISE subnet.')
param subnet2Name string = 'Subnet2'

@description('The prefix for the third ISE subnet. For example, 10.0.1.128/26.')
param subnet3Prefix string = '10.0.1.128/26'

@description('The name of the third ISE subnet.')
param subnet3Name string = 'Subnet3'

@description('The prefix for the fourth ISE subnet. For example, 10.0.1.192/26.')
param subnet4Prefix string = '10.0.1.192/26'

@description('The name of the fourth ISE subnet.')
param subnet4Name string = 'Subnet4'

@description('After the first deployment, you don\'t need to recreate the VNET. When set to false this will skip the VNET and subnet deployment.')
param rebuildVNET bool = true

resource vnetName_resource 'Microsoft.Network/virtualNetworks@2020-05-01' = if (rebuildVNET) {
  name: vnetName
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        vnetAddressPrefix
      ]
    }
  }
}

resource vnetName_subnet1Name 'Microsoft.Network/virtualNetworks/subnets@2020-05-01' = if (rebuildVNET) {
  parent: vnetName_resource
  location: location
  name: '${subnet1Name}'
  properties: {
    addressPrefix: subnet1Prefix
    delegations: [
      {
        name: 'integrationServiceEnvironments'
        properties: {
          serviceName: 'Microsoft.Logic/integrationServiceEnvironments'
        }
      }
    ]
  }
}

resource vnetName_subnet2Name 'Microsoft.Network/virtualNetworks/subnets@2020-05-01' = if (rebuildVNET) {
  parent: vnetName_resource
  location: location
  name: '${subnet2Name}'
  properties: {
    addressPrefix: subnet2Prefix
  }
  dependsOn: [
    vnetName_subnet1Name
  ]
}

resource vnetName_subnet3Name 'Microsoft.Network/virtualNetworks/subnets@2020-05-01' = if (rebuildVNET) {
  parent: vnetName_resource
  location: location
  name: '${subnet3Name}'
  properties: {
    addressPrefix: subnet3Prefix
  }
  dependsOn: [
    vnetName_subnet2Name
  ]
}

resource vnetName_subnet4Name 'Microsoft.Network/virtualNetworks/subnets@2020-05-01' = if (rebuildVNET) {
  parent: vnetName_resource
  location: location
  name: '${subnet4Name}'
  properties: {
    addressPrefix: subnet4Prefix
  }
  dependsOn: [
    vnetName_subnet3Name
  ]
}

resource integrationServiceEnvironmentName_resource 'Microsoft.Logic/integrationServiceEnvironments@2019-05-01' = {
  name: integrationServiceEnvironmentName
  location: location
  sku: {
    name: integrationServiceEnvironmentSku
    capacity: skuCapacity
  }
  properties: {
    networkConfiguration: {
      accessEndpoint: {
        type: accessEndpointType
      }
      subnets: [
        {
          id: vnetName_subnet1Name.id
        }
        {
          id: vnetName_subnet2Name.id
        }
        {
          id: vnetName_subnet3Name.id
        }
        {
          id: vnetName_subnet4Name.id
        }
      ]
    }
  }
  dependsOn: [
    vnetName_resource
  ]
}

resource integrationServiceEnvironmentName_managedConnectors 'Microsoft.Logic/integrationServiceEnvironments/ManagedApis@2019-05-01' = [for item in managedConnectors: {
  name: '${integrationServiceEnvironmentName}/${item}'
  location: location
  properties: {}
  dependsOn: [
    integrationServiceEnvironmentName_resource
  ]
}]