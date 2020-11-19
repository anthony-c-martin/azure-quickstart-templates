param clusterName string = 'kusto${uniqueString(resourceGroup().id)}'
param dataManagementPublicIpName string = 'dm-pip'
param enginePublicIpName string = 'engine-pip'
param location string {
  metadata: {
    description: 'Location for all resources.'
  }
  default: resourceGroup().location
}
param skuName string = 'Standard_D13_v2'
param skuTier string = 'Standard'
param subnetName string = 'subnet'
param virtualNetworkName string = 'vnet'

var dataManagementPublicIpId = dataManagementPublicIpName_resource.id
var enginePublicIpId = enginePublicIpName_resource.id
var nsgId = nsgName_resource.id
var nsgName = 'azureDataExplorerNsg'
var publicIpAllocationMethod = 'Static'
var subnetId = resourceId('Microsoft.Network/virtualNetworks/subnets', virtualNetworkName, subnetName)
var vnetId = virtualNetworkName_resource.id

resource clusterName_resource 'Microsoft.Kusto/Clusters@2020-06-14' = {
  sku: {
    name: skuName
    tier: skuTier
  }
  name: clusterName
  location: location
  properties: {
    virtualNetworkConfiguration: {
      subnetId: subnetId
      enginePublicIpId: enginePublicIpId
      dataManagementPublicIpId: dataManagementPublicIpId
    }
  }
  dependsOn: [
    enginePublicIpId
    dataManagementPublicIpId
    vnetId
  ]
}

resource dataManagementPublicIpName_resource 'Microsoft.Network/publicIPAddresses@2020-05-01' = {
  name: dataManagementPublicIpName
  sku: {
    name: 'Standard'
  }
  location: location
  properties: {
    publicIPAllocationMethod: publicIpAllocationMethod
    publicIPAddressVersion: 'IPv4'
  }
}

resource enginePublicIpName_resource 'Microsoft.Network/publicIPAddresses@2020-05-01' = {
  name: enginePublicIpName
  sku: {
    name: 'Standard'
  }
  location: location
  properties: {
    publicIPAllocationMethod: publicIpAllocationMethod
    publicIPAddressVersion: 'IPv4'
  }
}

resource virtualNetworkName_resource 'Microsoft.Network/virtualNetworks@2020-05-01' = {
  name: virtualNetworkName
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        '10.0.0.0/16'
      ]
    }
    subnets: [
      {
        name: subnetName
        properties: {
          addressPrefix: '10.0.0.0/20'
          networkSecurityGroup: {
            id: nsgId
          }
        }
      }
    ]
  }
  dependsOn: [
    nsgId
  ]
}

resource nsgName_resource 'Microsoft.Network/networkSecurityGroups@2019-07-01' = {
  name: nsgName
  location: location
  properties: {
    securityRules: [
      {
        name: 'AllowHTTPS'
        properties: {
          description: 'Allow access using HTTPS'
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '443'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: '*'
          access: 'Allow'
          priority: 100
          direction: 'Inbound'
        }
      }
    ]
  }
}