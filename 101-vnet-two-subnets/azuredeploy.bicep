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
  default: 'Subnet1'
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
  default: 'Subnet2'
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
  dependsOn: [
    vnetName_res
  ]
}

resource vnetName_subnet2Name 'Microsoft.Network/virtualNetworks/subnets@2020-05-01' = {
  location: location
  name: '${vnetName}/${subnet2Name}'
  properties: {
    addressPrefix: subnet2Prefix
  }
  dependsOn: [
    vnetName_res
    vnetName_subnet1Name
  ]
}