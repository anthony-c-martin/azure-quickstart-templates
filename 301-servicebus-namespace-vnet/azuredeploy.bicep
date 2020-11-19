param serviceBusNamespaceName string {
  metadata: {
    description: 'Name of the Service Bus namespace'
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
param virtualNetworkSubnetId string {
  metadata: {
    description: 'Azure Resource Manager Id of SubNet'
  }
  default: 'default'
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

var namespaceVirtualNetworkRuleName = concat(serviceBusNamespaceName, '/${vnetRuleName}')

resource serviceBusNamespaceName_resource 'Microsoft.ServiceBus/namespaces@2018-01-01-preview' = {
  name: serviceBusNamespaceName
  location: location
  sku: {
    name: 'Premium'
    tier: 'Premium'
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
              service: 'Microsoft.ServiceBus'
            }
          ]
        }
      }
    ]
  }
}

resource namespaceVirtualNetworkRuleName_resource 'Microsoft.ServiceBus/namespaces/VirtualNetworkRules@2018-01-01-preview' = {
  name: namespaceVirtualNetworkRuleName
  properties: {
    virtualNetworkSubnetId: resourceId('Microsoft.Network/virtualNetworks/subnets/', vnetRuleName, subnetName)
  }
  dependsOn: [
    serviceBusNamespaceName_resource
  ]
}