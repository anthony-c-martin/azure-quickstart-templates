@description('Name of the Service Bus namespace')
param serviceBusNamespaceName string

@description('Name of the Virtual Network Rule')
param vnetRuleName string

@description('Name of the Virtual Network Sub Net')
param subnetName string

@description('Azure Resource Manager Id of SubNet')
param virtualNetworkSubnetId string = 'default'

@allowed([
  'East US2'
  'South Central US'
])
@description('Location for Namespace')
param location string = resourceGroup().location

var namespaceVirtualNetworkRuleName_var = '${serviceBusNamespaceName}/${vnetRuleName}'

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

resource namespaceVirtualNetworkRuleName 'Microsoft.ServiceBus/namespaces/VirtualNetworkRules@2018-01-01-preview' = {
  name: namespaceVirtualNetworkRuleName_var
  properties: {
    virtualNetworkSubnetId: resourceId('Microsoft.Network/virtualNetworks/subnets/', vnetRuleName, subnetName)
  }
  dependsOn: [
    serviceBusNamespaceName_resource
  ]
}