@description('Private DNS zone name')
param privateDnsZoneName string = 'contoso.com'

@description('Enable automatic VM DNS registration in the zone')
param vmRegistration bool = true

@description('VNet name')
param vnetName string = 'VNet1'

@description('Address prefix')
param vnetAddressPrefix string = '10.0.0.0/16'

@description('Subnet 1 Prefix')
param subnet1Prefix string = '10.0.0.0/24'

@description('Subnet 1 Name')
param subnet1Name string = 'App'

@description('Subnet 2 Prefix')
param subnet2Prefix string = '10.0.1.0/24'

@description('Subnet 2 Name')
param subnet2Name string = 'Utility'

@description('Location for all resources.')
param location string = resourceGroup().location

resource vnetName_resource 'Microsoft.Network/virtualNetworks@2020-05-01' = {
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

resource vnetName_subnet1Name 'Microsoft.Network/virtualNetworks/subnets@2020-05-01' = {
  parent: vnetName_resource
  location: location
  name: '${subnet1Name}'
  properties: {
    addressPrefix: subnet1Prefix
  }
}

resource vnetName_subnet2Name 'Microsoft.Network/virtualNetworks/subnets@2020-05-01' = {
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

resource privateDnsZoneName_resource 'Microsoft.Network/privateDnsZones@2020-01-01' = {
  name: privateDnsZoneName
  location: 'global'
}

resource privateDnsZoneName_privateDnsZoneName_link 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2020-01-01' = {
  parent: privateDnsZoneName_resource
  name: '${privateDnsZoneName}-link'
  location: 'global'
  properties: {
    registrationEnabled: vmRegistration
    virtualNetwork: {
      id: vnetName_resource.id
    }
  }
}