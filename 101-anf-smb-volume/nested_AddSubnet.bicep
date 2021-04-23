@description('Name of the existing virtual network')
param virtualNetworkName string

@description('The name of the subnet where the ANF volume will be created. This subnet will be delegated to Microsoft.NetApp/volumes.')
param anfSubnetName string

@description('Same location of resource group for all resources')
param location string

@description('Subnet address range.')
param anfSubnetAddressPrefix string

resource virtualNetworkName_anfSubnetName 'Microsoft.Network/virtualNetworks/subnets@2020-05-01' = {
  name: '${virtualNetworkName}/${anfSubnetName}'
  location: location
  properties: {
    addressPrefix: anfSubnetAddressPrefix
    delegations: [
      {
        name: 'Microsoft.Netapp.volumes'
        properties: {
          serviceName: 'Microsoft.Netapp/volumes'
        }
      }
    ]
  }
}