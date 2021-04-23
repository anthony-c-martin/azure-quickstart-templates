@description('Name of the VNET to add a subnet to')
param existingVNETName string

@description('Name of the subnet to add')
param newSubnetName string

@description('Address space of the subnet to add')
param newSubnetAddressPrefix string = '10.0.0.0/24'

@description('Location for all resources.')
param location string = resourceGroup().location

resource existingVNETName_newSubnetName 'Microsoft.Network/virtualNetworks/subnets@2019-06-01' = {
  name: '${existingVNETName}/${newSubnetName}'
  location: location
  properties: {
    addressPrefix: newSubnetAddressPrefix
  }
}