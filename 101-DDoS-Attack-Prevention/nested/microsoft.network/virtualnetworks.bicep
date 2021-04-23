param vnetName string
param location string
param addressPrefix string
param subnets array
param tags object

resource vnetName_resource 'Microsoft.Network/virtualNetworks@2018-06-01' = {
  name: vnetName
  location: location
  tags: tags
  properties: {
    addressSpace: {
      addressPrefixes: [
        addressPrefix
      ]
    }
    subnets: subnets
  }
}