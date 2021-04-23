@description('Name of the Event Hubs namespace')
param eventhubNamespaceName string

@description('Name of the Virtual Network Rule')
param vnetRuleName string

@description('Name of the Virtual Network Sub Net')
param subnetName string

@allowed([
  'East US2'
  'South Central US'
])
@description('Location for Namespace')
param location string = resourceGroup().location

var namespaceVirtualNetworkRuleName_var = '${eventhubNamespaceName}/${vnetRuleName}'
var subNetId = resourceId('Microsoft.Network/virtualNetworks/subnets/', vnetRuleName, subnetName)

resource eventhubNamespaceName_resource 'Microsoft.EventHub/namespaces@2018-01-01-preview' = {
  name: eventhubNamespaceName
  location: location
  sku: {
    name: 'Standard'
    tier: 'Standard'
  }
  properties: {}
}

resource vnetRuleName_resource 'Microsoft.Network/virtualNetworks@2017-09-01' = {
  name: vnetRuleName
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        '10.0.0.0/23'
      ]
    }
    subnets: [
      {
        name: subnetName
        properties: {
          addressPrefix: '10.0.0.0/23'
          serviceEndpoints: [
            {
              service: 'Microsoft.EventHub'
            }
          ]
        }
      }
    ]
  }
}

resource namespaceVirtualNetworkRuleName 'Microsoft.EventHub/namespaces/VirtualNetworkRules@2018-01-01-preview' = {
  name: namespaceVirtualNetworkRuleName_var
  properties: {
    virtualNetworkSubnetId: subNetId
  }
  dependsOn: [
    eventhubNamespaceName_resource
  ]
}