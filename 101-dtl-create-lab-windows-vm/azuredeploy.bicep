@description('The name of the new lab instance to be created')
param labName string

@description('Location for all resources.')
param location string = resourceGroup().location

@description('The name of the vm to be created.')
param vmName string

@description('The size of the vm to be created.')
param vmSize string = 'Standard_D3_v2'

@description('The username for the local account that will be created on the new vm.')
param userName string

@description('The password for the local account that will be created on the new vm.')
@secure()
param password string

var labSubnetName = '${labVirtualNetworkName}Subnet'
var labVirtualNetworkId = labName_labVirtualNetworkName.id
var labVirtualNetworkName = 'Dtl${labName}'

resource labName_resource 'Microsoft.DevTestLab/labs@2018-10-15-preview' = {
  name: labName
  location: location
}

resource labName_labVirtualNetworkName 'Microsoft.DevTestLab/labs/virtualNetworks@2018-10-15-preview' = {
  parent: labName_resource
  name: '${labVirtualNetworkName}'
}

resource labName_vmName 'Microsoft.DevTestLab/labs/virtualMachines@2018-10-15-preview' = {
  parent: labName_resource
  name: '${vmName}'
  location: location
  properties: {
    userName: userName
    password: password
    labVirtualNetworkId: labVirtualNetworkId
    labSubnetName: labSubnetName
    size: vmSize
    allowClaim: 'true'
    galleryImageReference: {
      offer: 'WindowsServer'
      publisher: 'MicrosoftWindowsServer'
      sku: '2019-Datacenter'
      osType: 'Windows'
      version: 'latest'
    }
  }
}

output labId string = labName_resource.id