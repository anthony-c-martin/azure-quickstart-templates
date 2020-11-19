param privateDnsZoneName string {
  metadata: {
    description: 'Private DNS zone name'
  }
  default: 'contoso.com'
}
param vmRegistration bool {
  metadata: {
    description: 'Enable automatic VM DNS registration in the zone'
  }
  default: true
}
param vnetName string {
  metadata: {
    description: 'VNet name'
  }
  default: 'VNet1'
}
param vnetAddressPrefix string {
  metadata: {
    description: 'Address prefix'
  }
  default: '10.0.0.0/16'
}
param subnet1Prefix string {
  metadata: {
    description: 'Subnet 1 Prefix'
  }
  default: '10.0.0.0/24'
}
param subnet1Name string {
  metadata: {
    description: 'Subnet 1 Name'
  }
  default: 'App'
}
param subnet2Prefix string {
  metadata: {
    description: 'Subnet 2 Prefix'
  }
  default: '10.0.1.0/24'
}
param subnet2Name string {
  metadata: {
    description: 'Subnet 2 Name'
  }
  default: 'Utility'
}
param location string {
  metadata: {
    description: 'Location for all resources.'
  }
  default: resourceGroup().location
}

resource vnetName_res 'Microsoft.Network/virtualNetworks@2020-05-01' = {
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
  location: location
  name: '${vnetName}/${subnet1Name}'
  properties: {
    addressPrefix: subnet1Prefix
  }
}

resource vnetName_subnet2Name 'Microsoft.Network/virtualNetworks/subnets@2020-05-01' = {
  location: location
  name: '${vnetName}/${subnet2Name}'
  properties: {
    addressPrefix: subnet2Prefix
  }
}

resource privateDnsZoneName_res 'Microsoft.Network/privateDnsZones@2020-01-01' = {
  name: privateDnsZoneName
  location: 'global'
}

resource privateDnsZoneName_privateDnsZoneName_link 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2020-01-01' = {
  name: '${privateDnsZoneName}/${privateDnsZoneName}-link'
  location: 'global'
  properties: {
    registrationEnabled: vmRegistration
    virtualNetwork: {
      id: vnetName_res.id
    }
  }
}