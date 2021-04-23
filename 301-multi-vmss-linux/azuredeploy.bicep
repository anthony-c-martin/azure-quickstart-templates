@description('Admin username for all VMs')
param adminUsername string

@description('Number of VMSSes to deploy')
param numberOfVMSS int

@description('Documentation here: https://docs.microsoft.com/azure/virtual-machine-scale-sets/virtual-machine-scale-sets-placement-groups')
param singlePlacementGroup bool = true

@maxValue(1000)
@description('Number of VM instances per scale set; if singlePlacementGroup is true (the default), then this value must be 100 or less; if singlePlacementGroup is false, then ths value must be 1000 or less')
param instanceCountPerVMSS int

@description('The base URI where artifacts required by this template are located. When the template is deployed using the accompanying scripts, a private location in the subscription will be used and this value will be automatically generated.')
param artifactsLocation string = 'https://raw.githubusercontent.com/Azure/azure-quickstart-templates/master/301-multi-vmss-linux/'

@description('The sasToken required to access _artifactsLocation.  When the template is deployed using the accompanying scripts, a sasToken will be automatically generated.')
@secure()
param artifactsLocationSasToken string = ''

@allowed([
  'sshPublicKey'
  'password'
])
@description('Type of authentication to use on the Virtual Machine. SSH key is recommended.')
param authenticationType string = 'sshPublicKey'

@description('SSH Key or password for the Virtual Machine. SSH key is recommended.')
@secure()
param adminPasswordOrKey string

var VMSSPrefix = 'vmss-linux'
var newVNETName_var = '${VMSSPrefix}-vnet'
var addressPrefix = '10.0.0.0/16'
var subnetName = 'subnet'
var subnetPrefix = '10.0.0.0/16'

resource newVNETName 'Microsoft.Network/virtualNetworks@2017-04-01' = {
  name: newVNETName_var
  location: resourceGroup().location
  properties: {
    addressSpace: {
      addressPrefixes: [
        addressPrefix
      ]
    }
    subnets: [
      {
        name: subnetName
        properties: {
          addressPrefix: subnetPrefix
        }
      }
    ]
  }
}

module clusterSet '?' /*TODO: replace with correct path to [uri(parameters('_artifactsLocation'), concat('nestedtemplates/base.json', parameters('_artifactsLocationSasToken')))]*/ = [for i in range(0, numberOfVMSS): {
  name: 'clusterSet${i}'
  params: {
    VMSSName: concat(VMSSPrefix, padLeft(i, 2, '0'))
    singlePlacementGroup: singlePlacementGroup
    instanceCount: instanceCountPerVMSS
    subnetId: resourceId('Microsoft.Network/virtualNetworks/subnets', newVNETName_var, subnetName)
    adminUsername: adminUsername
    authenticationType: authenticationType
    adminPasswordOrKey: adminPasswordOrKey
  }
  dependsOn: [
    newVNETName
  ]
}]