param nicName string
param publicIPAddressId string
param subnetId string

@allowed([
  'Dynamic'
  'Static'
])
param privateIPAllocationMethod string = 'Dynamic'
param location string
param nsgId string = ''
param tags object

resource nicName_resource 'Microsoft.Network/networkInterfaces@2018-06-01' = {
  name: nicName
  location: location
  tags: tags
  properties: {
    networkSecurityGroup: {
      id: nsgId
    }
    ipConfigurations: [
      {
        name: 'ipconfig'
        properties: {
          privateIPAllocationMethod: privateIPAllocationMethod
          publicIPAddress: {
            id: publicIPAddressId
          }
          subnet: {
            id: subnetId
          }
        }
      }
    ]
  }
}