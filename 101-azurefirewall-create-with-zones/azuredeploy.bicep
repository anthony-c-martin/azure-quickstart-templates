@description('Virtual network name')
param virtualNetworkName string = 'test-vnet'

@description('Virtual network address range')
param vnetAddressPrefix string = '10.0.0.0/16'

@description('AzureFirewallSubnet prefix')
param azureFirewallSubnetAddressPrefix string = '10.0.1.0/24'

@description('Azure Firewall name')
param firewallName string = 'firewall1'

@description('Number of public IP addresses')
param numberOfPublicIPAddresses int = 1

@description('Public IP address name prefix - will be auto suffixed with a number (e.g. publicIP1)')
param publicIPNamePrefix string = 'publicIP'

@description('Location for all resources. Only certain regions support zones.')
param location string = resourceGroup().location

@description('Zone numbers e.g. 1,2,3.')
param availabilityZones array = [
  '1'
  '2'
  '3'
]

var azureFirewallSubnetName = 'AzureFirewallSubnet'
var azureFirewallSubnetId = resourceId('Microsoft.Network/virtualNetworks/subnets', virtualNetworkName, azureFirewallSubnetName)
var azureFirewallSubnetJSON = json('{{"id": "${azureFirewallSubnetId}"}}')
var azureFirewallIpConfigurations = [for i in range(0, numberOfPublicIPAddresses): {
  name: 'IpConf${i}'
  properties: {
    subnet: ((i == 0) ? azureFirewallSubnetJSON : json('null'))
    publicIPAddress: {
      id: resourceId('Microsoft.Network/publicIPAddresses', concat(publicIPNamePrefix, (i + 1)))
    }
  }
}]

resource virtualNetworkName_resource 'Microsoft.Network/virtualNetworks@2020-05-01' = {
  name: virtualNetworkName
  location: location
  tags: {
    displayName: virtualNetworkName
  }
  properties: {
    addressSpace: {
      addressPrefixes: [
        vnetAddressPrefix
      ]
    }
    subnets: [
      {
        name: azureFirewallSubnetName
        properties: {
          addressPrefix: azureFirewallSubnetAddressPrefix
        }
      }
    ]
  }
}

resource publicIPNamePrefix_1 'Microsoft.Network/publicIPAddresses@2020-05-01' = [for i in range(0, numberOfPublicIPAddresses): {
  name: concat(publicIPNamePrefix, (i + 1))
  location: location
  sku: {
    name: 'Standard'
  }
  properties: {
    publicIPAllocationMethod: 'Static'
    publicIPAddressVersion: 'IPv4'
  }
}]

resource firewallName_resource 'Microsoft.Network/azureFirewalls@2020-05-01' = {
  name: firewallName
  location: location
  zones: ((length(availabilityZones) == 0) ? json('null') : availabilityZones)
  properties: {
    ipConfigurations: azureFirewallIpConfigurations
    applicationRuleCollections: [
      {
        name: 'appRc1'
        properties: {
          priority: 101
          action: {
            type: 'Allow'
          }
          rules: [
            {
              name: 'appRule1'
              protocols: [
                {
                  port: 80
                  protocolType: 'Http'
                }
              ]
              targetFqdns: [
                'www.microsoft.com'
              ]
              sourceAddresses: [
                '10.0.0.0/24'
              ]
            }
          ]
        }
      }
    ]
    networkRuleCollections: [
      {
        name: 'netRc1'
        properties: {
          priority: 200
          action: {
            type: 'Allow'
          }
          rules: [
            {
              name: 'netRule1'
              protocols: [
                'TCP'
              ]
              sourceAddresses: [
                '10.0.0.0/24'
              ]
              destinationAddresses: [
                '*'
              ]
              destinationPorts: [
                '8000-8999'
              ]
            }
          ]
        }
      }
    ]
  }
  dependsOn: [
    virtualNetworkName_resource
    publicIPNamePrefix_1
  ]
}