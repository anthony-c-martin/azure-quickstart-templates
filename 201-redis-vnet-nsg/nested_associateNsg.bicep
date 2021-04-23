param reference_variables_subnetId_2020_05_01_addressPrefix object
param resourceId_Microsoft_Network_networkSecurityGroups_parameters_newNsgName string

@description('The name of the existing Virtual Network.')
param existingVirtualNetworkName string

@description('The name of the existing subnet.')
param existingSubnetName string

@description('The location of the existing Virtual Network and new Network Security Group.')
param location string

resource existingVirtualNetworkName_existingSubnetName 'Microsoft.Network/virtualNetworks/subnets@2020-05-01' = {
  name: '${existingVirtualNetworkName}/${existingSubnetName}'
  location: location
  properties: {
    addressPrefix: reference_variables_subnetId_2020_05_01_addressPrefix.addressPrefix
    networkSecurityGroup: {
      id: resourceId_Microsoft_Network_networkSecurityGroups_parameters_newNsgName
    }
  }
}