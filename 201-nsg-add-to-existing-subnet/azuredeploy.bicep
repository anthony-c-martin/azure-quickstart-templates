@description('The resource group where the existing VNet is located.')
param virtualNetworkResourceGroupName string

@description('The name of the existing VNet')
param virtualNetworkName string

@description('The name of the existing subnet.')
param subnetName string = 'default'

@description('Location for all resources')
param location string = resourceGroup().location

@description('The base URI where artifacts required by this template are located.')
param artifactsLocation string = 'https://raw.githubusercontent.com/Azure/azure-quickstart-templates/master/201-nsg-add-to-existing-subnet/'

@description('The sasToken required to access _artifactsLocation.')
@secure()
param artifactsLocationSasToken string = ''

resource new_nsg 'Microsoft.Network/networkSecurityGroups@2020-05-01' = {
  name: 'new-nsg'
  location: location
  properties: {
    securityRules: [
      {
        name: 'SSH'
        properties: {
          description: 'Allows SSH traffic'
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '22'
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

module deploy '?' /*TODO: replace with correct path to [uri(parameters('_artifactsLocation'), concat('nested/updateSubnet.json', parameters('_artifactsLocationSasToken')))]*/ = {
  name: 'deploy'
  scope: resourceGroup(virtualNetworkResourceGroupName)
  params: {
    virtualNetworkName: virtualNetworkName
    subnetName: subnetName
    subnetAddressPrefix: reference(resourceId(virtualNetworkResourceGroupName, 'Microsoft.Network/virtualNetworks/subnets', virtualNetworkName, subnetName), '2018-03-01').addressPrefix
    nsgId: new_nsg.id
    location: location
  }
}