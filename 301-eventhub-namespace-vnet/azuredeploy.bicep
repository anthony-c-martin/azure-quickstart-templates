param eventhubNamespaceName string {
  metadata: {
    description: 'Name of the Event Hubs namespace'
  }
}
param vnetRuleName string {
  metadata: {
    description: 'Name of the Virtual Network Rule'
  }
}
param subnetName string {
  metadata: {
    description: 'Name of the Virtual Network Sub Net'
  }
}
param location string {
  allowed: [
    'East US2'
    'South Central US'
  ]
  metadata: {
    description: 'Location for Namespace'
  }
  default: resourceGroup().location
}

var namespaceVirtualNetworkRuleName = concat(eventhubNamespaceName, '/${vnetRuleName}')
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

resource namespaceVirtualNetworkRuleName_resource 'Microsoft.EventHub/namespaces/VirtualNetworkRules@2018-01-01-preview' = {
  name: namespaceVirtualNetworkRuleName
  properties: {
    virtualNetworkSubnetId: subNetId
  }
  dependsOn: [
    eventhubNamespaceName_resource
  ]
}