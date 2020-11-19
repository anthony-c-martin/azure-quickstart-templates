param existingVNETName string {
  metadata: {
    description: 'Name of the VNET to add a subnet to'
  }
}
param newSubnetName string {
  metadata: {
    description: 'Name of the subnet to add'
  }
}
param newSubnetAddressPrefix string {
  metadata: {
    description: 'Address space of the subnet to add'
  }
  default: '10.0.0.0/24'
}
param location string {
  metadata: {
    description: 'Location for all resources.'
  }
  default: resourceGroup().location
}

resource existingVNETName_newSubnetName 'Microsoft.Network/virtualNetworks/subnets@2019-06-01' = {
  name: '${existingVNETName}/${newSubnetName}'
  location: location
  properties: {
    addressPrefix: newSubnetAddressPrefix
  }
}